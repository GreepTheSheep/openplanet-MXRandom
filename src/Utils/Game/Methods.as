namespace TM
{
    const uint COOLDOWN = 5000;

    void LoadMap(ref@ mapData)
    {
#if TMNEXT
        if (!Permissions::PlayLocalMap()) {
            Log::Error("Missing permission to play local maps. Club / Standard access is required.", true);
            return;
        }
#elif MP4
        if (TM::CurrentTitlePack() == "") {
            Log::Error("No titlepack is selected, can't load map!.", true);
            return;
        }
#endif

        MX::MapInfo@ map = cast<MX::MapInfo>(mapData);

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

        string gameMode;
        MX::ModesFromMapType.Get(map.MapType, gameMode);

#if MP4
        if (gameMode == "") MX::ModesFromTitlePack.Get(map.TitlePack, gameMode);
#endif

#if DEPENDENCY_CHAOSMODE
        if (ChaosMode::IsInRMCMode()) {
            gameMode = "TrackMania/ChaosModeRMC";
        }
#endif

        app.ManiaTitleControlScriptAPI.PlayMap(url, gameMode, "");

        const uint start = Time::Now;

        while (Time::Now < start + COOLDOWN || IsLoadingScreen()) {
            yield();
        }
    }

    bool IsMapLoaded() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        return app.RootMap !is null;
    }

    bool IsMapCorrect(const string &in mapUid){
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap is null) return false;

        return app.RootMap.MapInfo.MapUid == mapUid;
    }

    bool InRMCMap() {
        if (!IsMapLoaded() || DataJson["recentlyPlayed"].Length == 0) return false;

        return IsMapCorrect(string(DataJson["recentlyPlayed"][0]["MapUid"]));
    }

    uint PlaygroundGameTime() {
        auto app = GetApp();
        auto playgroundScript = app.Network.PlaygroundClientScriptAPI;
        if (playgroundScript is null) return uint(-1);
        return uint(playgroundScript.GameTime);
    }

    void LoadRMCMap() {
        if (DataJson["recentlyPlayed"].Length == 0) return;

        MX::MapInfo@ map = MX::MapInfo(DataJson["recentlyPlayed"][0]);
        if (IsMapCorrect(map.MapUid)) return;

        startnew(LoadMap, map);
    }

    bool HasEditedMedals() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap is null) return false;

        auto map = app.RootMap;

        uint normalGold = uint((map.TMObjective_AuthorTime * 1.06) / 1000 + 1) * 1000;
        uint normalSilver = uint((map.TMObjective_AuthorTime * 1.2) / 1000 + 1) * 1000;
        uint normalBronze = uint((map.TMObjective_AuthorTime * 1.5) / 1000 + 1) * 1000;

        if (map.TMObjective_GoldTime < normalGold) {
            return true;
        }

        if (map.TMObjective_SilverTime < normalSilver) {
            return true;
        }

        if (map.TMObjective_BronzeTime < normalBronze) {
            return true;
        }

        return false;
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

    bool IsLoadingScreen() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());

        auto scriptAPI = app.Network.PlaygroundClientScriptAPI;
        if (scriptAPI !is null && scriptAPI.IsLoadingScreen) {
            return true;
        }

        auto script = app.PlaygroundScript;
        if (script is null) return false;

        auto manager = script.UIManager;
        if (manager !is null && manager.HoldLoadingScreen) {
            return true;
        }

        return false;
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