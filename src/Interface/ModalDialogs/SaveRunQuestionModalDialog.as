class SaveRunQuestionModalDialog : ModalDialog
{
    SaveRunQuestionModalDialog()
    {
        super("\\$f90" + Icons::ExclamationTriangle + " \\$zSave run?");
        m_size = vec2(400, 130);
    }

    void RenderDialog() override
    {
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::Text("Do you wish to save this run to continue it at a later point?");
        UI::EndChild();
        if (UI::Button(Icons::Times + " No")) {
            Close();
            DataManager::RemoveCurrentSaveFile();
            RMC::HasCompletedCheckbox = true;
        }
        UI::SameLine();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 70 * scale, UI::GetCursorPos().y));
        if (UI::OrangeButton(Icons::PlayCircleO + " Yes")) {
            Close();
            RMC::CurrentRunData["MapID"] = RMC::CurrentMapID;
            RMC::CurrentRunData["TimerRemaining"] = RMC::EndTimeCopyForSaveData - RMC::StartTimeCopyForSaveData;
            RMC::CurrentRunData["TimeSpentOnMap"] = RMC::TimeSpentMap;
            RMC::CurrentRunData["PrimaryCounterValue"] = RMC::GoalMedalCount;
            RMC::CurrentRunData["SecondaryCounterValue"] = RMC::selectedGameMode == RMC::GameMode::Challenge ? RMC::Challenge.BelowMedalCount : RMC::Survival.Skips;
            if (RMC::selectedGameMode == RMC::GameMode::Survival) {
                RMC::CurrentRunData["CurrentRunTime"] = RMC::Survival.SurvivedTime;
            } else {
                RMC::CurrentRunData["GotBelowMedalOnMap"] = RMC::GotBelowMedalOnCurrentMap;
                RMC::CurrentRunData["CurrentRunTime"] = RMC::Challenge.ModeStartTimestamp;
            }
            RMC::CurrentRunData["GotGoalMedalOnMap"] = RMC::GotGoalMedalOnCurrentMap;
            DataManager::SaveCurrentRunData();
            Log::Log("Saved run data", true);
            RMC::HasCompletedCheckbox = true;
        }
    }
}