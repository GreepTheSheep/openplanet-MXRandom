namespace PluginSettings {
    [Setting hidden]
    string RMC_MX_Url = MX_URL;

    [Setting hidden]
    string RMC_Leaderboard_Url = "https://flinkblog.de/RMC";

    [Setting hidden]
    bool RMC_Xertrov_API_Download = false;

    [Setting hidden]
    LogLevel LoggingLevel = LogLevel::Info;

    [SettingsTab name="Advanced" order="4" icon="Wrench"]
    void RenderAdvancedSettings() {
        if (UI::OrangeButton("Reset to default")) {
            RMC_MX_Url = MX_URL;
            RMC_Xertrov_API_Download = false;
            RMC_Leaderboard_Url = "https://flinkblog.de/RMC";
            LoggingLevel = LogLevel::Info;
        }

        if (RMC_MX_Url != MX_URL) {
            Controls::FrameWarning(Icons::ExclamationTriangle + " Using a different API from MX might cause unexpected issues, including crashes and filters not working.");
        }

        UI::SetNextItemWidth(300);
        RMC_MX_Url = UI::InputText("MX Base URL", RMC_MX_Url);
        UI::SettingDescription("Use this URL for API calls to ManiaExchange. Useful for hosting your own service for caching and preloading API responses for better performance.\n\nOnly change if you know what you're doing!");

        if (RMC_MX_Url.EndsWith("/")) {
            RMC_MX_Url = RMC_MX_Url.SubStr(0, RMC_MX_Url.Length - 1);
        }

        if (UI::Button("Use official MX API")) {
            RMC_MX_Url = MX_URL;
        }

#if TMNEXT
        RMC_Xertrov_API_Download = UI::Checkbox("Use Xertrov's API to load maps", RMC_Xertrov_API_Download);
        UI::SettingDescription("Use Xertrov's API to load TMX maps (Plugin will still use the MX base URL for everything else).\n\n\\$f80" + Icons::ExclamationTriangle + "\\$z Only use this setting if you are experiencing crashes while loading maps.");

        if (PluginSettings::RMC_PushLeaderboardResults) {
            UI::SetNextItemWidth(300);
            RMC_Leaderboard_Url = UI::InputText("RMC & RMS Leaderboard URL", RMC_Leaderboard_Url);
            UI::SettingDescription("Use this URL for API calls to RMC & RMS Leaderboard. Useful for hosting your own service for storing your own scores.\n\nOnly change if you know what you're doing!");

            if (RMC_Leaderboard_Url.EndsWith("/")) {
                RMC_Leaderboard_Url = RMC_Leaderboard_Url.SubStr(0, RMC_Leaderboard_Url.Length - 1);
            }
        }

        UI::Separator();
#endif

        UI::SetNextItemWidth(175);
        if (UI::BeginCombo("Log level", tostring(LoggingLevel))) {
            for (int i = 0; i <= LogLevel::Trace; i++) {
                if (UI::Selectable(tostring(LogLevel(i)), LoggingLevel == LogLevel(i))) {
                    LoggingLevel = LogLevel(i);
                }
            }

            UI::EndCombo();
        }
    }
}
