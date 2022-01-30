namespace TM
{
    void LoadMap()
    {
        if (PluginSettings::closeOverlayOnMapLoaded) UI::HideOverlay();
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
        while(!app.ManiaTitleControlScriptAPI.IsReady) {
            yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
        }
        app.ManiaTitleControlScriptAPI.PlayMap(loadMapURL, "", "");
    }
}