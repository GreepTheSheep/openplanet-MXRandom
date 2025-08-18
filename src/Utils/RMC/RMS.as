class RMS : RMC {
    int Skips = 0;
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string get_ModeName() override { 
        if (RMC::currentGameMode == RMC::GameMode::SurvivalChaos) {
            return "Random Map Chaos Survival";
        }

        return "Random Map Survival";
    }

    int get_TimeLimit() override { return (PluginSettings::RMC_SurvivalMaxTime - Skips) * 60 * 1000; }

    int get_SurvivedTime() {
        return TotalTime;
    }

    void RenderTimer() override {
        UI::PushFont(Fonts::TimerFont);
        if (RMC::IsRunning) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(TimeLeft));
            else UI::Text(RMC::FormatTimer(TimeLeft));

            UI::Dummy(vec2(0, 8));

            if (PluginSettings::RMC_SurvivalShowSurvivedTime && SurvivedTime > 0) {
                UI::PopFont();
                UI::PushFont(Fonts::HeaderSub);
                UI::Text(RMC::FormatTimer(SurvivedTime));
                UI::SetPreviousTooltip("Total time survived");
            }

            if (PluginSettings::RMC_DisplayMapTimeSpent) {
                if (PluginSettings::RMC_SurvivalShowSurvivedTime && SurvivedTime > 0) {
                    UI::SameLine();
                }
                UI::PushFont(Fonts::HeaderSub);
                UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
                UI::SetPreviousTooltip("Time spent on this map");
                UI::PopFont();
            }
        } else {
            UI::TextDisabled(RMC::FormatTimer(TimeLimit));
            UI::Dummy(vec2(0, 8));
        }

        UI::PopFont();
    }

    void RenderBelowGoalMedal() override {
        UI::HPadding(25);
        UI::Image(SkipTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(Skips), Fonts::TimerFont);
    }

    void SkipButtons() override {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::ClickedOnSkip);

        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            RMC::ClickedOnSkip = true;
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips++;
            Log::Trace("RMS: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");

        if (UI::OrangeButton(Icons::PlayCircleO + " Skip Broken Map")) {
            RMC::ClickedOnSkip = true;
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            RMC::IsPaused = true;
            Renderables::Add(BrokenMapSkipWarnModalDialog(this));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");

        UI::EndDisabled();
    }

    void NextMapButton() override {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::ClickedOnSkip);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMS: Next map");
            UI::ShowNotification("Please wait...");
            TimeLeft += (3*60*1000);
            startnew(RMC::SwitchMap);
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To move to the next map, please exit the pause menu.");

        UI::EndDisabled();
    }

    void StartTimer() override {
        TimeLeft = !RMC::ContinueSavedRun ? TimeLimit : int(RMC::CurrentRunData["TimeLeft"]);
        TotalTime = !RMC::ContinueSavedRun ? 0 : int(RMC::CurrentRunData["TotalTime"]);
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        if (RMC::GotGoalMedal) GotGoalMedalNotification();
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
    }

    void GameEndNotification() override {
        UI::ShowNotification(
            "\\$0f0" + ModeName + " ended!",
            "You survived with a time of " + RMC::FormatTimer(SurvivedTime) +
            ".\nYou got " + RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal) +
            " medals and " + Skips + " skips."
        );

#if TMNEXT
        if (RMC::currentGameMode == RMC::GameMode::Challenge) {
            RMCLeaderAPI::postRMS(RMC::GoalMedalCount, Skips, SurvivedTime, PluginSettings::RMC_Medal);
        }
#if DEPENDENCY_CHAOSMODE
        else if (RMC::currentGameMode == RMC::GameMode::SurvivalChaos) {
            ChaosMode::SetRMCMode(false);
        }
#endif
#endif
    }

    void GotGoalMedalNotification() override {
        Log::Trace("RMC: Got the " + tostring(PluginSettings::RMC_Medal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
            TimeLeft += (3*60*1000);
            startnew(RMC::SwitchMap);
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification() override {}
}