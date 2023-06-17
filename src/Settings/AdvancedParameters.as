namespace PluginSettings
{
    [Setting hidden]
    bool closeOverlayOnMapLoaded = true;

    [Setting hidden]
    string RMC_MX_Url = "https://" + MX_URL;

    [SettingsTab name="Advanced" order="3" icon="Wrench"]
    void RenderAdvancedSettings()
    {
        if (UI::OrangeButton("Reset to default"))
        {
            closeOverlayOnMapLoaded = true;
            RMC_MX_Url = "https://" + MX_URL;
        }

        UI::SetNextItemWidth(300);
        RMC_MX_Url = UI::InputText("MX Base URL", RMC_MX_Url);
        UI::SetPreviousTooltip("Use this URL for API calls to ManiaExchange. Useful for hosting your own service for caching and preloading api responses for better performance.\nOnly change if you know what you're doing!");

        closeOverlayOnMapLoaded = UI::Checkbox("Close overlay on map loading", closeOverlayOnMapLoaded);
    }
}