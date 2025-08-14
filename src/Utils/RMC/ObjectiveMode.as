class RMObjective : RMC
{
    int Skips = 0;
    int RunTimeStart = -1;
    int RunTime = -1;
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string GetModeName() override { return "Random Map Objective";}

    void RenderTimer() override
    {
        UI::PushFont(Fonts::TimerFont);
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
            UI::PushFont(Fonts::HeaderSub);
            UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
            UI::SetPreviousTooltip("Time spent on this map");
            UI::PopFont();
        }
    }

    void RenderGoalMedal() override
    {
        UI::Image(Textures[PluginSettings::RMC_Medal], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();

        if (PluginSettings::RMC_ObjectiveMode_DisplayRemaininng) {
            UI::AlignTextToImage("-"+tostring(PluginSettings::RMC_ObjectiveMode_Goal-RMC::GoalMedalCount), Fonts::TimerFont);
            UI::SetPreviousTooltip("Remaining medals. Click to set to total count.");
        } else {
            UI::AlignTextToImage(tostring(RMC::GoalMedalCount) + " / " + tostring(PluginSettings::RMC_ObjectiveMode_Goal), Fonts::TimerFont);
            UI::SetPreviousTooltip("Medal count. Click to set to remaining medals.");
        }
        if (UI::IsItemClicked()) {
            PluginSettings::RMC_ObjectiveMode_DisplayRemaininng = !PluginSettings::RMC_ObjectiveMode_DisplayRemaininng;
        }
    }

    void RenderBelowGoalMedal() override
    {
        UI::HPadding(25);
        UI::Image(SkipTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(Skips), Fonts::TimerFont);
    }

    void SkipButtons() override
    {
        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips += 1;
            Log::Trace("ObjectiveMode: Skipping map");
            UI::ShowNotification("Please wait...");
            MX::MapInfo@ currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            if (
#if TMNEXT
                (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.HasPrepatchTags(currentMap)) ||
#endif
                (PluginSettings::RMC_EditedMedalsWarns && TM::HasEditedMedals())
            ) {
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
        RMC::StartTime = Time::Now;
        RunTimeStart = Time::Now;
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
    }

    void GotGoalMedalNotification() override
    {
        Log::Trace("ObjectiveMode: Got the "+ tostring(PluginSettings::RMC_Medal) + " medal!");
        if (RMC::GoalMedalCount < PluginSettings::RMC_ObjectiveMode_Goal) {
            if (PluginSettings::RMC_AutoSwitch) {
                UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
                startnew(RMC::SwitchMap);
            } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
        }
    }

    void GotBelowGoalMedalNotification() override {}

    void TimerYield() override
    {
        auto app = cast<CTrackMania>(GetApp());

        while (RMC::IsRunning) {
            yield();
            if (!RMC::IsPaused) {
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(false);
#endif
                if (TM::InRMCMap()) {
                    RMC::StartTime = Time::Now;
                    RMC::TimeSpentMap = Time::Now - RMC::TimeSpawnedMap;
                    PendingTimerLoop();

                    if (RMC::GoalMedalCount >= PluginSettings::RMC_ObjectiveMode_Goal) {
                        UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "You have reached your goal in " + RMC::FormatTimer(RunTime));
                        RMC::StartTime = -1;
                        RMC::EndTime = -1;
                        RMC::IsRunning = false;
                        RMC::ShowTimer = false;
                        if (PluginSettings::RMC_ExitMapOnEndTime){
                            app.BackToMainMenu();
                        }
                        @MX::preloadedMap = null;
                    }
                } else {
                    RMC::IsPaused = true;
                }
            } else {
                // pause timer
                RMC::StartTime = Time::Now - (Time::Now - RMC::StartTime);
                RMC::EndTime = Time::Now - (Time::Now - RMC::EndTime);
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(true);
#endif
            }
        }
    }

    void PbLoop() override {
        while (RMC::IsRunning) {
            yield();

            if (!RMC::IsPaused && !RMC::GotGoalMedal) {
                uint score = TM::GetFinishScore();

                if (score == uint(-1)) {
                    sleep(50);
                    continue;
                }

                if (score <= GoalTime) {
                    GotGoalMedalNotification();
                    RMC::GoalMedalCount++;
                    RMC::GotGoalMedal = true;
                }

                if (RMC::CurrentTimeOnMap == -1 || int(score) < RMC::CurrentTimeOnMap) {
                    // PB
                    RMC::CurrentTimeOnMap = score;
                    RMC::CreateSave();
                }

                sleep(1000);
            }
        }
    }
}