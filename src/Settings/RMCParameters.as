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
    bool RMC_DisplayPace = false;

    [Setting hidden]
    uint RMC_TagsLength = 1;

    [Setting hidden]
    bool RMC_ShowAwards = true;

    [Setting hidden]
    bool RMC_SurvivalShowSurvivedTime = true;

    [Setting hidden]
    bool RMC_DisplayMapTimeSpent = true;

    [Setting hidden]
    bool RMC_DisplayMapDate = true;

    [Setting hidden]
    int RMC_Duration = 60;

    [Setting hidden]
    int RMC_SurvivalMaxTime = 15;

    [Setting hidden]
#if TMNEXT
    bool RMC_PrepatchTagsWarns = true;
#else
    bool RMC_PrepatchTagsWarns = false;
#endif

    [Setting hidden]
    int RMC_ImageSize = 25;

    [Setting hidden]
    int RMC_ObjectiveMode_Goal = 5;

    [Setting hidden]
    bool RMC_ObjectiveMode_DisplayRemaininng = true;

    [Setting hidden]
    int RMC_Together_ClubId = 0;

    [Setting hidden]
    int RMC_Together_RoomId = 0;

    [SettingsTab name="Random Map Challenge"]
    void RenderRMCSettingTab(bool dontShowBaseInfos = false)
    {
        if (!dontShowBaseInfos) {
            RMC::RenderBaseInfos();
            UI::Separator();
        }

        UI::BeginTabBar("RMCSettingsCategoryTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
        if (UI::BeginTabItem(Icons::Cogs + " Base Settings"))
        {
            if (UI::OrangeButton("Reset to default"))
            {
                RMC_GoalMedal = RMC::Medals[3];
                RMC_AutoSwitch = true;
                RMC_ExitMapOnEndTime = false;
                RMC_Duration = 60;
                RMC_SurvivalMaxTime = 15;
                RMC_PrepatchTagsWarns = true;
            }
            if (UI::BeginCombo("Goal", RMC_GoalMedal)){
                for (uint i = 0; i < RMC::Medals.Length; i++) {
                    string goalMedal = RMC::Medals[i];

                    if (UI::Selectable(goalMedal, RMC_GoalMedal == goalMedal)) {
                        RMC_GoalMedal = goalMedal;
                    }

                    if (RMC_GoalMedal == goalMedal) {
                        UI::SetItemDefaultFocus();
                    }
                }
                UI::EndCombo();
            }

            RMC_AutoSwitch = UI::Checkbox("Automatically switch map when got "+RMC_GoalMedal+" medal", RMC_AutoSwitch);
            RMC_ExitMapOnEndTime = UI::Checkbox("Automatically quits the map when the timer is up", RMC_ExitMapOnEndTime);

            UI::SetNextItemWidth(300);
            RMC_Duration = UI::SliderInt("Random Map Challange duration (in minutes)", RMC_Duration, 10, 120);
            UI::SetNextItemWidth(300);
            RMC_SurvivalMaxTime = UI::SliderInt("Maximum timer on Survival mode (in minutes)", RMC_SurvivalMaxTime, 2, 60);

#if TMNEXT
            RMC_PrepatchTagsWarns = UI::Checkbox("Prepatch maps warnings", RMC_PrepatchTagsWarns);
            UI::SetPreviousTooltip("Display a warning if the map is built before the new physics patches (eg the bobsleigh update)");
#endif
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::WindowMaximize + " Display Settings"))
        {
            if (UI::OrangeButton("Reset to default"))
            {
                RMC_DisplayCurrentMap = true;
                RMC_AlwaysShowBtns = true;
                RMC_SurvivalShowSurvivedTime = true;
                RMC_DisplayMapTimeSpent = true;
                RMC_DisplayMapDate = true;
                RMC_TagsLength = 1;
                RMC_ImageSize = 20;
            }
            RMC_DisplayCurrentMap = UI::Checkbox("Display the current map name, author and style (according to MX)", RMC_DisplayCurrentMap);
            RMC_AlwaysShowBtns = UI::Checkbox("Always show the buttons (even when the Openplanet overlay is hidden)", RMC_AlwaysShowBtns);
            RMC_DisplayPace = UI::Checkbox("Show goal pace during the run", RMC_DisplayPace);
            RMC_SurvivalShowSurvivedTime = UI::Checkbox("Display the time survived in Survival mode", RMC_SurvivalShowSurvivedTime);
            RMC_DisplayMapTimeSpent = UI::Checkbox("Display the time spent on the actual map", RMC_DisplayMapTimeSpent);
            RMC_DisplayMapDate = UI::Checkbox("Display the date the map was last updated", RMC_DisplayMapDate);
            RMC_ShowAwards = UI::Checkbox("Display the amount of awards the map has received", RMC_ShowAwards);
            UI::SetNextItemWidth(100);
            RMC_TagsLength = UI::SliderInt("Display Map Tags Length (0: hidden)", RMC_TagsLength, 0, 3);

            UI::SetNextItemWidth(300);
            RMC_ImageSize = UI::SliderInt("Medals size", RMC_ImageSize, 15, 35);
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }
}