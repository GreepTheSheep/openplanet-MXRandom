class BrokenMapSkipWarnModalDialog : ModalDialog {
    RMC@ run;

    BrokenMapSkipWarnModalDialog(RMC@ gamemode) {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###BrokenMapSkip");
        m_size = vec2(400, 130);
        @run = gamemode;
    }

    void RenderDialog() override {
        float scale = UI::GetScale();

        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Broken Map skips are only for impossible or broken maps.\n\nAre you sure to skip?");
        UI::EndChild();

        if (UI::Button(Icons::Times + " No")) {
            Close();
            run.IsPaused = false;
        }

        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70 * scale, UI::GetCursorPos().y));

        if (UI::OrangeButton(Icons::PlayCircleO + " Yes")) {
            Close();
            Log::Info("RMC: Skipping broken map.");
            UI::ShowNotification("Please wait...");

#if DEPENDENCY_BETTERCHAT
            if (run.Mode == RMC::GameMode::Together) {
                BetterChat::SendChatMessage(Icons::Users + " Skipping broken map...");
            }
#endif
            run.TimeLeft += run.TimeSpentMap;
            run.TotalTime -= run.TimeSpentMap;
            startnew(CoroutineFunc(run.SwitchMap));
        }
    }
}