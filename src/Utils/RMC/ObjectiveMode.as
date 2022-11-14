class RMObjective : RMC
{
    int Skips = 0;
    int RunTimeStart = -1;
    int RunTime = -1;
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string GetModeName() override { return "Random Map Objective";}

    void RenderTimer() override
    {
        UI::PushFont(TimerFont);
        if (RMC::IsRunning || RMC::EndTime > 0 || RMC::StartTime > 0) {
            RunTime = RMC::StartTime - RunTimeStart;

            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(RunTime));
            else UI::Text(RMC::FormatTimer(RunTime));

        } else {
            UI::TextDisabled(RMC::FormatTimer(0));
        }
        UI::PopFont();
        UI::Dummy(vec2(0, 8));
        if (PluginSettings::RMC_DisplayMapTimeSpent) {
            UI::PushFont(g_fontHeaderSub);
            UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
            UI::SetPreviousTooltip("Time spent on this map");
            UI::PopFont();
        }
    }

    void RenderGoalMedal() override
    {
        if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) UI::Image(AuthorTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) UI::Image(GoldTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) UI::Image(SilverTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[0]) UI::Image(BronzeTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else UI::Text(PluginSettings::RMC_GoalMedal);
        UI::SameLine();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(TimerFont);
        if (PluginSettings::RMC_ObjectiveMode_DisplayRemaininng) {
            UI::Text("-"+tostring(PluginSettings::RMC_ObjectiveMode_Goal-RMC::GoalMedalCount));
            UI::PopFont();
            UI::SetPreviousTooltip("Remaining medals. Click to set to total count.");
        } else {
            UI::Text(tostring(RMC::GoalMedalCount) + "/" + tostring(PluginSettings::RMC_ObjectiveMode_Goal));
            UI::PopFont();
            UI::SetPreviousTooltip("Medal count. Click to set to remaining medals.");
        }
        if (UI::IsItemClicked()) {
            PluginSettings::RMC_ObjectiveMode_DisplayRemaininng = !PluginSettings::RMC_ObjectiveMode_DisplayRemaininng;
        }
        UI::SetCursorPos(pos_orig);
    }

    void RenderBelowGoalMedal() override
    {
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x+(PluginSettings::RMC_ObjectiveMode_DisplayRemaininng ? 8:24), pos_orig.y));
        UI::Image(SkipTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        UI::SameLine();
        pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(TimerFont);
        UI::Text(tostring(Skips));
        UI::PopFont();
        UI::SetCursorPos(pos_orig);
    }

    void SkipButton() override
    {
        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips += 1;
            Log::Trace("ObjectiveMode: Skipping map");
            UI::ShowNotification("Please wait...");
            MX::MapInfo@ CurrentMapFromJson = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            if (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.isMapHasPrepatchMapTags(CurrentMapFromJson)) {
                RMC::EndTime += RMC::TimeSpentMap;
            }
            startnew(RMC::SwitchMap);
        }
    }

    void NextMapButton() override
    {
        if(UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("ObjectiveMode: Next map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
    }

    void DevButtons() override {}

    void StartTimer() override
    {
        RMC::StartTime = Time::get_Now();
        RunTimeStart = Time::get_Now();
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
    }

    void GotGoalMedalNotification() override
    {
        Log::Trace("ObjectiveMode: Got "+ tostring(PluginSettings::RMC_GoalMedal) + " medal!");
        if (RMC::GoalMedalCount < PluginSettings::RMC_ObjectiveMode_Goal) {
            if (PluginSettings::RMC_AutoSwitch) {
                UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "We're searching for another map...");
                startnew(RMC::SwitchMap);
            } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "Select 'Next map' to change the map");
        }
    }

    void GotBelowGoalMedalNotification() override {}

    void TimerYield() override
    {
        while (RMC::IsRunning){
            yield();
            if (!RMC::IsPaused) {
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(false);
#endif
                CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
                if (currentMap !is null) {
                    CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
                    if (currentMapInfo !is null) {
                        if (DataJson["recentlyPlayed"].Length > 0 && currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["TrackUID"]) {
                            RMC::StartTime = Time::get_Now();
                            PendingTimerLoop();

                            if (RMC::GoalMedalCount >= PluginSettings::RMC_ObjectiveMode_Goal) {
                                UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "You have reached your goal in "+RMC::FormatTimer(RunTime));
                                RMC::StartTime = -1;
                                RMC::EndTime = -1;
                                RMC::IsRunning = false;
                                RMC::ShowTimer = false;
                                if (PluginSettings::RMC_ExitMapOnEndTime){
                                    CTrackMania@ app = cast<CTrackMania>(GetApp());
                                    app.BackToMainMenu();
                                }
                            }
                        } else {
                            RMC::IsPaused = true;
                        }
                    }
                }
            } else {
                // pause timer
                RMC::StartTime = Time::get_Now() - (Time::get_Now() - RMC::StartTime);
                RMC::EndTime = Time::get_Now() - (Time::get_Now() - RMC::EndTime);
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(true);
#endif
            }

            if (RMC::GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal) && !RMC::GotGoalMedalOnCurrentMap){
                RMC::GoalMedalCount += 1;
                RMC::GotGoalMedalOnCurrentMap = true;
                GotGoalMedalNotification();
            }
            if (
                RMC::GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1 &&
                !RMC::GotGoalMedalOnCurrentMap &&
                PluginSettings::RMC_GoalMedal != RMC::Medals[0])
            {
                GotBelowGoalMedalNotification();
                RMC::GotBelowMedalOnCurrentMap = true;
            }
        }
    }
}