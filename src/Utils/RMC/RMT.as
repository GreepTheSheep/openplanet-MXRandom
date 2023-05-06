class RMT : RMC
{
    string LobbyMapUID = "";
    NadeoServices::ClubRoom@ RMTRoom;
    MX::MapInfo@ currentMap;
    MX::MapInfo@ nextMap;
    uint lastPbUpdate = 0;
    array<PBTime@> m_mapPersonalBests;
    array<RMTPlayerScore@> m_playerScores;
    bool m_CurrentlyLoadingRecords = false;
    PBTime@ playerGotGoalActualMap;
    PBTime@ playerGotBelowGoalActualMap;
    uint RMTTimerMapChange = 0;
    bool isSwitchingMap = false;
    bool pressedStopButton = false;

    string GetModeName() override { return "Random Map Together";}

    void Render() override
    {
        if (UI::IsOverlayShown() || (!UI::IsOverlayShown() && PluginSettings::RMC_AlwaysShowBtns)) {
            if (UI::RedButton(Icons::Times + " Stop RMT"))
            {
                pressedStopButton = true;
                RMC::IsRunning = false;
                RMC::ShowTimer = false;
                RMC::StartTime = -1;
                RMC::EndTime = -1;
#if DEPENDENCY_BETTERCHAT
                BetterChat::SendChatMessage(Icons::Users + " Random Map Together stopped");
                startnew(CoroutineFunc(BetterChatSendLeaderboard));
#endif
                startnew(CoroutineFunc(ResetToLobbyMap));
            }

            UI::Separator();
        }

        RenderTimer();
        UI::Separator();
        vec2 pos_orig = UI::GetCursorPos();
        RenderGoalMedal();
        UI::SetCursorPos(vec2(pos_orig.x+100, pos_orig.y));
        RenderBelowGoalMedal();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+60));
        RenderMVPPlayer();

        if (PluginSettings::RMC_DisplayCurrentMap)
        {
            RenderCurrentMap();
        }

        if (RMC::IsRunning && (UI::IsOverlayShown() || (!UI::IsOverlayShown() && PluginSettings::RMC_AlwaysShowBtns))) {
            UI::Separator();
            RenderPlayingButtons();
        }
    }

    void StartRMT()
    {
        m_mapPersonalBests = {};
        m_playerScores = {};
        RMC::GoalMedalCount = 0;
        BelowMedalCount = 0;
        RMC::ShowTimer = true;
        pressedStopButton = false;
        Log::Trace("RMT: Getting lobby map UID from the room...");
        MXNadeoServicesGlobal::CheckNadeoRoomAsync();
        yield();
        @RMTRoom = MXNadeoServicesGlobal::foundRoom;
        LobbyMapUID = RMTRoom.room.currentMapUid;
        Log::Trace("RMT: Lobby map UID: " + LobbyMapUID);
#if DEPENDENCY_BETTERCHAT
        BetterChat::SendChatMessage(Icons::Users + " Starting Random Map Together. Have Fun!");
        sleep(200);
        BetterChat::SendChatMessage(Icons::Users + " Goal medal: " + tostring(PluginSettings::RMC_GoalMedal));
#endif
        SetupMapStart();
    }

    void SetupMapStart() {
        isSwitchingMap = true;
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
        while (!TM::IsMapCorrect(currentMap.TrackUID)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, TimeLimit() / 1000);
        while (GetApp().CurrentPlayground is null) yield();
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
        while (GamePlayground.GameTerminals.Length < 0) yield();
        while (GamePlayground.GameTerminals[0] is null) yield();
        while (GamePlayground.GameTerminals[0].GUIPlayer is null) yield();
        CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].GUIPlayer);
        while (player.ScriptAPI is null) yield();
        CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
        while (playerScriptAPI.Post == 0) yield();
        RMC::StartTime = Time::Now;
        RMC::EndTime = RMC::StartTime + TimeLimit();
        RMC::IsPaused = false;
        RMC::GotGoalMedalOnCurrentMap = false;
        RMC::GotBelowMedalOnCurrentMap = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(UpdateRecordsLoop));
        RMC::TimeSpawnedMap = Time::Now;
        isSwitchingMap = false;
        startnew(CoroutineFunc(RMTFetchNextMap));
    }

    void RMTFetchNextMap() {
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
        @nextMap = MX::MapInfo(res);
        Log::Trace("RMT: Next Random map: " + nextMap.Name + " (" + nextMap.TrackID + ")");
        if (!MXNadeoServicesGlobal::CheckIfMapExistsAsync(nextMap.TrackUID)) {
            Log::Trace("RMT: Next map is not on NadeoServices, retrying...");
            @nextMap = null;
            RMTSwitchMap();
            return;
        }
    }

    void RMTSwitchMap() {
        m_playerScores.SortDesc();
        isSwitchingMap = true;
        m_mapPersonalBests = {};
        RMTTimerMapChange = RMC::EndTime - RMC::StartTime;
        RMC::IsPaused = true;
        RMC::GotGoalMedalOnCurrentMap = false;
        RMC::GotBelowMedalOnCurrentMap = false;
        if (nextMap is null) {
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
                RMTSwitchMap();
                return;
            }
        } else {
            @currentMap = nextMap;
            @nextMap = null;
            Log::Trace("RMT: Random map: " + currentMap.Name + " (" + currentMap.TrackID + ")");
        }

        MXNadeoServicesGlobal::SetMapToClubRoomAsync(RMTRoom, currentMap.TrackUID);
        MXNadeoServicesGlobal::ClubRoomSwitchMapAsync(RMTRoom);
        while (!TM::IsMapCorrect(currentMap.TrackUID)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, RMTTimerMapChange / 1000);
        while (GetApp().CurrentPlayground is null) yield();
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
        while (GamePlayground.GameTerminals.Length < 0) yield();
        while (GamePlayground.GameTerminals[0] is null) yield();
        while (GamePlayground.GameTerminals[0].GUIPlayer is null) yield();
        CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].GUIPlayer);
        while (player.ScriptAPI is null) yield();
        m_playerScores.SortDesc();
