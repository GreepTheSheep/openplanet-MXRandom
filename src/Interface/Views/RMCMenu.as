namespace RMC
{
    void RenderRMCMenu()
    {
#if TMNEXT
        if (Permissions::PlayLocalMap()) {
#endif
            if (UI::GreenButton(Icons::ClockO + " Start Random Map Challenge")){
                selectedGameMode = GameMode::Challenge;
                IsRunning = true;
                startnew(Start);
            }
            if (UI::GreenButton(Icons::Heart + " Start Random Map Survival")){
                selectedGameMode = GameMode::Survival;
                IsRunning = true;
            }
#if TMNEXT
        } else {
            UI::Text(Icons::TimesCircle + " You have not the permissions to play local maps");
        }
#endif
        if (UI::Button(Icons::Table + " Standings")) {
            OpenBrowserURL("https://docs.google.com/spreadsheets/d/1hgjYu84s6RtQZTgDFS7ZeyqszALCH-5OpsmDtBNWK_U/edit?usp=sharing");
        }
        UI::SameLine();
        if (UI::OrangeButton(Icons::Backward + " Go back")) {
            window.isInRMCMode = false;
        }

        if (Challenge.GoalMedalCount > 0 || Challenge.BelowMedalCount > 0 || Survival.Skips > 0){
            UI::Separator();
            UI::Text("Last run stats:");
            Challenge.RenderGoalMedal();
            vec2 pos_orig = UI::GetCursorPos();
            UI::SetCursorPos(vec2(pos_orig.x+50, pos_orig.y));
            if (selectedGameMode == GameMode::Challenge) Challenge.RenderBelowGoalMedal();
            else if (selectedGameMode == GameMode::Survival) Survival.RenderBelowGoalMedal();
        }
    }

    void RenderRMCTimer()
    {
        if (selectedGameMode == GameMode::Challenge) Challenge.Render();
        else if (selectedGameMode == GameMode::Survival) Survival.Render();
    }
}