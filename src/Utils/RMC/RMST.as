class RMST : RMS
{
#if TMNEXT
    string LobbyMapUID = "";
    NadeoServices::ClubRoom@ RMSTRoom;
    MX::MapInfo@ currentMap;
    MX::MapInfo@ nextMap;
    array<PBTime@> m_mapPersonalBests;
    array<RMSTPlayerScore@> m_playerScores;
    bool m_CurrentlyLoadingRecords = false;
    PBTime@ playerGotGoalActualMap;
    uint RMSTTimerMapChange = 0;
    bool isSwitchingMap = false;
    bool pressedStopButton = false;
    bool isFetchingNextMap = false;
    array<string> seenMaps;
    int SurvivedTimeStart = -1;
    int SurvivedTime = -1;

    string GetModeName() override { return "Random Map Survival Together";}

    void DevButtons() override {}

    void Render() override
    {
        if (UI::IsOverlayShown() || (!UI::IsOverlayShown() && PluginSettings::RMC_AlwaysShowBtns)) {
            if (UI::RedButton(Icons::Times + " Stop RMST"))
            {
                pressedStopButton = true;
                RMC::IsRunning = false;
                RMC::ShowTimer = false;
                RMC::StartTime = -1;
                RMC::EndTime = -1;
                @nextMap = null;
                @MX::preloadedMap = null;
#if DEPENDENCY_BETTERCHAT
                BetterChat::SendChatMessage(Icons::Users + " Random Map Survival Together stopped");
                startnew(CoroutineFunc(BetterChatSendLeaderboard));
#endif
                startnew(CoroutineFunc(ResetToLobbyMap));
            }

            RenderCustomSearchWarning();
            UI::Separator();
        }

        RenderTimer();
        if (IS_DEV_MODE) UI::Text(RMC::FormatTimer(RMC::StartTime - SurvivedTimeStart));
        UI::Separator();
        RenderGoalMedal();
        UI::HPadding(25);
        RenderBelowGoalMedal();
        RenderMVPPlayer();

        if (PluginSettings::RMC_DisplayCurrentMap)
        {
            RenderCurrentMap();
        }

        if (RMC::IsRunning && (UI::IsOverlayShown() || (!UI::IsOverlayShown() && PluginSettings::RMC_AlwaysShowBtns))) {
            UI::Separator();
            RenderPlayingButtons();
            UI::Separator();
            DrawPlayerProgress();
        }
    }

    void RenderTimer() override
    {
        UI::PushFont(Fonts::TimerFont);
        if (RMC::IsRunning || RMC::EndTime > 0 || RMC::StartTime > 0) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));
            else UI::Text(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));

            SurvivedTime = RMC::StartTime - SurvivedTimeStart;
            if (SurvivedTime > 0 && PluginSettings::RMC_SurvivalShowSurvivedTime) {
                UI::PopFont();
                UI::Dummy(vec2(0, 8));
                UI::PushFont(Fonts::HeaderSub);
                UI::Text(RMC::FormatTimer(SurvivedTime));
                UI::SetPreviousTooltip("Total time survived");
            } else {
                UI::Dummy(vec2(0, 8));
            }
            if (PluginSettings::RMC_DisplayMapTimeSpent) {
                if(SurvivedTime > 0 && PluginSettings::RMC_SurvivalShowSurvivedTime) {
                    UI::SameLine();
                }
                UI::PushFont(Fonts::HeaderSub);
                UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
                UI::SetPreviousTooltip("Time spent on this map");
                UI::PopFont();
            }
        } else {
            UI::TextDisabled(RMC::FormatTimer(TimeLimit()));
            UI::Dummy(vec2(0, 8));
        }

        UI::PopFont();
    }

    void StartRMST()
    {
        m_mapPersonalBests = {};
        m_playerScores = {};
        if (!seenMaps.IsEmpty()) seenMaps.RemoveRange(0, seenMaps.Length);
        RMC::GoalMedalCount = 0;
        Skips = 0;
        RMC::ShowTimer = true;
        RMC::ClickedOnSkip = false;
        pressedStopButton = false;
        Log::Trace("RMST: Getting lobby map UID from the room...");
        MXNadeoServicesGlobal::CheckNadeoRoomAsync();
        yield();
        @RMSTRoom = MXNadeoServicesGlobal::foundRoom;
        LobbyMapUID = RMSTRoom.room.currentMapUid;
        Log::Trace("RMST: Lobby map UID: " + LobbyMapUID);
#if DEPENDENCY_BETTERCHAT
        BetterChat::SendChatMessage(Icons::Users + " Starting Random Map Survival Together. Have Fun!");
        sleep(200);
        BetterChat::SendChatMessage(Icons::Users + " Goal medal: " + tostring(PluginSettings::RMC_GoalMedal));
#endif
        SetupMapStart();
    }

    void SetupMapStart() {
        RMC::IsStarting = true;
        isSwitchingMap = true;
        // Fetch a map
        Log::Trace("RMST: Fetching a random map...");
        Json::Value res;
        try {
            res = API::GetAsync(MX::CreateQueryURL())["Results"][0];
        } catch {
            Log::Error("ManiaExchange API returned an error, retrying...", true);
            SetupMapStart();
            return;
        }
        @currentMap = MX::MapInfo(res);
        Log::Trace("RMST: Random map: " + currentMap.Name + " (" + currentMap.MapId + ")");
        seenMaps.InsertLast(currentMap.MapUid);
        UI::ShowNotification(Icons::InfoCircle + " RMST - Information on map switching", "Nadeo prevent sometimes when switching map too often and will not change map.\nIf after 10 seconds the podium screen is not shown, you can start a vote to change to next map in the game pause menu.", Text::ParseHexColor("#420399"));

        if (!MXNadeoServicesGlobal::CheckIfMapExistsAsync(currentMap.MapUid)) {
            Log::Trace("RMST: Map is not on NadeoServices, retrying...");
            SetupMapStart();
            return;
        }

        DataManager::SaveMapToRecentlyPlayed(currentMap);
        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMSTRoom, currentMap.MapUid);
        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMSTRoom, TimeLimit() / 1000);
        while (GetApp().CurrentPlayground is null) yield();
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
        while (GamePlayground.GameTerminals.Length < 0) yield();
        while (GamePlayground.GameTerminals[0] is null) yield();
        while (GamePlayground.GameTerminals[0].ControlledPlayer is null) yield();
        CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].ControlledPlayer);
        while (player.ScriptAPI is null) yield();
        CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
        while (playerScriptAPI.Post == 0) yield();
        RMC::StartTime = Time::Now;
        RMC::EndTime = RMC::StartTime + TimeLimit();
        SurvivedTimeStart = Time::Now;
        RMC::IsPaused = false;
        RMC::GotGoalMedalOnCurrentMap = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(UpdateRecordsLoop));
        RMC::TimeSpawnedMap = Time::Now;
        isSwitchingMap = false;
        RMC::IsStarting = false;
        startnew(CoroutineFunc(RMSTFetchNextMap));
    }

    void RMSTFetchNextMap() {
        isFetchingNextMap = true;
        // Fetch a map
        Log::Trace("RMST: Fetching a random map...");
        Json::Value res;
        try {
            res = API::GetAsync(MX::CreateQueryURL())["Results"][0];
        } catch {
            Log::Error("ManiaExchange API returned an error, retrying...");
            RMSTFetchNextMap();
            return;
        }
        @nextMap = MX::MapInfo(res);
        Log::Trace("RMST: Next Random map: " + nextMap.Name + " (" + nextMap.MapId + ")");

        if (PluginSettings::SkipSeenMaps) {
            if (seenMaps.Find(nextMap.MapUid) != -1) {
                Log::Trace("Map has been played already, retrying...");
                RMSTFetchNextMap();
                return;
            }

            seenMaps.InsertLast(nextMap.MapUid);
        }

        if (!MXNadeoServicesGlobal::CheckIfMapExistsAsync(nextMap.MapUid)) {
            Log::Trace("RMST: Next map is not on NadeoServices, retrying...");
            @nextMap = null;
            RMSTFetchNextMap();
            return;
        }

        isFetchingNextMap = false;
    }

    void RMSTSwitchMap() {
        m_playerScores.SortDesc();
        isSwitchingMap = true;
        m_mapPersonalBests = {};
        RMSTTimerMapChange = RMC::EndTime - RMC::StartTime;
        RMC::IsPaused = true;
        RMC::GotGoalMedalOnCurrentMap = false;
        if (nextMap is null && !isFetchingNextMap) RMSTFetchNextMap();
        while (isFetchingNextMap) yield();
        @currentMap = nextMap;
        @nextMap = null;
        Log::Trace("RMST: Random map: " + currentMap.Name + " (" + currentMap.MapId + ")");
        UI::ShowNotification(Icons::InfoCircle + " RMST - Information on map switching", "Nadeo prevent sometimes when switching map too often and will not change map.\nIf after 10 seconds the podium screen is not shown, you can start a vote to change to next map in the game pause menu.", Text::ParseHexColor("#420399"));

        DataManager::SaveMapToRecentlyPlayed(currentMap);
        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMSTRoom, currentMap.MapUid);
        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMSTRoom, RMSTTimerMapChange / 1000);
        while (GetApp().CurrentPlayground is null) yield();
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
        while (GamePlayground.GameTerminals.Length < 0) yield();
        while (GamePlayground.GameTerminals[0] is null) yield();
        while (GamePlayground.GameTerminals[0].ControlledPlayer is null) yield();
        CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].ControlledPlayer);
        while (player.ScriptAPI is null) yield();
        m_playerScores.SortDesc();
