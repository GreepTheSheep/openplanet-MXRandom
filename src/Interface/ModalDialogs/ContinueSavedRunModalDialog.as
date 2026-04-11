class ContinueSavedRunModalDialog : ModalDialog {
    bool HasCompletedCheckbox = false;
    RMC@ run;
    Json::Value@ runSave;

    ContinueSavedRunModalDialog(RMC@ mode, Json::Value@ save) {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zContinue Saved Run?");
        m_size = vec2(400, 160);
        @run = mode;
        @runSave = save;
    }

    void RenderDialog() override {
        float scale = UI::GetScale();

        UI::BeginChild("Content", vec2(0, -32) * scale);

        string lastLetter = tostring(run.Mode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        int PrimaryCounterValue = runSave["PrimaryCounterValue"];
        Medals runMedal = runSave.HasKey("Settings") ? Medals(int(runSave["Settings"]["GoalMedal"])) : PluginSettings::GoalMedal;

        UI::Text(
            "You already have a saved " + gameMode + " run with " + tostring(PrimaryCounterValue) + " " + tostring(runMedal) + "s"
            "\n\nDo you want to continue this run or start a new one?\n"
            "\nNOTE: Starting a new run will delete the current save!"
        );

        UI::EndChild();

        if (UI::OrangeButton(Icons::Times + " New Run")) {
            DataManager::RemoveCurrentSaveFile();
            HasCompletedCheckbox = true;
            Close();
        }

        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 100 * scale, UI::GetCursorPos().y));

        if (UI::GreenButton(Icons::PlayCircleO + " Continue")) {
            run.ContinueSavedRun = true;
            HasCompletedCheckbox = true;
            Close();
        }
    }
}