namespace TM {
    const uint COOLDOWN = 5000;
    array<uint> royalTimes = { 0, 0, 0, 0 };

    void LoadMap(ref@ mapData) {
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
        while (!app.ManiaTitleControlScriptAPI.IsReady) {
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

    bool IsMapCorrect(const string &in mapUid) {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        if (app.RootMap is null) return false;

        return app.RootMap.IdName == mapUid;
    }

    bool InRMCMap() {
        if (!IsMapLoaded() || DataJson["recentlyPlayed"].Length == 0) return false;

        return IsMapCorrect(string(DataJson["recentlyPlayed"][0]["MapUid"]));
    }

    // from TMX Together by Xertrov https://openplanet.dev/plugin/tmx-together

    uint PlaygroundGameTime() {
        auto app = GetApp();
        auto playgroundScript = app.Network.PlaygroundInterfaceScriptHandler;

        if (playgroundScript is null) return uint(-1);

        return uint(playgroundScript.GameTime);
    }

    uint PlaygroundStartTime() {
        auto app = GetApp();
        auto playground = cast<CSmArenaClient>(app.CurrentPlayground);

        if (playground is null || playground.Arena is null || playground.Arena.Rules is null) return uint(-1);

        return uint(playground.Arena.Rules.RulesStateStartTime);
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
        int authorTime = map.TMObjective_AuthorTime;
        MapTypes type = CurrentMapType();
        bool inverse = type == MapTypes::Stunt;

        uint normalGold;
        uint normalSilver;
        uint normalBronze;

        switch (type) {
            case MapTypes::Stunt:
                // Credits to beu and Ezio for the formula
                normalGold = uint(Math::Floor(authorTime * 0.085) * 10);
                normalSilver = uint(Math::Floor(authorTime * 0.06) * 10);
                normalBronze = uint(Math::Floor(authorTime * 0.037) * 10);
                break;
            case MapTypes::Platform:
                normalGold = authorTime + 3;
                normalSilver = authorTime + 10;
                normalBronze = authorTime + 30;
                break;
            case MapTypes::Race:
            case MapTypes::Royal:
            default:
                normalGold = uint((authorTime * 1.06) / 1000 + 1) * 1000;
                normalSilver = uint((authorTime * 1.2) / 1000 + 1) * 1000;
                normalBronze = uint((authorTime * 1.5) / 1000 + 1) * 1000;
                break;
        }

        if ((!inverse && map.TMObjective_GoldTime < normalGold) || (inverse && map.TMObjective_GoldTime > normalGold)) {
            return true;
        }

        if ((!inverse && map.TMObjective_SilverTime < normalSilver) || (inverse && map.TMObjective_SilverTime > normalSilver)) {
            return true;
        }

        if ((!inverse && map.TMObjective_BronzeTime < normalBronze) || (inverse && map.TMObjective_BronzeTime > normalBronze)) {
            return true;
        }

        return false;
    }

    string CurrentTitlePack() {
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
        if (IsPauseMenuDisplayed()) {
            CSmArenaClient@ playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
            if (playground !is null) {
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

    bool IsInServer() {
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

    int GetFinishScore() {
        if (!TM::IsMapLoaded()) {
            return -1;
        }

        auto app = cast<CTrackMania>(GetApp());
        int score = -1;

#if MP4
        CGameCtnPlayground@ playground = cast<CGameCtnPlayground>(app.CurrentPlayground);

        if (playground !is null && playground.PlayerRecordedGhost !is null) {
            if (playground.PlayerRecordedGhost.RaceTime != uint(-1)) {
                score = playground.PlayerRecordedGhost.RaceTime;
            }
        }
#elif TMNEXT
        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        CSmArenaRulesMode@ script = cast<CSmArenaRulesMode>(app.PlaygroundScript);
        MapTypes currentType = CurrentMapType();

        if (playground !is null && script !is null && playground.GameTerminals.Length > 0) {
            CSmPlayer@ player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);

            if (player is null) {
                return -1;
            }

            auto seq = playground.GameTerminals[0].UISequence_Current;

            if (seq == SGamePlaygroundUIConfig::EUISequence::Finish || seq == SGamePlaygroundUIConfig::EUISequence::UIInteraction) {
                CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
                auto ghost = script.Ghost_RetrieveFromPlayer(playerScriptAPI);

                if (ghost !is null) {
                    switch (currentType) {
                        case MapTypes::Stunt:
                            score = ghost.Result.StuntsScore;
                            break;
                        case MapTypes::Platform:
                            score = ghost.Result.NbRespawns;
                            break;
                        case MapTypes::Race:
                        case MapTypes::Royal:
                        default:
                            if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) {
                                score = ghost.Result.Time;
                            }
                            break;
                    }

                    script.DataFileMgr.Ghost_Release(ghost.Id);

                    // from the Random Altered Campaign Challenge plugin https://openplanet.dev/plugin/randomalteredcampaign
                    // Credit to ArEyeses for the code
                    if (currentType == MapTypes::Royal) {
                        uint resIndex = player.CurrentLaunchedRespawnLandmarkIndex;

                        if (resIndex >= 0 && resIndex < playground.Arena.MapLandmarks.Length) {
                            uint section = playground.Arena.MapLandmarks[resIndex].Order;

                            if (section == 5) {
                                return royalTimes[0] + royalTimes[1] + royalTimes[2] + royalTimes[3] + score;
                            }

                            royalTimes[section - 1] = score;

                            // Reset section times from previous runs
                            for (uint i = section; i < royalTimes.Length; i++) {
                                royalTimes[i] = 0;
                            }

                            return -1;
                        }

                        return -1;
                    }
                }
            }
        }
#endif
        return score;
    }

    MapTypes CurrentMapType() {
        CTrackMania@ app = cast<CTrackMania>(GetApp());
        string mapType = app.RootMap.MapType;

        if (mapType.Contains("Stunt")) {
            return MapTypes::Stunt;
        } else if (mapType.Contains("Platform")) {
            return MapTypes::Platform;
        } else if (mapType.EndsWith("Royal")) {
            return MapTypes::Royal;
        }

        return MapTypes::Race;
    }

    bool IsPlayerReady() {
        auto app = cast<CTrackMania>(GetApp());

        auto playground = cast<CGamePlayground>(app.CurrentPlayground);
        if (playground is null || playground.GameTerminals.Length == 0) {
            return false;
        }

        CGameTerminal@ terminal = playground.GameTerminals[0];
        if (terminal is null) {
            return false;
        }

#if TMNEXT
        if (terminal.UISequence_Current != SGamePlaygroundUIConfig::EUISequence::Playing) return false;

        auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);
        uint gametime = PlaygroundGameTime();
        if (player is null || player.StartTime < 0 || player.StartTime > int(gametime) || player.ScriptAPI is null) {
            return false;
        }

        auto script = cast<CSmScriptPlayer>(player.ScriptAPI);
        if (script.Post == 0) {
            return false;
        }
#else
        auto player = cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer);
        if (player is null || player.RaceState != CTrackManiaPlayer::ERaceState::Running) {
            return false;
        }
#endif

        return true;
    }

    bool IsServerReady() {
        if (!IsPlayerReady()) {
            return false;
        }

        uint start = PlaygroundStartTime();
        uint gametime = PlaygroundGameTime();

        return gametime > start;
    }
}