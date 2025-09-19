class BrokenMapSkipWarnModalDialog : ModalDialog {
    Net::HttpRequest@ m_request;
    string resErrorString;
    Json::Value m_rulesJson;
    bool m_requestError = false;
    RMC@ mode;

    BrokenMapSkipWarnModalDialog(RMC@ gamemode) {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###BrokenMapSkip");
        m_size = vec2(400, 130);
        @mode = gamemode;
    }

    void RenderDialog() override {
        float scale = UI::GetScale();

        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Broken Map skips are only for impossible or broken maps.\n\nAre you sure to skip?");
        UI::EndChild();

        if (UI::Button(Icons::Times + " No")) {
            Close();
            mode.IsPaused = false;
        }

        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70 * scale, UI::GetCursorPos().y));

        if (UI::OrangeButton(Icons::PlayCircleO + " Yes")) {
            Close();
            Log::Log("RMC: Skipping broken map.");
            UI::ShowNotification("Please wait...");
            mode.TimeLeft += mode.TimeSpentMap;
            mode.TotalTime -= mode.TimeSpentMap;
            startnew(CoroutineFunc(mode.SwitchMap));
        }
    }
}