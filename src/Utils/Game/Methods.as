namespace TM
{
    void LoadMap(ref@ mapData)
    {
        MX::MapInfo@ map = cast<MX::MapInfo@>(mapData);

        if (PluginSettings::closeOverlayOnMapLoaded) UI::HideOverlay();
#if TMNEXT
        ClosePauseMenu();
#endif
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
        while(!app.ManiaTitleControlScriptAPI.IsReady) {
            yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
        }

        string url = PluginSettings::RMC_MX_Url + "/mapgbx/" + map.MapId;

#if DEPENDENCY_CHAOSMODE
        if (ChaosMode::IsInRMCMode()) {
            Log::Trace("Loading map in Chaos Mode");
            app.ManiaTitleControlScriptAPI.PlayMap(url, "TrackMania/ChaosModeRMC", "");
            return;
        }
#endif

        string gameMode;
        MX::ModesFromMapType.Get(map.MapType, gameMode);

#if MP4
        if (gameMode == "") MX::ModesFromTitlePack.Get(map.TitlePack, gameMode);
#endif

        app.ManiaTitleControlScriptAPI.PlayMap(url, gameMode, "");
    }

    bool IsMapLoaded(){
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap is null) return false;
        else return true;
    }

    bool IsMapCorrect(const string &in mapUid){
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap is null) return false;
        else return app.RootMap.MapInfo.MapUid == mapUid;
    }

    string CurrentTitlePack()
    {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.LoadedManiaTitle is null) return "";
        string titleId = app.LoadedManiaTitle.TitleId;
#if MP4
        return titleId.SubStr(0, titleId.IndexOf("@"));
#else
        return titleId;
#endif
    }

    void ClosePauseMenu() {
        if(IsPauseMenuDisplayed()) {
            CSmArenaClient@ playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
            if(playground !is null) {
                playground.Interface.ManialinkScriptHandler.CloseInGameMenu(CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Resume);
            }
        }
    }

    bool IsPauseMenuDisplayed() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        return app.ManiaPlanetScriptAPI.ActiveContext_InGameMenuDisplayed;
    }

    bool IsInServer(){
        CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork>(GetApp().Network);
        CGameCtnNetServerInfo@ ServerInfo = cast<CGameCtnNetServerInfo>(Network.ServerInfo);
        return ServerInfo.JoinLink != "";
    }

    int GetWorldRecordFromCache(const string &in mapUid) {
        int valueReturn;
        if (worldRecordsCache.Get(mapUid, valueReturn)) return valueReturn;
        else return -1;
    }

    void SetWorldRecordToCache(const string &in mapUid, const uint &in time) {
        worldRecordsCache.Set(mapUid, time);
    }
}