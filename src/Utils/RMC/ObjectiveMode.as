class RMObjective : RMC {
    int Skips = 0;
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string get_ModeName() override { return "Random Map Objective";}

    void RenderTimer() override {
        UI::PushFont(Fonts::TimerFont);
        if (RMC::IsRunning) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(TotalTime));
            else UI::Text(RMC::FormatTimer(TotalTime));
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

    void RenderGoalMedal() override {
        UI::Image(Textures[PluginSettings::RMC_Medal], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();

        if (PluginSettings::RMC_ObjectiveMode_DisplayRemaininng) {
            UI::AlignTextToImage("-" + tostring(PluginSettings::RMC_ObjectiveMode_Goal - RMC::GoalMedalCount), Fonts::TimerFont);
            UI::SetPreviousTooltip("Remaining medals. Click to set to total count.");
        } else {
            UI::AlignTextToImage(tostring(RMC::GoalMedalCount) + " / " + tostring(PluginSettings::RMC_ObjectiveMode_Goal), Fonts::TimerFont);
            UI::SetPreviousTooltip("Medal count. Click to set to remaining medals.");
        }
        if (UI::IsItemClicked()) {
            PluginSettings::RMC_ObjectiveMode_DisplayRemaininng = !PluginSettings::RMC_ObjectiveMode_DisplayRemaininng;
        }
    }

    void RenderBelowGoalMedal() override {
        UI::HPadding(25);
        UI::Image(SkipTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(Skips), Fonts::TimerFont);
    }

    void SkipButtons() override {
        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips++;
            Log::Trace("ObjectiveMode: Skipping map");
            UI::ShowNotification("Please wait...");
            MX::MapInfo@ currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            if (
#if TMNEXT
                (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.HasPrepatchTags(currentMap)) ||
#endif
                (PluginSettings::RMC_EditedMedalsWarns && TM::HasEditedMedals())
            ) {
                TimeLeft += RMC::TimeSpentMap;
            }
            startnew(CoroutineFunc(SwitchMap));
        }
    }

    void NextMapButton() override {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::IsSwitchingMap);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("ObjectiveMode: Next map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To move to the next map, please exit the pause menu.");

        UI::EndDisabled();
    }

    void DevButtons() override {}

    void StartTimer() override {
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
        startnew(CoroutineFunc(PreloadNextMap));
    }

    void GotGoalMedalNotification() override {
        Log::Trace("ObjectiveMode: Got the " + tostring(PluginSettings::RMC_Medal) + " medal!");
        if (RMC::GoalMedalCount < PluginSettings::RMC_ObjectiveMode_Goal) {
            if (PluginSettings::RMC_AutoSwitch) {
                UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
                startnew(CoroutineFunc(SwitchMap));
            } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
        }
    }

    void GotBelowGoalMedalNotification() override {}

    void TimerYield() override {
        auto app = cast<CTrackMania>(GetApp());
        int lastUpdate = Time::Now;

        while (RMC::IsRunning) {
            yield();

#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(RMC::IsPaused);
#endif

            if (!RMC::IsPaused) {
                if (!TM::InRMCMap()) {
                    RMC::IsPaused = true;
                } else if (RMC::GoalMedalCount >= PluginSettings::RMC_ObjectiveMode_Goal) {
                    UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "You have reached your goal in " + RMC::FormatTimer(TotalTime));
                    RMC::IsRunning = false;
                    RMC::ShowTimer = false;
                    if (PluginSettings::RMC_ExitMapOnEndTime) {
                        app.BackToMainMenu();
                    }
                } else {
                    int delta = Time::Now - lastUpdate;
                    TotalTime += delta;
                    RMC::TimeSpentMap += delta;
                }
            }

            lastUpdate = Time::Now;
        }
    }

    void PbLoop() override {
        while (RMC::IsRunning) {
            yield();

            if (!RMC::IsPaused && !RMC::GotGoalMedal) {
                uint score = TM::GetFinishScore();
                bool inverse = TM::CurrentMapType() == MapTypes::Stunt;

                if (score == uint(-1)) {
                    sleep(50);
                    continue;
                }

                if ((!inverse && score <= GoalTime) || (inverse && score >= GoalTime)) {
                    RMC::GoalMedalCount++;
                    GotGoalMedalNotification();
                    RMC::GotGoalMedal = true;
                }

                if (RMC::PBOnMap == -1 || (!inverse && int(score) < RMC::PBOnMap) || (inverse && int(score) > RMC::PBOnMap)) {
                    // PB
                    RMC::PBOnMap = score;
                    RMC::CreateSave();
                }

                sleep(1000);
            }
        }
    }
}