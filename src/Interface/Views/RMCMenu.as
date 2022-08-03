namespace RMC
{
    void RenderRMCMenu()
    {
#if TMNEXT
        if (Permissions::PlayLocalMap()) {
#endif
            if (UI::GreenButton(Icons::ClockO + " Start Random Map Challenge")){
                selectedGameMode = GameMode::Challenge;
                startnew(Start);
            }
            if (UI::GreenButton(Icons::Heart + " Start Random Map Survival")){
                selectedGameMode = GameMode::Survival;
                startnew(Start);
            }
#if TMNEXT
            if (UI::TreeNode("\\$f50" + Icons::Fire + " \\$zChaos Mode")) {
#if DEPENDENCY_CHAOSMODE
                if (UI::RedButton(Icons::Fire + " Start RMC with Chaos Mode")){
                    selectedGameMode = GameMode::ChallengeChaos;
                    ChaosMode::SetRMCMode(true);
                    startnew(Start);
                }
                if (UI::RedButton(Icons::Fire + " Start RMS with Chaos Mode")){
                    selectedGameMode = GameMode::SurvivalChaos;
                    ChaosMode::SetRMCMode(true);
                    startnew(Start);
                }
#else
                if (UI::RedButton(Icons::Fire + " Chaos Mode")){
                    Renderables::Add(ChaosModeIntroModalDialog());
                }
#endif
                UI::TreePop();
            }
#endif
            // if (UI::RedButton(Icons::FlagCheckered + " Random Map Race \\$ff0(Coming soon!)")){
            //     Renderables::Add(RMRIntroModalDialog());
            // }
#if TMNEXT
        } else {
            UI::Text(Icons::TimesCircle + " You have not the permissions to play local maps");
        }
#endif
        UI::Separator();
        if (UI::Button(Icons::Table + " Standings")) {
            OpenBrowserURL("https://docs.google.com/spreadsheets/d/1hgjYu84s6RtQZTgDFS7ZeyqszALCH-5OpsmDtBNWK_U/edit?usp=sharing");
        }
        UI::SameLine();
        if (UI::PurpleButton(Icons::Cog)) {
            Renderables::Add(RMCSettingsModalDialog());
        }
        UI::SameLine();
        if (UI::IsOverlayShown() && UI::OrangeButton(Icons::Backward + " Go back")) {
            window.isInRMCMode = false;
        }

        if (RMC::GoalMedalCount > 0 || Challenge.BelowMedalCount > 0 || Survival.Skips > 0 || Survival.SurvivedTime > 0) {
            if (!UI::IsOverlayShown()) UI::Dummy(vec2(0, 10));
            UI::Separator();
            UI::Text("Last run stats:");
            vec2 pos_orig = UI::GetCursorPos();
            Challenge.RenderGoalMedal();
            UI::SetCursorPos(vec2(UI::GetCursorPos().x+50, UI::GetCursorPos().y));
            if (selectedGameMode == GameMode::Challenge) Challenge.RenderBelowGoalMedal();
            else if (selectedGameMode == GameMode::Survival) {
                Survival.RenderBelowGoalMedal();
                UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+60));
                UI::Text("Survived time: " + RMC::FormatTimer(Survival.SurvivedTime));
            }
        }
    }

    void RenderRMCTimer()
    {
        if (selectedGameMode == GameMode::Challenge || selectedGameMode == GameMode::ChallengeChaos) Challenge.Render();
        else if (selectedGameMode == GameMode::Survival || selectedGameMode == GameMode::SurvivalChaos) Survival.Render();
    }

    void RenderBaseInfos()
    {
        UI::PushFont(g_fontHeader);
        UI::Text("Random Map Challenge / Survival");
        UI::PopFont();
        UI::TextWrapped("In the Random Map Challenge, you have to grab the maximum number of author medals in 1 hour.");
        UI::TextWrapped("In the Random Map Survival, you have to grab the maximum number of author medals before the timer reaches 0. You gain 3 minutes per medal won, you can skip but you lose 1 minute of your time limit");
        if (UI::GreenButton(Icons::ExternalLink + " More informations")) OpenBrowserURL("https://flinkblog.de/RMC/");
    }
}