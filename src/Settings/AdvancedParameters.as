namespace PluginSettings {
    [Setting hidden]
    bool closeOverlayOnMapLoaded = true;

    [Setting hidden]
    string RMC_MX_Url = "https://" + MX_URL;

    [Setting hidden]
    string RMC_Leaderboard_Url = "https://flinkblog.de/RMC";

    [SettingsTab name="Advanced" order="4" icon="Wrench"]
    void RenderAdvancedSettings() {
        if (UI::OrangeButton("Reset to default")) {
            closeOverlayOnMapLoaded = true;
            RMC_MX_Url = "https://" + MX_URL;
            RMC_Leaderboard_Url = "https://flinkblog.de/RMC";
        }

        UI::SetNextItemWidth(300);
        RMC_MX_Url = UI::InputText("MX Base URL", RMC_MX_Url);
        UI::SettingDescription("Use this URL for API calls to ManiaExchange. Useful for hosting your own service for caching and preloading API responses for better performance.\n\nOnly change if you know what you're doing!");

        if (RMC_MX_Url.Length > 0 && RMC_MX_Url[RMC_MX_Url.Length - 1] == 47) {  // 47 is the ASCII code for a forward slash
            // Remove the last character if it's a forward slash
            RMC_MX_Url = RMC_MX_Url.SubStr(0, RMC_MX_Url.Length - 1);
        }

#if TMNEXT
        if (UI::Button("Use official TMX API")) {
            RMC_MX_Url = "https://" + MX_URL;
        }

        if (PluginSettings::RMC_PushLeaderboardResults) {
            UI::NewLine();
            RMC_Leaderboard_Url = UI::InputText("RMC & RMS Leaderboard URL", RMC_Leaderboard_Url);
            UI::SettingDescription("Use this URL for API calls to RMC & RMS Leaderboard. Useful for hosting your own service for storing your own scores.\n\nOnly change if you know what you're doing!");

            if (RMC_Leaderboard_Url.Length > 0 && RMC_Leaderboard_Url[RMC_Leaderboard_Url.Length - 1] == 47) {
                RMC_Leaderboard_Url = RMC_Leaderboard_Url.SubStr(0, RMC_Leaderboard_Url.Length - 1);
            }
        }

        UI::Separator();
#endif

        closeOverlayOnMapLoaded = UI::Checkbox("Close overlay on map loading", closeOverlayOnMapLoaded);
    }
}
