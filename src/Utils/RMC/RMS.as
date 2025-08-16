class RMS : RMC
{
    int Skips = 0;
    int SurvivedTimeStart = -1;
    int SurvivedTime = -1;
    UI::Texture@ SkipTex = UI::LoadTexture("src/Assets/Images/YEPSkip.png");

    string GetModeName() override { return "Random Map Survival";}

    int TimeLimit() override { return PluginSettings::RMC_SurvivalMaxTime * 60 * 1000; }

    void RenderTimer() override
    {
        UI::PushFont(Fonts::TimerFont);
        if (RMC::IsRunning || RMC::EndTime > 0 || RMC::StartTime > 0) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));
            else UI::Text(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));

            SurvivedTime = RMC::StartTime - SurvivedTimeStart;
            if (SurvivedTime > 0 && PluginSettings::RMC_SurvivalShowSurvivedTime) {
                UI::PopFont();
                UI::Dummy(vec2(0, 8));
                UI::PushFont(Fonts::HeaderSub);
                UI::Text(RMC::FormatTimer(SurvivedTime));
                UI::SetPreviousTooltip("Total time survived");
            } else {
                UI::Dummy(vec2(0, 8));
            }
            if (PluginSettings::RMC_DisplayMapTimeSpent) {
                if(SurvivedTime > 0 && PluginSettings::RMC_SurvivalShowSurvivedTime) {
                    UI::SameLine();
                }
                UI::PushFont(Fonts::HeaderSub);
                UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
                UI::SetPreviousTooltip("Time spent on this map");
                UI::PopFont();
            }
        } else {
            UI::TextDisabled(RMC::FormatTimer(TimeLimit()));
            UI::Dummy(vec2(0, 8));
        }

        UI::PopFont();
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
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::ClickedOnSkip);
        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips += 1;
            Log::Trace("RMS: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
        if (UI::OrangeButton(Icons::PlayCircleO + " Skip Broken Map")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            RMC::IsPaused = true;
            Renderables::Add(BrokenMapSkipWarnModalDialog());
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");
        UI::EndDisabled();
    }

    void NextMapButton() override
    {
        if(UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMS: Next map");
            UI::ShowNotification("Please wait...");
            RMC::EndTime += (3*60*1000);
            startnew(RMC::SwitchMap);
        }
    }

    void StartTimer() override
    {
        RMC::StartTime = Time::Now;
        RMC::EndTime =  !RMC::ContinueSavedRun ? RMC::StartTime + TimeLimit() : RMC::StartTime + int(RMC::CurrentRunData["TimerRemaining"]);
        SurvivedTimeStart = !RMC::ContinueSavedRun ? Time::Now : Time::Now - int(RMC::CurrentRunData["CurrentRunTime"]);
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        if (RMC::GotGoalMedal) GotGoalMedalNotification();
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
    }

    void PendingTimerLoop() override
    {
        // Cap timer max
        if ((RMC::EndTime - RMC::StartTime) > (PluginSettings::RMC_SurvivalMaxTime-RMC::Survival.Skips)*60*1000) {
            RMC::EndTime = RMC::StartTime + (PluginSettings::RMC_SurvivalMaxTime-RMC::Survival.Skips)*60*1000;
        }
    }

    void GameEndNotification() override
    {
        if (RMC::currentGameMode == RMC::GameMode::Survival) {
#if TMNEXT
            RMCLeaderAPI::postRMS(RMC::GoalMedalCount, Skips, SurvivedTime, PluginSettings::RMC_Medal);
#endif
            UI::ShowNotification(
                "\\$0f0Random Map Survival ended!",
                "You survived with a time of " + RMC::FormatTimer(RMC::Survival.SurvivedTime) +
                ".\nYou got "+ RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal) +
                " medals and " + RMC::Survival.Skips + " skips."
            );
        }
#if DEPENDENCY_CHAOSMODE
        if (RMC::currentGameMode == RMC::GameMode::SurvivalChaos) {
            UI::ShowNotification(
                "\\$0f0Random Map Chaos Survival ended!",
                "You survived with a time of " + RMC::FormatTimer(RMC::Survival.SurvivedTime) +
                ".\nYou got "+ RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal) +
                " medals and " + RMC::Survival.Skips + " skips."
            );
            ChaosMode::SetRMCMode(false);
        }
#endif
    }

    void GotGoalMedalNotification() override
    {
        Log::Trace("RMC: Got the "+ tostring(PluginSettings::RMC_Medal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
            RMC::EndTime += (3*60*1000);
            startnew(RMC::SwitchMap);
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the "+tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification() override {}
}