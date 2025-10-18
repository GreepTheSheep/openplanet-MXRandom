class RMS : RMC {
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string get_ModeName() override { 
        return "Random Map Survival";
    }

    RMC::GameMode get_Mode() override {
        return RMC::GameMode::Survival;
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

    bool get_ModeHasBelowMedal() override {
        return false;
    }

    void RenderPace() override { }

    void RenderTimer() override {
        UI::PushFont(Fonts::TimerFont);

        if (IsPaused || !IsRunning) {
            UI::TextDisabled(RMC::FormatTimer(TimeLeft));
        } else {
            UI::Text(RMC::FormatTimer(TimeLeft));
        }

        UI::PopFont();

        UI::Dummy(vec2(0, 8));

        if (IsRunning && SurvivedTime > 0) {
            UI::PushFont(Fonts::HeaderSub);

            if (PluginSettings::RMC_SurvivalShowSurvivedTime) {
                UI::Text(RMC::FormatTimer(SurvivedTime));
                UI::SetPreviousTooltip("Total time survived");
            }

            if (PluginSettings::RMC_SurvivalShowSurvivedTime && PluginSettings::RMC_DisplayMapTimeSpent) {
                UI::SameLine();
            }

            if (PluginSettings::RMC_DisplayMapTimeSpent) {
                UI::Text(Icons::Map + " " + RMC::FormatTimer(TimeSpentMap));
                UI::SetPreviousTooltip("Time spent on this map");
            }

            UI::PopFont();
        }
    }

    void RenderBelowGoalMedal() override {
        UI::HPadding(25);
        UI::Image(SkipTex, vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(Skips), Fonts::TimerFont);
    }

    void SkipButtons() override {
        UI::BeginDisabled(IsSwitchingMap);

        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            Skips += 1;
            Log::Trace("RMS: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        UI::EndDisabled();
    }

    void NextMapButton() override {
        UI::BeginDisabled(IsSwitchingMap);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            Log::Trace("RMS: Next map");
            UI::ShowNotification("Please wait...");
            TimeLeft += (3*60*1000);
            startnew(CoroutineFunc(SwitchMap));
        }

        UI::EndDisabled();
    }

    void StartTimer() override {
        IsRunning = true;

        if (GotGoalMedal) GotGoalMedalNotification();

        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
        startnew(CoroutineFunc(PreloadNextMap));
    }

    void SubmitToLeaderboard() override {
#if TMNEXT
        RMCLeaderAPI::postRMS(GoalMedalCount, Skips, SurvivedTime, PluginSettings::RMC_Medal);
#endif
    }

    void GameEndNotification() override {
        UI::ShowNotification(
            "\\$0f0" + ModeName + " ended!",
            "You survived with a time of " + RMC::FormatTimer(SurvivedTime) +
            ".\nYou got " + GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal) +
            " medals and " + Skips + " skips."
        );
    }

    void GotGoalMedalNotification() override {
        Log::Trace("RMS: Got the " + tostring(PluginSettings::RMC_Medal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
            TimeLeft += (3*60*1000);
            startnew(CoroutineFunc(SwitchMap));
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification() override {}
}