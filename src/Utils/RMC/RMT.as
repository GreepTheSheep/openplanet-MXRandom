class RMT : RMC
{
    string LobbyMapUID = "";
    NadeoServices::ClubRoom@ RMTRoom;
    MX::MapInfo@ currentMap;
    uint lastPbUpdate = 0;
    array<PBTime@> m_records;
    bool m_CurrentlyLoadingRecords = false;
    PBTime@ playerGotGoalActualMap;
    PBTime@ playerGotBelowGoalActualMap;

    string GetModeName() override { return "Random Map Together";}

    void StartRMT()
    {
        RMC::ShowTimer = true;
        Log::Trace("RMT: Getting lobby map UID from the room...");
        MXNadeoServicesGlobal::CheckNadeoRoomAsync();
        yield();
        @RMTRoom = MXNadeoServicesGlobal::foundRoom;
        LobbyMapUID = RMTRoom.room.currentMapUid;
        Log::Trace("RMT: Lobby map UID: " + LobbyMapUID);
        SetupMapStart();
    }

    void SetupMapStart() {
        // Fetch a map
        Log::Trace("RMT: Fetching a random map...");
        Json::Value res = API::GetAsync(MX::CreateQueryURL())["results"][0];
        Json::Value playedAt = Json::Object();
        Time::Info date = Time::Parse();
        playedAt["Year"] = date.Year;
        playedAt["Month"] = date.Month;
        playedAt["Day"] = date.Day;
        playedAt["Hour"] = date.Hour;
        playedAt["Minute"] = date.Minute;
        playedAt["Second"] = date.Second;
        res["PlayedAt"] = playedAt;
        @currentMap = MX::MapInfo(res);
        Log::Trace("RMT: Random map: " + currentMap.Name + " (" + currentMap.TrackID + ")");

        if (!MXNadeoServicesGlobal::CheckIfMapExistsAsync(currentMap.TrackUID)) {
            Log::Trace("RMT: Map is not on NadeoServices, retrying...");
            SetupMapStart();
            return;
        }

        MXNadeoServicesGlobal::SetMapToClubRoomAsync(RMTRoom, currentMap.TrackUID);
        MXNadeoServicesGlobal::ClubRoomSwitchMapAsync(RMTRoom);
        while (!TM::IsMapCorrect(currentMap.TrackUID)) {
            sleep(1000);
        }
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, TimeLimit() / 1000);
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
        while (GamePlayground is null || GamePlayground.GameTerminals.Length < 1 || GamePlayground.GameTerminals[0].GUIPlayer is null) {
            sleep(1000);
        }
        CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].GUIPlayer);
        while (player is null){
            yield();
        }
        CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
        while (playerScriptAPI.Post == 0){
            yield();
        }
        StartTimer();
        startnew(CoroutineFunc(UpdateRecordsLoop));
        RMC::TimeSpawnedMap = Time::Now;
    }

    void TimerYield() override
    {
        while (RMC::IsRunning){
            yield();
            RMC::IsPaused = false;
            CGameCtnChallenge@ currentMapChallenge = cast<CGameCtnChallenge>(GetApp().RootMap);
            if (currentMapChallenge !is null) {
                CGameCtnChallengeInfo@ currentMapInfo = currentMapChallenge.MapInfo;
                if (currentMapInfo !is null) {
                    RMC::StartTime = Time::Now;
                    RMC::TimeSpentMap = Time::Now - RMC::TimeSpawnedMap;
                    PendingTimerLoop();

                    if (RMC::StartTime > RMC::EndTime) {
                        RMC::StartTime = -1;
                        RMC::EndTime = -1;
                        RMC::IsRunning = false;
                        RMC::ShowTimer = false;
                        GameEndNotification();
                    }
                }
            }

            if (isObjectiveCompleted() && !RMC::GotGoalMedalOnCurrentMap){
                Log::Log(playerGotGoalActualMap.name + " got goal medal with a time of " + playerGotGoalActualMap.time);
                UI::ShowNotification("\\$071" + Icons::Trophy + " " + playerGotGoalActualMap.name + " got "+tostring(PluginSettings::RMC_GoalMedal)+" medal with a time of " + playerGotGoalActualMap.timeStr);
                RMC::GoalMedalCount += 1;
                RMC::GotGoalMedalOnCurrentMap = true;
            }
            if (
                isBelowObjectiveCompleted() &&
                !RMC::GotBelowMedalOnCurrentMap &&
                PluginSettings::RMC_GoalMedal != RMC::Medals[0])
            {
                Log::Log(playerGotBelowGoalActualMap.name + " got below goal medal with a time of " + playerGotBelowGoalActualMap.time);
                UI::ShowNotification("\\$db4" + Icons::Trophy + " " + playerGotBelowGoalActualMap.name + " got "+RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]+" medal with a time of " + playerGotBelowGoalActualMap.timeStr);
                RMC::GotBelowMedalOnCurrentMap = true;
            }
        }
    }

    void RenderCurrentMap() override
    {
        CGameCtnChallenge@ currentMapChallenge = cast<CGameCtnChallenge>(GetApp().RootMap);
        if (currentMapChallenge !is null) {
            CGameCtnChallengeInfo@ currentMapInfo = currentMapChallenge.MapInfo;
            if (currentMapInfo !is null) {
                UI::Separator();
                if (currentMap !is null) {
                    UI::Text(currentMap.Name);
                    UI::TextDisabled("by " + currentMap.Username);
#if TMNEXT
                    if (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.isMapHasPrepatchMapTags(currentMap)) {
                        RMCConfigMapTag@ prepatchTag = RMC::config.getMapPrepatchMapTag(currentMap);
                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z"+prepatchTag.title);
                        UI::SetPreviousTooltip(prepatchTag.reason + (IS_DEV_MODE ? ("\nExeBuild: " + currentMap.ExeBuild) : ""));
                    }
#endif
                    if (PluginSettings::RMC_TagsLength != 0) {
                        if (currentMap.Tags.Length == 0) UI::TextDisabled("No tags");
                        else {
                            uint tagsLength = currentMap.Tags.Length;
                            if (currentMap.Tags.Length > PluginSettings::RMC_TagsLength) tagsLength = PluginSettings::RMC_TagsLength;
                            for (uint i = 0; i < tagsLength; i++) {
                                Render::MapTag(currentMap.Tags[i]);
                                UI::SameLine();
                            }
                            UI::NewLine();
                        }
                    }
                } else {
                    UI::Separator();
                    UI::TextDisabled("Map info unavailable");
                }
            }
        } else {
            UI::Separator();
            UI::AlignTextToFramePadding();
            UI::Text("Switching map...");
        }
    }

    bool isObjectiveCompleted()
    {
        if (GetApp().RootMap !is null) {
            uint objectiveTime = -1;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) objectiveTime = GetApp().RootMap.MapInfo.TMObjective_AuthorTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) objectiveTime = GetApp().RootMap.MapInfo.TMObjective_GoldTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) objectiveTime = GetApp().RootMap.MapInfo.TMObjective_SilverTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[0]) objectiveTime = GetApp().RootMap.MapInfo.TMObjective_BronzeTime;


            if (m_records.Length > 0) {
                for (uint r = 0; r < m_records.Length; r++) {
                    if (m_records[r].time <= 0) continue;
                    if (m_records[r].time <= objectiveTime) {
                        @playerGotGoalActualMap = m_records[r];
                        return true;
                    }
                }
            }
        }
        return false;
    }

    bool isBelowObjectiveCompleted()
    {
        if (GetApp().RootMap !is null) {
            uint objectiveTime = -1;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) objectiveTime = GetApp().RootMap.MapInfo.TMObjective_GoldTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) objectiveTime = GetApp().RootMap.MapInfo.TMObjective_SilverTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) objectiveTime = GetApp().RootMap.MapInfo.TMObjective_BronzeTime;


            if (m_records.Length > 0) {
                for (uint r = 0; r < m_records.Length; r++) {
                    if (m_records[r].time <= 0) continue;
                    if (m_records[r].time <= objectiveTime) {
                        @playerGotBelowGoalActualMap = m_records[r];
                        return true;
                    }
                }
            }
        }
        return false;
    }

    void UpdateRecords() {
        lastPbUpdate = Time::Now;
        auto newPBs = GetPlayersPBs();
        if (newPBs.Length > 0) // empty arrays are returned on e.g., http error
            m_records = newPBs;
#if DEPENDENCY_MLFEEDRACEDATA
        if (m_records.Length > 0) {
            auto raceData = MLFeed::GetRaceData();
            bool foundBetter = false;
            for (uint i = 0; i < m_records.Length; i++) {
                auto pbTime = m_records[i];
                auto player = raceData.GetPlayer(pbTime.name);
                if (player is null) continue;
                if (player.bestTime < 1) continue;
                if (player.bestTime < int(pbTime.time) || pbTime.time < 1) {
                    pbTime.time = player.bestTime;
                    pbTime.recordTs = Time::Stamp;
                    pbTime.replayUrl = "";
                    pbTime.UpdateCachedStrings();
                    foundBetter = true;
                }
            }

            // found a better time, so update PBs order
            if (foundBetter) {
                m_records.SortAsc();
            }
        }
#endif
    }

    string GetLocalPlayerWSID() {
        try {
            return GetApp().Network.ClientManiaAppPlayground.LocalUser.WebServicesUserId;
        } catch {
            return "";
        }
    }

    array<PBTime@> GetPlayersPBs() {
        auto mapg = cast<CTrackMania>(GetApp()).Network.ClientManiaAppPlayground;
        if (mapg is null) return {};
        auto scoreMgr = mapg.ScoreMgr;
        auto userMgr = mapg.UserMgr;
        if (scoreMgr is null || userMgr is null) return {};
        auto players = GetPlayersInServer();
        if (players.Length == 0) return {};
        auto playerWSIDs = MwFastBuffer<wstring>();
        dictionary wsidToPlayer;
        for (uint i = 0; i < players.Length; i++) {
            playerWSIDs.Add(players[i].User.WebServicesUserId);
            @wsidToPlayer[players[i].User.WebServicesUserId] = players[i];
        }

        m_CurrentlyLoadingRecords = true;
        auto rl = scoreMgr.Map_GetPlayerListRecordList(userMgr.Users[0].Id, playerWSIDs, GetApp().RootMap.MapInfo.MapUid, "PersonalBest", "", "", "");
        while (rl.IsProcessing) yield();
        m_CurrentlyLoadingRecords = false;

        if (rl.HasFailed || !rl.HasSucceeded) {
            warn("Requesting records failed. Type,Code,Desc: " + rl.ErrorType + ", " + rl.ErrorCode + ", " + rl.ErrorDescription);
            return {};
        }

        /* note:
            - usually we expect `rl.MapRecordList.Length != players.Length`
            - `players[i].User.WebServicesUserId != rl.MapRecordList[i].WebServicesUserId`
        so we use a dictionary to look up the players (wsidToPlayer we set up earlier)
        */

        string localWSID = GetLocalPlayerWSID();

        array<PBTime@> ret;
        for (uint i = 0; i < rl.MapRecordList.Length; i++) {
            auto rec = rl.MapRecordList[i];
            auto _p = cast<CSmPlayer>(wsidToPlayer[rec.WebServicesUserId]);
            if (_p is null) {
                warn("Failed to lookup player from temp dict");
                continue;
            }
            ret.InsertLast(PBTime(_p, rec, rec.WebServicesUserId == localWSID));
            // remove the player so we can quickly get all players in server that don't have records
            wsidToPlayer.Delete(rec.WebServicesUserId);
        }
        // get pbs for players without pbs
        auto playersWOutRecs = wsidToPlayer.GetKeys();
        for (uint i = 0; i < playersWOutRecs.Length; i++) {
            auto wsid = playersWOutRecs[i];
            auto player = cast<CSmPlayer>(wsidToPlayer[wsid]);
            try {
                // sometimes we get a null pointer exception here on player.User.WebServicesUserId
                ret.InsertLast(PBTime(player, null));
            } catch {
                Log::Warn("Got exception updating records. Exception: " + getExceptionInfo());
            }
        }
        ret.SortAsc();
        return ret;
    }

    array<CSmPlayer@>@ GetPlayersInServer() {
        auto cp = cast<CTrackMania>(GetApp()).CurrentPlayground;
        if (cp is null) return {};
        array<CSmPlayer@> ret;
        for (uint i = 0; i < cp.Players.Length; i++) {
            auto player = cast<CSmPlayer>(cp.Players[i]);
            if (player !is null) ret.InsertLast(player);
        }
        return ret;
    }

    void UpdateRecordsLoop() {
        while (RMC::IsRunning) {
            sleep(500);
            UpdateRecords();
        }
    }

}