#if DEPENDENCY_BETTERCHAT
        if (m_playerScores.Length > 0) {
            RMTPlayerScore@ p = m_playerScores[0];
            string currentStatChat = Icons::Users + " RMT Leaderboard:$z " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals " + (PluginSettings::RMC_GoalMedal != RMC::Medals[0] ? " - " + BelowMedalCount + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medals" : "") + "\n";
            currentStatChat += "Current MVP: " + p.name + ": " + p.goals + " " + tostring(PluginSettings::RMC_GoalMedal) +
                (PluginSettings::RMC_GoalMedal != RMC::Medals[0] ?
                    " - " + p.belowGoals + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]
                : "");
            BetterChat::SendChatMessage(currentStatChat);
        }
#endif
        CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
        while (playerScriptAPI.Post == 0) yield();
        RMC::EndTime = RMC::EndTime + (Time::Now - RMC::StartTime);
        RMC::TimeSpawnedMap = Time::Now;
        RMC::IsPaused = false;
        isSwitchingMap = false;
        startnew(CoroutineFunc(RMTFetchNextMap));
    }

    void ResetToLobbyMap() {
        if (LobbyMapUID != "") {
            UI::ShowNotification("Returning to lobby map", "Please wait...", Text::ParseHexColor("#993f03"));
#if DEPENDENCY_BETTERCHAT
            BetterChat::SendChatMessage(Icons::Users + " Returning to lobby map...");
#endif
            MXNadeoServicesGlobal::SetMapToClubRoomAsync(RMTRoom, LobbyMapUID);
            if (pressedStopButton) MXNadeoServicesGlobal::ClubRoomSwitchMapAsync(RMTRoom);
            while (!TM::IsMapCorrect(LobbyMapUID)) sleep(1000);
            pressedStopButton = false;
        }
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, 0);
    }

    void TimerYield() override
    {
        while (RMC::IsRunning){
            yield();
            if (RMC::IsPaused) {
                RMC::StartTime = Time::Now - (Time::Now - RMC::StartTime);
                RMC::EndTime = Time::Now - (Time::Now - RMC::EndTime);
            } else {
                CGameCtnChallenge@ currentMapChallenge = cast<CGameCtnChallenge>(GetApp().RootMap);
                if (currentMapChallenge !is null) {
                    CGameCtnChallengeInfo@ currentMapInfo = currentMapChallenge.MapInfo;
                    if (currentMapInfo !is null) {
                        RMC::StartTime = Time::Now;
                        RMC::TimeSpentMap = Time::Now - RMC::TimeSpawnedMap;
                        PendingTimerLoop();

                        if (!pressedStopButton && (RMC::StartTime > RMC::EndTime || !RMC::IsRunning || RMC::EndTime <= 0)) {
                            RMC::StartTime = -1;
                            RMC::EndTime = -1;
                            RMC::IsRunning = false;
                            RMC::ShowTimer = false;
                            GameEndNotification();
                            m_playerScores.SortDesc();
#if DEPENDENCY_BETTERCHAT
                            BetterChat::SendChatMessage(Icons::Users + " Random Map Together ended, thanks for playing!");
                            sleep(200);
                            BetterChatSendLeaderboard();
#endif
                            ResetToLobbyMap();
                        }
                    }
                }

                if (isObjectiveCompleted() && !RMC::GotGoalMedalOnCurrentMap) {
                    Log::Log(playerGotGoalActualMap.name + " got goal medal with a time of " + playerGotGoalActualMap.time);
                    UI::ShowNotification(Icons::Trophy + " " + playerGotGoalActualMap.name + " got "+tostring(PluginSettings::RMC_GoalMedal)+" medal with a time of " + playerGotGoalActualMap.timeStr, "Switching map...", Text::ParseHexColor("#01660f"));
                    RMC::GoalMedalCount += 1;
                    RMC::GotGoalMedalOnCurrentMap = true;
                    RMTPlayerScore@ playerScored = findOrCreatePlayerScore(playerGotGoalActualMap);
                    playerScored.AddGoal();
                    m_playerScores.SortDesc();

#if DEPENDENCY_BETTERCHAT
                    BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotGoalActualMap.name + " got "+tostring(PluginSettings::RMC_GoalMedal)+" medal with a time of " + playerGotGoalActualMap.timeStr);
                    sleep(200);
                    BetterChat::SendChatMessage(Icons::Users + " Switching map...");
#endif

                    RMTSwitchMap();
                }
                if (isBelowObjectiveCompleted() && !RMC::GotBelowMedalOnCurrentMap && PluginSettings::RMC_GoalMedal != RMC::Medals[0]) {
                    Log::Log(playerGotBelowGoalActualMap.name + " got below goal medal with a time of " + playerGotBelowGoalActualMap.time);
                    UI::ShowNotification(Icons::Trophy + " " + playerGotBelowGoalActualMap.name + " got "+RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]+" medal with a time of " + playerGotBelowGoalActualMap.timeStr, "You can skip and take " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medal", Text::ParseHexColor("#4d3e0a"));
                    RMC::GotBelowMedalOnCurrentMap = true;
#if DEPENDENCY_BETTERCHAT
                    BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotBelowGoalActualMap.name + " got "+RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]+" medal with a time of " + playerGotBelowGoalActualMap.timeStr);
                    sleep(200);
                    BetterChat::SendChatMessage(Icons::Users + " You can skip and take " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medal");
#endif
                }
            }
        }
    }

    void RenderMVPPlayer() {
        if (m_playerScores.Length > 0) {
            RMTPlayerScore@ p = m_playerScores[0];
            UI::Text("MVP: " + p.name + " (" + p.goals + ")");
            if (UI::IsItemHovered()) {
                UI::BeginTooltip();
                RenderScores();
                UI::EndTooltip();
            }
        }
    }

    void BetterChatSendLeaderboard() {
#if DEPENDENCY_BETTERCHAT
        sleep(200);
        if (m_playerScores.Length > 0) {
            string currentStatsChat = Icons::Users + " RMT Leaderboard:$z " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals " + (PluginSettings::RMC_GoalMedal != RMC::Medals[0] ? " - " + BelowMedalCount + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medals" : "") + "\n\n";
            for (uint i = 0; i < m_playerScores.Length; i++) {
                RMTPlayerScore@ p = m_playerScores[i];
                currentStatsChat += tostring(i+1) + ". " + p.name + ": " + p.goals + " " + tostring(PluginSettings::RMC_GoalMedal) + (PluginSettings::RMC_GoalMedal != RMC::Medals[0] ? " - " + p.belowGoals + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] : "") + "\n";
            }
            BetterChat::SendChatMessage(currentStatsChat);
        }
