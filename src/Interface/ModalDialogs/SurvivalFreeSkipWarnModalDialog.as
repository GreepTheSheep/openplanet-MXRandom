class SurvivalFreeSkipWarnModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    string resErrorString;
    Json::Value m_rulesJson;
    bool m_requestError = false;

    SurvivalFreeSkipWarnModalDialog()
    {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zWarning###RMSFreeSkip");
        m_size = vec2(400, 130);
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -32));
        UI::Text("Free skips is only if the map is impossible or broken.\n\nAre you sure to skip?");
        UI::EndChild();
        if (UI::Button(Icons::Times + " No")) {
            Close();
            RMC::EndTime = RMC::EndTime + (Time::get_Now() - RMC::StartTime);
            RMC::IsPaused = false;
        }
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70, UI::GetCursorPos().y));
        if (UI::OrangeButton(Icons::PlayCircleO + " Yes")) {
            Close();
            RMC::EndTime = RMC::EndTime + (Time::get_Now() - RMC::StartTime);
            RMC::IsPaused = false;
            print("RMC: Survival Free Skip");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
    }
}