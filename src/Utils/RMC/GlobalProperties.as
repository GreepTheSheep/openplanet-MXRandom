namespace RMC
{
    bool IsRunning = false;

    RMC Challenge;
    RMS Survival;

    enum GameMode
    {
        Challenge,
        Survival
    }
    GameMode selectedGameMode;

    void RenderRMCMenu()
    {
        if (UI::GreenButton(Icons::ClockO + " Start Random Map Challenge")){
            // RMC::StartChallenge();
            selectedGameMode = GameMode::Challenge;
            Log::Log(tostring(selectedGameMode));
        }
        if (UI::GreenButton(Icons::Heart + " Start Random Map Survival")){
            // RMC::StartSurvival();
            selectedGameMode = GameMode::Survival;
            Log::Log(tostring(selectedGameMode));
        }
        if (UI::Button(Icons::Table + " Standings")) {
            OpenBrowserURL("https://docs.google.com/spreadsheets/d/1hgjYu84s6RtQZTgDFS7ZeyqszALCH-5OpsmDtBNWK_U/edit?usp=sharing");
        }
        UI::SameLine();
        if (UI::ColoredButton(UI::IsOverlayShown() ? Icons::Backward + " Go back" : Icons::Times + " Close", 0.155)) {
            window.isInRMCMode = false;
        }

        // if (Challenge.GoalMedalCount > 0 || Challenge.BelowMedalCount > 0 || Survival.Skips > 0){
            UI::Separator();
            UI::Text("Last run stats:");
            Challenge.RenderGoalMedal();
            vec2 pos_orig = UI::GetCursorPos();
            UI::SetCursorPos(vec2(pos_orig.x+50, pos_orig.y));
            if (selectedGameMode == GameMode::Challenge) Challenge.RenderBelowGoalMedal();
            else if (selectedGameMode == GameMode::Survival) Survival.RenderBelowGoalMedal();
        // }
    }
}