#endif
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
                    if(PluginSettings::RMC_DisplayMapDate) {
                        UI::TextDisabled(IsoDateToDMY(currentMap.UpdatedAt));
                        UI::SameLine();
                    }
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

    void RenderPlayingButtons() override
    {
        CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
        if (currentMap !is null) {
            SkipButton();
            if (IS_DEV_MODE) {
                DevButtons();
            }
        }
    }

    void SkipButton() override
    {
        string BelowMedal = PluginSettings::RMC_GoalMedal;
        if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) BelowMedal = RMC::Medals[2];
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) BelowMedal = RMC::Medals[1];
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) BelowMedal = RMC::Medals[0];
        else BelowMedal = PluginSettings::RMC_GoalMedal;

        if(UI::Button(Icons::PlayCircleO + " Skip" + (RMC::GotBelowMedalOnCurrentMap ? " and take " + BelowMedal + " medal" : ""))) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            if (RMC::GotBelowMedalOnCurrentMap) {
                BelowMedalCount += 1;
                RMTPlayerScore@ playerScored = findOrCreatePlayerScore(playerGotBelowGoalActualMap);
                playerScored.AddBelowGoal();
            }
            MX::MapInfo@ CurrentMapFromJson = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            if (
#if TMNEXT
                PluginSettings::RMC_PrepatchTagsWarns &&
                RMC::config.isMapHasPrepatchMapTags(CurrentMapFromJson) &&
#endif
                !RMC::GotBelowMedalOnCurrentMap
            ) RMC::EndTime += RMC::TimeSpentMap;
