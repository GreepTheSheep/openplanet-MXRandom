class RMS : RMC {
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string get_ModeName() override { 
        return "Random Map Survival";
    }

    int get_TimeLimit() override { return (PluginSettings::RMC_SurvivalMaxTime - Skips) * 60 * 1000; }

    int get_SurvivedTime() {
        return TotalTime;
    }

    int get_Skips() {
        return BelowMedalCount;
    }

    void set_Skips(int n) {
        BelowMedalCount = Math::Max(0, n);
    }

    void RenderPace() override { }

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
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::IsSwitchingMap);

        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips += 1;
            Log::Trace("RMS: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");

        if (UI::OrangeButton(Icons::PlayCircleO + " Skip Broken Map")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            RMC::IsPaused = true;
            Renderables::Add(BrokenMapSkipWarnModalDialog(this));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");

        UI::EndDisabled();
    }

    void NextMapButton() override {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::IsSwitchingMap);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMS: Next map");
            UI::ShowNotification("Please wait...");
            TimeLeft += (3*60*1000);
            startnew(CoroutineFunc(SwitchMap));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To move to the next map, please exit the pause menu.");

        UI::EndDisabled();
    }

    void StartTimer() override {
        if (RMC::ContinueSavedRun) {
            TimeLeft = int(RMC::CurrentRunData["TimeLeft"]);
            TotalTime = int(RMC::CurrentRunData["TotalTime"]);
        }

        RMC::IsPaused = false;
        RMC::IsRunning = true;
        if (RMC::GotGoalMedal) GotGoalMedalNotification();
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
        startnew(CoroutineFunc(PreloadNextMap));
    }

    void GameEndNotification() override {
        UI::ShowNotification(
            "\\$0f0" + ModeName + " ended!",
            "You survived with a time of " + RMC::FormatTimer(SurvivedTime) +
            ".\nYou got " + RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal) +
            " medals and " + Skips + " skips."
        );

#if TMNEXT
        if (RMC::currentGameMode == RMC::GameMode::Survival) {
            RMCLeaderAPI::postRMS(RMC::GoalMedalCount, Skips, SurvivedTime, PluginSettings::RMC_Medal);
        }
#endif
    }

    void GotGoalMedalNotification() override {
        Log::Trace("RMC: Got the " + tostring(PluginSettings::RMC_Medal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
            TimeLeft += (3*60*1000);
            startnew(CoroutineFunc(SwitchMap));
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification() override {}
}