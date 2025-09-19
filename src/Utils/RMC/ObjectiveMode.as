class RMObjective : RMC {
    int Skips = 0;
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string get_ModeName() override { return "Random Map Objective"; }

    RMC::GameMode get_GameMode() override {
        return RMC::GameMode::Objective;
    }

    void RenderPace() override { }

    void CheckSave() override { }

    void RenderTimer() override {
        UI::PushFont(Fonts::TimerFont);

        if (IsPaused || !IsRunning) {
            UI::TextDisabled(RMC::FormatTimer(TotalTime));
        } else {
            UI::Text(RMC::FormatTimer(TotalTime));
        }

        UI::PopFont();

        UI::Dummy(vec2(0, 8));

        if (PluginSettings::RMC_DisplayMapTimeSpent) {
            UI::PushFont(Fonts::HeaderSub);

            UI::Text(Icons::Map + " " + RMC::FormatTimer(TimeSpentMap));
            UI::SetPreviousTooltip("Time spent on this map");

            UI::PopFont();
        }
    }

    void RenderGoalMedal() override {
        UI::Image(Textures[PluginSettings::RMC_Medal], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();

        if (PluginSettings::RMC_ObjectiveMode_DisplayRemaininng) {
            UI::AlignTextToImage("-" + tostring(PluginSettings::RMC_ObjectiveMode_Goal - GoalMedalCount), Fonts::TimerFont);
            UI::SetPreviousTooltip("Remaining medals. Click to set to total count.");
        } else {
            UI::AlignTextToImage(tostring(GoalMedalCount) + " / " + tostring(PluginSettings::RMC_ObjectiveMode_Goal), Fonts::TimerFont);
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
            if (IsPaused) IsPaused = false;
            Skips++;
            Log::Trace("ObjectiveMode: Skipping map");
            UI::ShowNotification("Please wait...");

            if (
#if TMNEXT
                (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.HasPrepatchTags(currentMap)) ||
#endif
                (PluginSettings::RMC_EditedMedalsWarns && TM::HasEditedMedals())
            ) {
                TimeLeft += TimeSpentMap;
            }
            startnew(CoroutineFunc(SwitchMap));
        }
    }

    void NextMapButton() override {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || IsSwitchingMap);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            if (IsPaused) IsPaused = false;
            Log::Trace("ObjectiveMode: Next map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To move to the next map, please exit the pause menu.");

        UI::EndDisabled();
    }

    void DevButtons() override {}

    void StartTimer() override {
        IsPaused = false;
        IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
        startnew(CoroutineFunc(PreloadNextMap));
    }

    void GotGoalMedalNotification() override {
        Log::Trace("ObjectiveMode: Got the " + tostring(PluginSettings::RMC_Medal) + " medal!");
        if (GoalMedalCount < PluginSettings::RMC_ObjectiveMode_Goal) {
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

        while (IsRunning) {
            yield();

            if (!IsPaused) {
                if (!InCurrentMap()) {
                    IsPaused = true;
                } else if (GoalMedalCount >= PluginSettings::RMC_ObjectiveMode_Goal) {
                    UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "You have reached your goal in " + RMC::FormatTimer(TotalTime));
                    IsRunning = false;
                    RMC::ShowTimer = false;
                    if (PluginSettings::RMC_ExitMapOnEndTime) {
                        app.BackToMainMenu();
                    }
                } else {
                    int delta = Time::Now - lastUpdate;
                    TotalTime += delta;
                    TimeSpentMap += delta;
                }
            }

            lastUpdate = Time::Now;
        }
    }

    void PbLoop() override {
        while (IsRunning) {
            yield();

            if (!IsPaused && !GotGoalMedal) {
                uint score = TM::GetFinishScore();
                bool inverse = TM::CurrentMapType() == MapTypes::Stunt;

                if (score == uint(-1)) {
                    sleep(50);
                    continue;
                }

                if ((!inverse && score <= GoalTime) || (inverse && score >= GoalTime)) {
                    GoalMedalCount++;
                    GotGoalMedalNotification();
                    GotGoalMedal = true;
                }

                if (PBOnMap == -1 || (!inverse && int(score) < PBOnMap) || (inverse && int(score) > PBOnMap)) {
                    // PB
                    PBOnMap = score;
                    CreateSave();
                }

                sleep(1000);
            }
        }
    }
}