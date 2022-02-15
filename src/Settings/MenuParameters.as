namespace PluginSettings
{
    [Setting hidden]
    bool closeOverlayOnMapLoaded = true;

    [SettingsTab name="Menu"]
    void RenderMenuSettings()
    {
        closeOverlayOnMapLoaded = UI::Checkbox("Close overlay on map loaded", closeOverlayOnMapLoaded);
        UI::SetPreviousTooltip("This setting will not affect during RMC.");
    }
}