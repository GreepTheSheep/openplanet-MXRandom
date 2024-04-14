namespace PluginSettings
{
    [Setting hidden]
    bool closeOverlayOnMapLoaded = true;

    [Setting hidden]
#if TMNEXT
    string RMC_MX_Url = "https://map-monitor.xk.io";
#else
    string RMC_MX_Url = "https://" + MX_URL;
#endif

    // add a setting that people can toggle to switch between to the old length checks and manual length checks, in case the API starts failing.
    [Setting hidden]
    bool UseLengthChecksInRequests = true;

    [SettingsTab name="Advanced" order="3" icon="Wrench"]
    void RenderAdvancedSettings()
    {
        if (UI::OrangeButton("Reset to default"))
        {
            closeOverlayOnMapLoaded = true;
            RMC_MX_Url = "https://" + MX_URL;
            UseLengthChecksInRequests = true;
        }

        UI::SetNextItemWidth(300);
        RMC_MX_Url = UI::InputText("MX Base URL", RMC_MX_Url);
        UI::SetPreviousTooltip("Use this URL for API calls to ManiaExchange. Useful for hosting your own service for caching and preloading API responses for better performance.\nOnly change if you know what you're doing!");

        if (RMC_MX_Url.Length > 0 && RMC_MX_Url[RMC_MX_Url.Length - 1] == 47) {  // 47 is the ASCII code for a forward slash
            // Remove the last character if it's a forward slash
            RMC_MX_Url = RMC_MX_Url.SubStr(0, RMC_MX_Url.Length - 1);
        }

#if TMNEXT
        if (UI::Button("Use official TMX API")) {
            RMC_MX_Url = "https://" + MX_URL;
        }

        // Commented for the moment since it's not ready yet
        // bool clickedDanApi = UI::Button("Use DanOnTheMoon's Preloading + Proxy API");
        // UI::SetPreviousTooltip("Much faster API that preloads random maps and proxies requests to TMX.");
        // if (clickedDanApi) {
        //     RMC_MX_Url = "https://mx.danonthemoon.dev/mx";
        // }

        bool clickedXertApi = UI::Button("Use XertroV's API w/ Fixed Randomization");
        UI::SetPreviousTooltip("Much faster random API for TMX maps, and fixes TMX's broken randomization.\nAll TMX maps are cached and standard RMC map filtering applies.");
        if (clickedXertApi) {
            RMC_MX_Url = "https://map-monitor.xk.io";
        }

        UI::Separator();
#endif

        closeOverlayOnMapLoaded = UI::Checkbox("Close overlay on map loading", closeOverlayOnMapLoaded);

        UseLengthChecksInRequests = UI::Checkbox("Use length filters in API requests", UseLengthChecksInRequests);
        UI::SetPreviousTooltip("Length filter setting. Toggle this when TMX gives super long response times.");
    }
}
