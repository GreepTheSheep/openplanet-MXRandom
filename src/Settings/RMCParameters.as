namespace PluginSettings {
    [Setting hidden]
    bool HideWithGameUI = true;

    [Setting hidden]
    bool HideWithOP = false;

    [Setting hidden]
    bool CloseOverlayOnMapLoad = true;

    [Setting hidden]
    Medals RMC_Medal = Medals::Author;

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
    bool RMC_ShowAwards = false;

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
    bool RMC_EditedMedalsWarns = true;

    [Settings hidden]
    bool RMC_DisplayGoalTimes = false;

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

    [Setting hidden]
    bool RMC_RUN_AUTOSAVE = true;

    [Setting hidden]
    bool RMC_PauseWhenMenuOpen = true;

    [Setting hidden]
    int RMC_FreeSkipAmount = 1;  // one free skip as per official rules

    [Setting hidden]
#if TMNEXT
    bool RMC_PushLeaderboardResults = true;
#else
    bool RMC_PushLeaderboardResults = false;
#endif

    [SettingsTab name="Random Map Challenge" order="1" icon="Random"]
    void RenderRMCSettingTab() {
        UI::BeginTabBar("RMCSettingsCategoryTabBar", UI::TabBarFlags::FittingPolicyResizeDown);

        if (UI::BeginTabItem(Icons::Cogs + " General")) {
            if (UI::OrangeButton("Reset to default")) {
                RMC_Medal = Medals::Author;
                RMC_AutoSwitch = true;
                RMC_ExitMapOnEndTime = false;
                RMC_RUN_AUTOSAVE = true;
                RMC_PauseWhenMenuOpen = true;
                RMC_Duration = 60;
                RMC_FreeSkipAmount = 1;
                RMC_SurvivalMaxTime = 15;
                RMC_PushLeaderboardResults = true;
            }

            UI::SetNextItemWidth(200);
            if (UI::BeginCombo("Goal", tostring(RMC_Medal))) {
                for (uint i = 0; i < Medals::Last; i++) {
                    if (UI::Selectable(tostring(Medals(i)), RMC_Medal == Medals(i))) {
                        RMC_Medal = Medals(i);
                    }

                    if (RMC_Medal == Medals(i)) {
                        UI::SetItemDefaultFocus();
                    }
                }

                UI::EndCombo();
            }

            RMC_AutoSwitch = UI::Checkbox("Automatically switch map after getting the " + tostring(RMC_Medal) + " medal", RMC_AutoSwitch);
            RMC_ExitMapOnEndTime = UI::Checkbox("Automatically quit the map when the timer is up", RMC_ExitMapOnEndTime);
            RMC_RUN_AUTOSAVE = UI::Checkbox("Automatically save the current run after stopping it", RMC_RUN_AUTOSAVE);
            RMC_PauseWhenMenuOpen = UI::Checkbox("Pause timer when the pause menu is open", RMC_PauseWhenMenuOpen);

            UI::SetNextItemWidth(300);
            RMC_Duration = UI::SliderInt("Random Map Challenge duration (in minutes)", RMC_Duration, 5, 300);
            UI::SetNextItemWidth(300);
            RMC_FreeSkipAmount = UI::SliderInt("Free skips per RMC run", RMC_FreeSkipAmount, 1, 200);
            UI::SetNextItemWidth(300);
            RMC_SurvivalMaxTime = UI::SliderInt("Maximum timer in Survival mode (in minutes)", RMC_SurvivalMaxTime, 2, 60);

#if TMNEXT
            RMC_PushLeaderboardResults = UI::Checkbox("Send every RMC & RMS runs to the leaderboard", RMC_PushLeaderboardResults);
            UI::SettingDescription("The leaderboard is available on https://flinkblog.de/RMC/");
#endif

            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::WindowMaximize + " Display")) {
            if (UI::OrangeButton("Reset to default")) {
                HideWithGameUI = true;
                HideWithOP = false;
                CloseOverlayOnMapLoad = true;
                RMC_AlwaysShowBtns = true;
                RMC_DisplayGoalTimes = false;
                RMC_DisplayMapTimeSpent = true;
                RMC_DisplayPace = false;
                RMC_SurvivalShowSurvivedTime = true;
                RMC_ImageSize = 25;
                RMC_DisplayCurrentMap = true;
                RMC_ShowAwards = false;
                RMC_DisplayMapDate = true;
#if TMNEXT
                RMC_PrepatchTagsWarns = true;
#endif
                RMC_EditedMedalsWarns = true;
                RMC_TagsLength = 1;
                
            }

            HideWithGameUI = UI::Checkbox("Show/Hide with game UI", HideWithGameUI);
            HideWithOP = UI::Checkbox("Show/Hide with Openplanet overlay", HideWithOP);
            CloseOverlayOnMapLoad = UI::Checkbox("Close Openplanet overlay on map loading", CloseOverlayOnMapLoad);

            UI::PaddedHeaderSeparator("Game modes");

            RMC_AlwaysShowBtns = UI::Checkbox("Show buttons when the Openplanet overlay is hidden", RMC_AlwaysShowBtns);
            RMC_DisplayGoalTimes = UI::Checkbox("Display goal times", RMC_DisplayGoalTimes);
            RMC_DisplayMapTimeSpent = UI::Checkbox("Time spent on the map", RMC_DisplayMapTimeSpent);
            RMC_DisplayPace = UI::Checkbox("Show the pace of the current run", RMC_DisplayPace);
            RMC_SurvivalShowSurvivedTime = UI::Checkbox("Total time survived (Survival only)", RMC_SurvivalShowSurvivedTime);
            UI::SetNextItemWidth(300);
            RMC_ImageSize = UI::SliderInt("Medals size", RMC_ImageSize, 15, 35);

            UI::PaddedHeaderSeparator("Map");

            RMC_DisplayCurrentMap = UI::Checkbox("Display the current map information", RMC_DisplayCurrentMap);

            UI::BeginDisabled(!RMC_DisplayCurrentMap);

            RMC_ShowAwards = UI::Checkbox("Award count", RMC_ShowAwards);
            RMC_DisplayMapDate = UI::Checkbox("Upload date", RMC_DisplayMapDate);

#if TMNEXT
            RMC_PrepatchTagsWarns = UI::Checkbox("Prepatch warnings", RMC_PrepatchTagsWarns);
            UI::SettingDescription("Display a warning if the map was built before certain physics patches (e.g. the bobsleigh update)");
#endif
            RMC_EditedMedalsWarns = UI::Checkbox("Edited medals warnings", RMC_EditedMedalsWarns);
            UI::SettingDescription("Display a warning if the map has medal times that differ from the default formula.");

            UI::SetNextItemWidth(200);
            RMC_TagsLength = UI::SliderInt("Tags displayed (0: hidden)", RMC_TagsLength, 0, 3);

            UI::EndDisabled();

            UI::EndTabItem();
        }

        UI::EndTabBar();
    }
}