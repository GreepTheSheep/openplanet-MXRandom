class ContinueSavedRunModalDialog : ModalDialog {
    bool HasCompletedCheckbox = false;
    RMC@ run;

    ContinueSavedRunModalDialog(RMC@ mode) {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zContinue Saved Run?");
        m_size = vec2(400, 160);
        @run = mode;
    }

    void RenderDialog() override {
        float scale = UI::GetScale();

        UI::BeginChild("Content", vec2(0, -32) * scale);

        string lastLetter = tostring(run.Mode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        int PrimaryCounterValue = RMC::CurrentRunData["PrimaryCounterValue"];

        UI::Text(
            "You already have a saved " + gameMode + " run with " + tostring(PrimaryCounterValue) + " " + tostring(PluginSettings::RMC_Medal) + "s"
            "\n\nDo you want to continue this run or start a new one?\n"
            "\nNOTE: Starting a new run will delete the current save!"
        );

        UI::EndChild();

        if (UI::Button(Icons::Times + " New Run")) {
            DataManager::RemoveCurrentSaveFile();
            HasCompletedCheckbox = true;
            Close();
        }

        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 100 * scale, UI::GetCursorPos().y));

        if (UI::OrangeButton(Icons::PlayCircleO + " Continue")) {
            run.ContinueSavedRun = true;
            HasCompletedCheckbox = true;
            Close();
        }
    }
}