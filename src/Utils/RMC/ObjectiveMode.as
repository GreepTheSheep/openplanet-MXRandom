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
        if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) UI::Image(AuthorTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) UI::Image(GoldTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) UI::Image(SilverTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[0]) UI::Image(BronzeTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        else UI::Text(PluginSettings::RMC_GoalMedal);
        UI::SameLine();

        if (PluginSettings::RMC_ObjectiveMode_DisplayRemaininng) {
            UI::AlignTextToImage("-"+tostring(PluginSettings::RMC_ObjectiveMode_Goal-RMC::GoalMedalCount), TimerFont);
            UI::SetPreviousTooltip("Remaining medals. Click to set to total count.");
        } else {
            UI::AlignTextToImage(tostring(RMC::GoalMedalCount) + " / " + tostring(PluginSettings::RMC_ObjectiveMode_Goal), TimerFont);
            UI::SetPreviousTooltip("Medal count. Click to set to remaining medals.");
        }
        if (UI::IsItemClicked()) {
            PluginSettings::RMC_ObjectiveMode_DisplayRemaininng = !PluginSettings::RMC_ObjectiveMode_DisplayRemaininng;
        }
    }

    void RenderBelowGoalMedal() override
    {
        UI::Image(SkipTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(Skips), TimerFont);
    }

    void SkipButtons() override
    {
        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips += 1;
            Log::Trace("ObjectiveMode: Skipping map");
            UI::ShowNotification("Please wait...");
            MX::MapInfo@ CurrentMapFromJson = MX::MapInfo(DataJson["recentlyPlayed"][0]);
#if TMNEXT
            if (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.isMapHasPrepatchMapTags(CurrentMapFromJson)) {
                RMC::EndTime += RMC::TimeSpentMap;
            }
#endif
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
                        if (DataJson["recentlyPlayed"].Length > 0 && currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["MapUid"]) {
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
                                @MX::preloadedMap = null;
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

            if (!RMC::GotGoalMedalOnCurrentMap && RMC::GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal)){
                RMC::GoalMedalCount += 1;
                RMC::GotGoalMedalOnCurrentMap = true;
                GotGoalMedalNotification();
            } else if (
                !RMC::GotGoalMedalOnCurrentMap &&
                !RMC::GotBelowMedalOnCurrentMap &&
                PluginSettings::RMC_GoalMedal != RMC::Medals[0] &&
                RMC::GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1)
            {
                GotBelowGoalMedalNotification();
                RMC::GotBelowMedalOnCurrentMap = true;
            }
        }
    }
}