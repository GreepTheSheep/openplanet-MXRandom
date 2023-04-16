class RMT : RMC
{
    string LobbyMapUID = "";
    NadeoServices::ClubRoom@ RMTRoom;
    MX::MapInfo@ currentMap;

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
        CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].GUIPlayer);
        while (player is null){
            yield();
        }
        CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
        while (playerScriptAPI.Post == 0){
            yield();
        }
        StartTimer();
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
                GotGoalMedalNotification();
                RMC::GoalMedalCount += 1;
                RMC::GotGoalMedalOnCurrentMap = true;
            }
            if (
                isObjectiveCompleted() &&
                !RMC::GotGoalMedalOnCurrentMap &&
                PluginSettings::RMC_GoalMedal != RMC::Medals[0])
            {
                GotBelowGoalMedalNotification();
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
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
        for (uint player = 0; player < GamePlayground.GameTerminals.Length; player++)
        {
            CSmPlayer@ guiPlayer = cast<CSmPlayer>(GamePlayground.GameTerminals[0].GUIPlayer);
            if (guiPlayer is null) continue;
            CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(guiPlayer.ScriptAPI);
            if (playerScriptAPI.Score.PrevRaceTimes.Length > 0) {
                int lastTime = playerScriptAPI.Score.PrevRaceTimes[0];
                Log::Trace("Player #"+player+" - Last Time: " + lastTime);
            }
        }
        return false;
    }
}