#if DEPENDENCY_BETTERCHAT
        if (m_playerScores.Length > 0) {
            RMSTPlayerScore@ p = m_playerScores[0];
            string currentStatChat = Icons::Users + " RMST Team Progress: " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals - " + Skips + " skips\n";
            currentStatChat += "Current MVP: " + p.name + ": " + p.goals + " " + tostring(PluginSettings::RMC_GoalMedal) + " - " + p.skips + " skips";
            BetterChat::SendChatMessage(currentStatChat);
        }
#endif
        CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
        while (playerScriptAPI.Post == 0) yield();
        RMC::EndTime = RMC::EndTime + (Time::Now - RMC::StartTime);
        RMC::TimeSpawnedMap = Time::Now;
        RMC::IsPaused = false;
        isSwitchingMap = false;
        RMC::ClickedOnSkip = false;
        startnew(CoroutineFunc(RMSTFetchNextMap));
    }

    void ResetToLobbyMap() {
        if (LobbyMapUID != "") {
            UI::ShowNotification("Returning to lobby map", "Please wait...", Text::ParseHexColor("#993f03"));
#if DEPENDENCY_BETTERCHAT
            sleep(200);
            BetterChat::SendChatMessage(Icons::Users + " Returning to lobby map...");
#endif
            MXNadeoServicesGlobal::SetMapToClubRoomAsync(RMSTRoom, LobbyMapUID);
            if (pressedStopButton) MXNadeoServicesGlobal::ClubRoomSwitchMapAsync(RMSTRoom);
            while (!TM::IsMapCorrect(LobbyMapUID)) sleep(1000);
            pressedStopButton = false;
        }
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMSTRoom, 0);
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
                        SurvivedTime = RMC::StartTime - SurvivedTimeStart;
                        PendingTimerLoop();

                        if (!pressedStopButton && (RMC::StartTime > RMC::EndTime || !RMC::IsRunning || RMC::EndTime <= 0)) {
                            RMC::StartTime = -1;
                            RMC::EndTime = -1;
                            RMC::IsRunning = false;
                            RMC::ShowTimer = false;
                            GameEndNotification();
                            @nextMap = null;
                            @MX::preloadedMap = null;
                            m_playerScores.SortDesc();
#if DEPENDENCY_BETTERCHAT
                            BetterChat::SendChatMessage(Icons::Users + " Random Map Survival Together ended, thanks for playing!");
                            sleep(200);
                            BetterChatSendLeaderboard();
#endif
                            ResetToLobbyMap();
                        }
                    }
                }
            }
        }
    }

    void PendingTimerLoop() override
    {
        // Cap timer max
        if ((RMC::EndTime - RMC::StartTime) > (PluginSettings::RMC_SurvivalMaxTime-Skips)*60*1000) {
            RMC::EndTime = RMC::StartTime + (PluginSettings::RMC_SurvivalMaxTime-Skips)*60*1000;
        }
    }

    void GotGoalMedalNotification() override
    {
        Log::Trace("RMST: Got the "+ tostring(PluginSettings::RMC_GoalMedal) + " medal!");
        // In survival mode, add 3 minutes when getting a goal medal
        RMC::EndTime += (3*60*1000);
        
        // Find the player who got the medal for the notification
        string playerName = "Someone";
        if (playerGotGoalActualMap !is null) {
            playerName = playerGotGoalActualMap.name;
        }
        
        UI::ShowNotification("\\$071" + Icons::Trophy + " Team Goal Medal!", playerName + " got the " + tostring(PluginSettings::RMC_GoalMedal) + " medal! +3 minutes added to team timer!");
        
        if (PluginSettings::RMC_AutoSwitch) {
            startnew(CoroutineFunc(RMSTSwitchMap));
        }
    }

    void SkipButtons() override
    {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::ClickedOnSkip);
        if (UI::Button(Icons::PlayCircleO + " Skip")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Skips += 1;
            // In survival mode, lose 1 minute when skipping
            RMC::EndTime -= (1*60*1000);
            Log::Trace("RMST: Skipping map");
            UI::ShowNotification("Please wait...", "-1 minute for skip");
            startnew(CoroutineFunc(RMSTSwitchMap));
        }
        if (UI::OrangeButton(Icons::PlayCircleO + " Skip Broken Map")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            RMC::IsPaused = true;
            Renderables::Add(BrokenMapSkipWarnModalDialog());
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");
        UI::EndDisabled();
    }

    void NextMapButton() override
    {
        if(UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMST: Next map");
            UI::ShowNotification("Please wait...");
            RMC::EndTime += (3*60*1000);
            startnew(CoroutineFunc(RMSTSwitchMap));
        }
    }

    void GameEndNotification() override
    {
        if (RMC::selectedGameMode == RMC::GameMode::SurvivalTogether) {
#if TMNEXT
            RMCLeaderAPI::postRMS(RMC::GoalMedalCount, Skips, SurvivedTime, PluginSettings::RMC_GoalMedal);
#endif
            UI::ShowNotification(
                "\\$0f0Random Map Survival Together ended!",
                "You survived with a time of " + RMC::FormatTimer(SurvivedTime) +
                ".\nYou got "+ RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_GoalMedal) +
                " medals and " + Skips + " skips."
            );
        }
    }

    void UpdateRecordsLoop() {
        while (RMC::IsRunning) {
            if (!m_CurrentlyLoadingRecords && !isSwitchingMap) {
                m_CurrentlyLoadingRecords = true;
                startnew(CoroutineFunc(UpdateRecords));
            }
            sleep(1000);
        }
    }

    void UpdateRecords() {
        if (currentMap is null) {
            m_CurrentlyLoadingRecords = false;
            return;
        }

        array<PBTime@> records = MXNadeoServicesGlobal::GetMapRecords(currentMap.MapUid);
        if (records.Length == 0) {
            m_CurrentlyLoadingRecords = false;
            return;
        }

        m_mapPersonalBests = records;

        for (uint i = 0; i < m_mapPersonalBests.Length; i++) {
            PBTime@ record = m_mapPersonalBests[i];
            if (record is null) continue;

            bool foundPlayer = false;
            for (uint j = 0; j < m_playerScores.Length; j++) {
                if (m_playerScores[j].wsid == record.wsid) {
                    foundPlayer = true;
                    break;
                }
            }

            if (!foundPlayer) {
                m_playerScores.InsertLast(RMSTPlayerScore(record));
            }

            // Collaborative mode: Any player getting the goal medal benefits the entire team
            if (record.medal >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal) && !RMC::GotGoalMedalOnCurrentMap) {
                @playerGotGoalActualMap = record;
                RMC::GotGoalMedalOnCurrentMap = true;
                RMC::GoalMedalCount++;
                
                // Update the specific player's goal count for leaderboard tracking
                for (uint j = 0; j < m_playerScores.Length; j++) {
                    if (m_playerScores[j].wsid == record.wsid) {
                        m_playerScores[j].AddGoal();
                        break;
                    }
                }
                
                GotGoalMedalNotification();
            }
        }

        m_CurrentlyLoadingRecords = false;
    }

    void RenderMVPPlayer() {
        if (m_playerScores.Length > 0) {
            m_playerScores.SortDesc();
            RMSTPlayerScore@ mvp = m_playerScores[0];
            UI::Text("MVP: " + mvp.name + " (" + mvp.goals + " goals, " + mvp.skips + " skips)");
        }
    }

    void DrawPlayerProgress() {
        if (m_playerScores.Length == 0) return;

        UI::Text("Team Member Contributions:");
        m_playerScores.SortDesc();
        
        for (uint i = 0; i < Math::Min(m_playerScores.Length, 10); i++) {
            RMSTPlayerScore@ player = m_playerScores[i];
            UI::Text((i+1) + ". " + player.name + ": " + player.goals + " goals, " + player.skips + " skips");
        }
    }

    void RenderScores() {
        UI::Text("Team Progress: " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals, " + Skips + " skips");
        
        if (m_playerScores.Length == 0) return;
        
        UI::Text("Individual Contributions:");
        m_playerScores.SortDesc();
        
        for (uint i = 0; i < Math::Min(m_playerScores.Length, 5); i++) {
            RMSTPlayerScore@ player = m_playerScores[i];
            UI::Text((i+1) + ". " + player.name + ": " + player.goals + " goals, " + player.skips + " skips");
        }
    }

    void BetterChatSendLeaderboard() {
#if DEPENDENCY_BETTERCHAT
        if (m_playerScores.Length == 0) return;
        
        m_playerScores.SortDesc();
        string leaderboard = Icons::Users + " RMST Team Results:\n";
        leaderboard += "Team Achievement: " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals, " + Skips + " skips\n";
        leaderboard += "Individual Contributions:\n";
        
        for (uint i = 0; i < Math::Min(m_playerScores.Length, 5); i++) {
            RMSTPlayerScore@ player = m_playerScores[i];
            leaderboard += (i+1) + ". " + player.name + ": " + player.goals + " goals, " + player.skips + " skips\n";
        }
        
        BetterChat::SendChatMessage(leaderboard);
#endif
    }

    void RenderCustomSearchWarning() {
        // Implementation for custom search warning if needed
        // For now, empty implementation
    }

    void RenderCurrentMap() {
        if (currentMap !is null) {
            UI::Text("Current Map: " + currentMap.Name);
            UI::Text("Author: " + currentMap.AuthorName);
        }
    }

    void RenderPlayingButtons() {
        SkipButtons();
        if (!PluginSettings::RMC_AutoSwitch) {
            NextMapButton();
        }
    }

#else
    string GetModeName() override { return "Random Map Survival Together (NOT SUPPORTED ON THIS GAME)";}
#endif
}

class RMSTPlayerScore {
    string name;
    string wsid;
    int goals;
    int skips;

    RMSTPlayerScore(PBTime@ _player) {
        wsid = _player.wsid;
        name = _player.name;
        goals = 0;
        skips = 0;
    }

    int AddGoal() {
        goals = goals + 1;
        return goals;
    }

    int AddSkip() {
        skips = skips + 1;
        return skips;
    }

    int opCmp(RMSTPlayerScore@ other) const {
        if (goals < other.goals) return -1;
        if (goals == other.goals) {
            if (skips > other.skips) return -1;
            if (skips == other.skips) return 0;
            return 1;
        }
        return 1;
    }
} 