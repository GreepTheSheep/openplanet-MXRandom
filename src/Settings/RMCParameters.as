namespace PluginSettings
{
    [Setting hidden]
    string RMC_GoalMedal = RMC::Medals[3];

    [Setting hidden]
    bool RMC_DisplayCurrentMap = true;

    [Setting hidden]
    bool RMC_AutoSwitch = true;

    [Setting hidden]
    bool RMC_ExitMapOnEndTime = false;

    [Setting hidden]
    bool RMC_AlwaysShowBtns = true;

    [Setting hidden]
    int RMC_SurvivalMaxTime = 15;

    [SettingsTab name="Random Map Challenge"]
    void RenderRMCSettingTab(bool dontShowBaseInfos = false)
    {
        if (!dontShowBaseInfos) {
            RMC::RenderBaseInfos();
            UI::Separator();
        }

        if (UI::OrangeButton("Reset to default"))
        {
            RMC_GoalMedal = RMC::Medals[3];
            RMC_DisplayCurrentMap = true;
            RMC_AutoSwitch = true;
            RMC_ExitMapOnEndTime = false;
            RMC_AlwaysShowBtns = true;
            RMC_SurvivalMaxTime = 15;
        }

        RMC_DisplayCurrentMap = UI::Checkbox("Display the current map name, author and style (according to MX)", RMC_DisplayCurrentMap);

        if (UI::BeginCombo("Goal", RMC_GoalMedal)){
            for (uint i = 0; i < RMC::Medals.Length; i++) {
                string goalMedal = RMC::Medals[i];

                if (UI::Selectable(goalMedal, MapLengthOperator == goalMedal)) {
                    RMC_GoalMedal = goalMedal;
                }

                if (MapLengthOperator == goalMedal) {
                    UI::SetItemDefaultFocus();
                }
            }
            UI::EndCombo();
        }

        RMC_AutoSwitch = UI::Checkbox("Automatically switch map when got "+RMC_GoalMedal+" medal", RMC_AutoSwitch);
        RMC_ExitMapOnEndTime = UI::Checkbox("Automatically quits the map when the timer is up", RMC_ExitMapOnEndTime);
        RMC_AlwaysShowBtns = UI::Checkbox("Always show the buttons (even when the Openplanet overlay is hidden)", RMC_AlwaysShowBtns);

        UI::SetNextItemWidth(300);
        RMC_SurvivalMaxTime = UI::SliderInt("Maximum timer on Survival mode (in minutes)", RMC_SurvivalMaxTime, 2, 60);
    }
}