namespace PluginSettings
{
    array<string> Medals = {
        "Bronze",
        "Silver",
        "Gold",
        "Author"
    };

    [Setting hidden]
    bool RMC_ShowWindow = true;

    string RMC_GoalMedal = Medals[3];

    [Setting hidden]
    bool RMC_DisplayCurrentMap = true;

    [Setting hidden]
    bool RMC_AutoSwitch = true;

    [Setting hidden]
    bool RMC_ExitMapOnEndTime = false;

    [Setting hidden]
    bool RMC_OnlySkipBtn = false;

    [Setting hidden]
    bool RMC_AlwaysShowBtns = true;

    [Setting hidden]
    int RMC_SurvivalMaxTime = 15;

    [SettingsTab name="Random Map Challenge"]
    void RenderRMCSettingTab()
    {
        UI::PushFont(Header1);
        UI::Text("Random Map Challenge / Survival");
        UI::PopFont();
        UI::TextWrapped("In the Random Map Challenge, you have to grab the maximum number of author medals in 1 hour.");
        UI::TextWrapped("In the Random Map Survival, you have to grab the maximum number of author medals before the timer reaches 0. You gain 3 minutes per medal won, you can skip but you lose 1 minute of your time limit");
        if (UI::GreenButton(Icons::ExternalLink + " More informations")) OpenBrowserURL("https://flinkblog.de/RMC/");
        UI::Separator();


        if (UI::Button("Reset to default"))
        {
            RMC_ShowWindow = true;
            RMC_DisplayCurrentMap = true;
            RMC_AutoSwitch = true;
            RMC_ExitMapOnEndTime = false;
            RMC_OnlySkipBtn = false;
            RMC_AlwaysShowBtns = true;
            RMC_SurvivalMaxTime = 15;
        }

        RMC_ShowWindow = UI::Checkbox("Show window", RMC_ShowWindow);
        RMC_DisplayCurrentMap = UI::Checkbox("Display the current map name, author and style (according to MX)", RMC_DisplayCurrentMap);

        if (UI::BeginCombo("Goal", RMC_GoalMedal)){
            for (uint i = 0; i < Medals.Length; i++) {
                string goalMedal = Medals[i];

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
        RMC_OnlySkipBtn = UI::Checkbox("Show Skip button on first map", RMC_OnlySkipBtn);
        RMC_AlwaysShowBtns = UI::Checkbox("Always show the buttons (even when the Openplanet overlay is hidden)", RMC_AlwaysShowBtns);

        UI::SetNextItemWidth(300);
        RMC_SurvivalMaxTime = UI::SliderInt("Maximum timer on Survival mode (in minutes)", RMC_SurvivalMaxTime, 2, 60);
    }
}