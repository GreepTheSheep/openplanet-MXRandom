class ResetRunModalDialog : ModalDialog {
    RMC@ currentRun;
	bool HasCompletedCheckbox;
	bool ResetRun;

    ResetRunModalDialog(RMC@ run) {
        super(Icons::Refresh + " Reset run?");
        m_size = vec2(400, 100);
        @currentRun = run;
    }

    bool CanClose() override {
        return false;
    }

    void RenderDialog() override {
        float scale = UI::GetScale();

        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Are you sure you want to reset this run?");
        UI::EndChild();

        if (UI::RedButton(Icons::Times + " No")) {
			HasCompletedCheckbox = true;
            Close();
        }

        UI::SameLine();

        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70 * scale, UI::GetCursorPos().y));

        if (UI::GreenButton(Icons::Check + " Yes")) {
			HasCompletedCheckbox = true;
			ResetRun = true;
            Close();
        }
    }
}
