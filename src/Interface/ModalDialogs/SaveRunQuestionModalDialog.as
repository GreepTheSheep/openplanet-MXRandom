class SaveRunQuestionModalDialog : ModalDialog {
    SaveRunQuestionModalDialog() {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zSave run?");
        m_size = vec2(400, 130);
    }

    void RenderDialog() override {
        float scale = UI::GetScale();

        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Do you wish to save this run to continue it at a later point?");
        UI::EndChild();

        if (UI::Button(Icons::Times + " No")) {
            Close();
            DataManager::RemoveCurrentSaveFile();
        }

        UI::SameLine();

        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70 * scale, UI::GetCursorPos().y));

        if (UI::OrangeButton(Icons::PlayCircleO + " Yes")) {
            Close();
            RMC::CreateSave();
            Log::Log("Saved run data", true);
        }
    }
}