#if DEPENDENCY_BETTERCHAT
            BetterChat::SendChatMessage(Icons::Users + " Skipping map...");
#endif
            startnew(CoroutineFunc(RMTSwitchMap));
        }
    }

    void RenderScores()
    {
        string BelowMedal = PluginSettings::RMC_GoalMedal;
        if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) BelowMedal = RMC::Medals[2];
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) BelowMedal = RMC::Medals[1];
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) BelowMedal = RMC::Medals[0];
        else BelowMedal = PluginSettings::RMC_GoalMedal;
        int tableCols = 3;
        if (PluginSettings::RMC_GoalMedal == RMC::Medals[0]) tableCols = 2;
        if (UI::BeginTable("RMTScores", tableCols)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn(PluginSettings::RMC_GoalMedal, UI::TableColumnFlags::WidthFixed, 40);
            UI::TableSetupColumn(BelowMedal, UI::TableColumnFlags::WidthFixed, 40);
            UI::TableHeadersRow();

            UI::ListClipper clipper(m_playerScores.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                {
                    UI::TableNextRow();
                    UI::PushID("RMTScore"+i);
                    RMTPlayerScore@ s = m_playerScores[i];
                    UI::TableSetColumnIndex(0);
                    UI::Text(s.name);
                    UI::TableSetColumnIndex(1);
                    UI::Text(tostring(s.goals));
                    if (PluginSettings::RMC_GoalMedal != RMC::Medals[0]) {
                        UI::TableSetColumnIndex(2);
                        UI::Text(tostring(s.belowGoals));
                    }
                    UI::PopID();
                }
            }
            UI::EndTable();
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


            if (m_mapPersonalBests.Length > 0) {
                for (uint r = 0; r < m_mapPersonalBests.Length; r++) {
                    if (m_mapPersonalBests[r].time <= 0) continue;
                    if (m_mapPersonalBests[r].time <= objectiveTime) {
                        @playerGotGoalActualMap = m_mapPersonalBests[r];
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


            if (m_mapPersonalBests.Length > 0) {
                for (uint r = 0; r < m_mapPersonalBests.Length; r++) {
                    if (m_mapPersonalBests[r].time <= 0) continue;
                    if (m_mapPersonalBests[r].time <= objectiveTime) {
                        @playerGotBelowGoalActualMap = m_mapPersonalBests[r];
                        return true;
                    }
                }
            }
        }
        return false;
    }

    void UpdateRecords() {
        lastPbUpdate = Time::Now;
        auto newPBs = GetPlayersPBsMLFeed();
        if (newPBs.Length > 0) // empty arrays are returned on e.g., http error
            m_mapPersonalBests = newPBs;
    }

    string GetLocalPlayerWSID() {
        try {
            return GetApp().Network.ClientManiaAppPlayground.LocalUser.WebServicesUserId;
        } catch {
            return "";
        }
    }

    array<PBTime@> GetPlayersPBsMLFeed() {
        array<PBTime@> ret;
#if DEPENDENCY_MLFEEDRACEDATA
        auto mapg = cast<CTrackMania>(GetApp()).Network.ClientManiaAppPlayground;
        if (mapg is null) return {};
        auto scoreMgr = mapg.ScoreMgr;
        auto userMgr = mapg.UserMgr;
        if (scoreMgr is null || userMgr is null) return {};
        auto raceData = MLFeed::GetRaceData_V2();
        auto players = GetPlayersInServer();
        if (players.Length == 0) return {};
        auto playerWSIDs = MwFastBuffer<wstring>();
        dictionary wsidToPlayer;
        for (uint i = 0; i < players.Length; i++) {
            auto SMPlayer = players[i];
            auto player = raceData.GetPlayer_V2(SMPlayer.User.Name);
            if (player is null) continue;
            if (player.bestTime < 1) continue;
            auto pbTime = PBTime(SMPlayer, null, SMPlayer.User.WebServicesUserId == GetLocalPlayerWSID());
            pbTime.time = player.bestTime;
            pbTime.recordTs = Time::Stamp;
            pbTime.replayUrl = "";
            pbTime.UpdateCachedStrings();
            ret.InsertLast(pbTime);
        }
        ret.SortAsc();
#endif
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
            if (!isSwitchingMap) UpdateRecords();
        }
    }

    RMTPlayerScore@ findOrCreatePlayerScore(PBTime@ _player) {
        for (uint i = 0; i < m_playerScores.Length; i++) {
            RMTPlayerScore@ playerScore = m_playerScores[i];
            if (playerScore.wsid == _player.wsid) return playerScore;
        }
        RMTPlayerScore@ newPlayerScore = RMTPlayerScore(_player);
        m_playerScores.InsertLast(newPlayerScore);
        return newPlayerScore;
    }

}

class RMTPlayerScore {
    string name;
    string club;
    string wsid;
    int goals;
    int belowGoals;

    RMTPlayerScore(PBTime@ _player) {
        wsid = _player.wsid; // rare null pointer exception here
        name = _player.name;
        club = _player.club;
    }

    int AddGoal() {
        goals = goals + 1;
        return goals;
    }

    int AddBelowGoal() {
        belowGoals = belowGoals + 1;
        return belowGoals;
    }

    int opCmp(RMTPlayerScore@ other) const {
        if (goals == 0) {
            return (other.goals == 0 ? 0 : 1); // one or both goals unset
        }
        if (other.goals == 0 || goals < other.goals) return -1;
        if (goals == other.goals) return 0;
        return 1;
    }
}