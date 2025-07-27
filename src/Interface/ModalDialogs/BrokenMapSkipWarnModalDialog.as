class BrokenMapSkipWarnModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    string resErrorString;
    Json::Value m_rulesJson;
    bool m_requestError = false;

    BrokenMapSkipWarnModalDialog()
    {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###BrokenMapSkip");
        m_size = vec2(400, 130);
    }

    void RenderDialog() override
    {
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Broken Map skips are only for impossible or broken maps.\n\nAre you sure to skip?");
        UI::EndChild();
        if (UI::Button(Icons::Times + " No")) {
            Close();
            RMC::EndTime = RMC::EndTime + (Time::Now - RMC::StartTime);
            RMC::IsPaused = false;
        }
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70 * scale, UI::GetCursorPos().y));
        if (UI::OrangeButton(Icons::PlayCircleO + " Yes")) {
            Close();
            RMC::EndTime = RMC::EndTime + (Time::Now - RMC::StartTime);
            RMC::IsPaused = false;
            print("RMC: Broken Map Skip");
            UI::ShowNotification("Please wait...");
            RMC::EndTime += RMC::TimeSpentMap;
            startnew(RMC::SwitchMap);
        }
    }
}