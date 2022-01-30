namespace PluginSettings
{
    [Setting hidden]
    bool closeOverlayOnMapLoaded = true;

    [Setting hidden]
    bool dontShowChangeLog = false;

    [SettingsTab name="Menu"]
    void RenderMenuSettings()
    {
        closeOverlayOnMapLoaded = UI::Checkbox("Close overlay on map loaded", closeOverlayOnMapLoaded);
        UI::SetPreviousTooltip("This setting will not affect during RMC.");
        dontShowChangeLog = UI::Checkbox("Never show changelog when updating", dontShowChangeLog);
    }
}