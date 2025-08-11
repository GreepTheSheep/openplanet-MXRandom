class RMT : RMC
{
#if TMNEXT
    string LobbyMapUID = "";
    NadeoServices::ClubRoom@ RMTRoom;
    MX::MapInfo@ currentMap;
    MX::MapInfo@ nextMap;
    array<PBTime@> m_mapPersonalBests;
    array<RMTPlayerScore@> m_playerScores;
    bool m_CurrentlyLoadingRecords = false;
    PBTime@ playerGotGoal;
    PBTime@ playerGotBelowGoal;
    uint RMTTimerMapChange = 0;
    bool isSwitchingMap = false;
    bool pressedStopButton = false;
    bool isFetchingNextMap = false;
    array<string> seenMaps;

    string GetModeName() override { return "Random Map Together";}

    void DevButtons() override {}

    void Render() override
    {
        if (UI::IsOverlayShown() || PluginSettings::RMC_AlwaysShowBtns) {
            if (UI::RedButton(Icons::Times + " Stop RMT"))
            {
                pressedStopButton = true;
                RMC::IsRunning = false;
                RMC::ShowTimer = false;
                RMC::StartTime = -1;
                RMC::EndTime = -1;
                @nextMap = null;
                @MX::preloadedMap = null;
#if DEPENDENCY_BETTERCHAT
                BetterChat::SendChatMessage(Icons::Users + " Random Map Together stopped");
                startnew(CoroutineFunc(BetterChatSendLeaderboard));
#endif
                startnew(CoroutineFunc(ResetToLobbyMap));
            }

            RenderCustomSearchWarning();
            UI::Separator();
        }

        RenderTimer();
        if (IS_DEV_MODE) UI::Text(RMC::FormatTimer(RMC::StartTime - ModeStartTimestamp));
        UI::Separator();
        RenderGoalMedal();
        UI::HPadding(25);
        RenderBelowGoalMedal();
        RenderMVPPlayer();

       if (PluginSettings::RMC_DisplayPace) {
            try {
                float goalPace = ((TimeLimit() / 60 / 1000) * RMC::GoalMedalCount / ((RMC::StartTime - ModeStartTimestamp) / 60 / 100));
                UI::Text("Pace: " + goalPace);
            } catch {
                UI::Text("Pace: 0");
            }
        }

        if (PluginSettings::RMC_DisplayCurrentMap)
        {
            RenderCurrentMap();
        }

        if (RMC::IsRunning && (UI::IsOverlayShown() || PluginSettings::RMC_AlwaysShowBtns)) {
            UI::Separator();
            RenderPlayingButtons();
            UI::Separator();
            DrawPlayerProgress();
        }
    }

    void StartRMT()
    {
        m_mapPersonalBests = {};
        m_playerScores = {};
        if (!seenMaps.IsEmpty()) seenMaps.RemoveRange(0, seenMaps.Length);
        RMC::GoalMedalCount = 0;
        BelowMedalCount = 0;
        RMC::ShowTimer = true;
        RMC::ClickedOnSkip = false;
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
        RMC::IsStarting = true;
        isSwitchingMap = true;
        // Fetch a map
        Log::Trace("RMT: Fetching a random map...");
        Json::Value res;
        try {
            res = API::GetAsync(MX::CreateQueryURL())["Results"][0];
        } catch {
            Log::Error("ManiaExchange API returned an error, retrying...", true);
            SetupMapStart();
            return;
        }
        @currentMap = MX::MapInfo(res);
        Log::Trace("RMT: Random map: " + currentMap.Name + " (" + currentMap.MapId + ")");
        seenMaps.InsertLast(currentMap.MapUid);

        if (currentMap.OnlineMapId == "" && !MXNadeoServicesGlobal::CheckIfMapExistsAsync(currentMap.MapUid)) {
            Log::Trace("RMT: Map is not on NadeoServices, retrying...");
            SetupMapStart();
            return;
        }

        DataManager::SaveMapToRecentlyPlayed(currentMap);
        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMTRoom, currentMap.MapUid);
        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, TimeLimit() / 1000);
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
        RMC::IsPaused = false;
        RMC::GotGoalMedal = false;
        RMC::GotBelowMedal = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(UpdateRecordsLoop));
        RMC::TimeSpawnedMap = Time::Now;
        isSwitchingMap = false;
        RMC::IsStarting = false;
        startnew(CoroutineFunc(RMTFetchNextMap));
    }

    void RMTFetchNextMap() {
        isFetchingNextMap = true;
        // Fetch a map
        Log::Trace("RMT: Fetching a random map...");
        Json::Value res;
        try {
            res = API::GetAsync(MX::CreateQueryURL())["Results"][0];
        } catch {
            Log::Error("ManiaExchange API returned an error, retrying...");
            RMTFetchNextMap();
            return;
        }
        @nextMap = MX::MapInfo(res);
        Log::Trace("RMT: Next Random map: " + nextMap.Name + " (" + nextMap.MapId + ")");

        if (PluginSettings::SkipSeenMaps) {
            if (seenMaps.Find(nextMap.MapUid) != -1) {
                Log::Trace("Map has been played already, retrying...");
                RMTFetchNextMap();
                return;
            }

            seenMaps.InsertLast(nextMap.MapUid);
        }

        if (currentMap.OnlineMapId == "" && !MXNadeoServicesGlobal::CheckIfMapExistsAsync(nextMap.MapUid)) {
            Log::Trace("RMT: Next map is not on NadeoServices, retrying...");
            @nextMap = null;
            RMTFetchNextMap();
            return;
        }

        isFetchingNextMap = false;
    }

    void RMTSwitchMap() {
        m_playerScores.SortDesc();
        isSwitchingMap = true;
        m_mapPersonalBests = {};
        RMTTimerMapChange = RMC::EndTime - RMC::StartTime;
        RMC::IsPaused = true;
        RMC::GotGoalMedal = false;
        RMC::GotBelowMedal = false;
        if (nextMap is null && !isFetchingNextMap) RMTFetchNextMap();
        while (isFetchingNextMap) yield();
        @currentMap = nextMap;
        @nextMap = null;
        Log::Trace("RMT: Random map: " + currentMap.Name + " (" + currentMap.MapId + ")");

        if (RMC::TimeSpentMap < 15000) {
            // Only notify if the server has spent fewer than 15 secs on the map
            UI::ShowNotification(Icons::InfoCircle + " RMT - Information on map switching", "Map switch might be prevented by Nadeo if done too quickly.\nIf the podium screen is not shown after 10 seconds, you can start a vote to change to the next map in the game pause menu.", Text::ParseHexColor("#420399"));
        }

        DataManager::SaveMapToRecentlyPlayed(currentMap);
        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMTRoom, currentMap.MapUid);
        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, RMTTimerMapChange / 1000);
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
            RMTPlayerScore@ p = m_playerScores[0];
            string currentStatChat = Icons::Users + " RMT Leaderboard: " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals" + (PluginSettings::RMC_GoalMedal != RMC::Medals[0] ? " - " + BelowMedalCount + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medals" : "") + "\n";
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
        RMC::ClickedOnSkip = false;
        startnew(CoroutineFunc(RMTFetchNextMap));
    }

    void ResetToLobbyMap() {
        if (LobbyMapUID != "") {
            UI::ShowNotification("Returning to lobby map", "Please wait...", Text::ParseHexColor("#993f03"));
#if DEPENDENCY_BETTERCHAT
            sleep(200);
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
                if (TM::IsMapLoaded()) {
                    RMC::StartTime = Time::Now;
                    RMC::TimeSpentMap = Time::Now - RMC::TimeSpawnedMap;
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
                        BetterChat::SendChatMessage(Icons::Users + " Random Map Together ended, thanks for playing!");
                        sleep(200);
                        BetterChatSendLeaderboard();
#endif
                        ResetToLobbyMap();
                    }
                }

                if (!RMC::GotGoalMedal && isObjectiveCompleted()) {
                    Log::Log(playerGotGoal.name + " got the goal medal with a time of " + playerGotGoal.time);
                    UI::ShowNotification(Icons::Trophy + " " + playerGotGoal.name + " got the "+tostring(PluginSettings::RMC_GoalMedal)+" medal with a time of " + playerGotGoal.timeStr, "Switching map...", Text::ParseHexColor("#01660f"));
                    RMC::GoalMedalCount += 1;
                    RMC::GotGoalMedal = true;
                    RMTPlayerScore@ playerScored = GetPlayerScore(playerGotGoal);
                    playerScored.AddGoal();
                    m_playerScores.SortDesc();

#if DEPENDENCY_BETTERCHAT
                    BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotGoal.name + " got the "+tostring(PluginSettings::RMC_GoalMedal)+" medal with a time of " + playerGotGoal.timeStr);
                    sleep(200);
                    BetterChat::SendChatMessage(Icons::Users + " Switching map...");
#endif

                    RMTSwitchMap();
                }
                if (!RMC::GotBelowMedal && PluginSettings::RMC_GoalMedal != RMC::Medals[0] && isBelowObjectiveCompleted()) {
                    Log::Log(playerGotBelowGoal.name + " got the below goal medal with a time of " + playerGotBelowGoal.time);
                    UI::ShowNotification(Icons::Trophy + " " + playerGotBelowGoal.name + " got the "+RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]+" medal with a time of " + playerGotBelowGoal.timeStr, "You can skip and take " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medal", Text::ParseHexColor("#4d3e0a"));
                    RMC::GotBelowMedal = true;
#if DEPENDENCY_BETTERCHAT
                    BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotBelowGoal.name + " got the "+RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]+" medal with a time of " + playerGotBelowGoal.timeStr);
                    sleep(200);
                    BetterChat::SendChatMessage(Icons::Users + " You can skip and take the " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medal");
#endif
                }
            }
        }
    }

    void RenderMVPPlayer() {
        if (m_playerScores.Length > 0) {
            RMTPlayerScore@ p = m_playerScores[0];
            UI::Text("MVP: " + p.name + " (" + p.goals + ")");
            if (UI::BeginItemTooltip()) {
                RenderScores();
                UI::EndTooltip();
            }
        }
    }

    void BetterChatSendLeaderboard() {
#if DEPENDENCY_BETTERCHAT
        sleep(200);
        if (m_playerScores.Length > 0) {
            string currentStatsChat = Icons::Users + " RMT Leaderboard: " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals" + (PluginSettings::RMC_GoalMedal != RMC::Medals[0] ? " - " + BelowMedalCount + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medals" : "") + "\n\n";
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

        if (!isSwitchingMap) {
            if (TM::IsMapLoaded()) {
                UI::Separator();

                if (currentMap !is null) {
                    UI::Text(currentMap.Name);

                    if (PluginSettings::RMC_ShowAwards) {
                        UI::SameLine();
                        UI::Text("\\$db4" + Icons::Trophy + "\\$z " + currentMap.AwardCount);
                    }

                    if(PluginSettings::RMC_DisplayMapDate) {
                        UI::TextDisabled(IsoDateToDMY(currentMap.UpdatedAt));
                        UI::SameLine();
                    }

                    UI::TextDisabled("by " + currentMap.Username);

                    if (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.HasPrepatchTags(currentMap)) {
                        RMCConfigMapTag@ tag = RMC::config.GetPrepatchTag(currentMap);

                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z" + tag.title);
                        UI::SetPreviousTooltip(tag.reason + (IS_DEV_MODE ? ("\nExeBuild: " + currentMap.ExeBuild) : ""));
                    }

                    if (PluginSettings::RMC_EditedMedalsWarns && TM::HasEditedMedals()) {
                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z Edited Medals");
                        UI::SetPreviousTooltip("The map has medal times that differ from the default.\n\nYou can skip it if preferred.");
                    }

                    if (PluginSettings::RMC_TagsLength != 0) {
                        if (currentMap.Tags.IsEmpty()) {
                            UI::TextDisabled("No tags");
                        } else {
                            uint tagsRender = Math::Min(currentMap.Tags.Length, PluginSettings::RMC_TagsLength);
                            for (uint i = 0; i < tagsRender; i++) {
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
            UI::SameLine();
            UI::Text(Icons::InfoCircle);
            UI::SetPreviousTooltip("Map switch might be prevented by Nadeo if done too quickly.\n\nIf the podium screen is not shown after 10 seconds, you can \nstart a vote to change to the next map in the game pause menu.");
        }
    }

    void RenderPlayingButtons() override
    {
        if (TM::IsMapLoaded()) {
            SkipButtons();
            if (IS_DEV_MODE) {
                DevButtons();
            }
        }
    }

    void SkipButtons() override
    {
        string BelowMedal = PluginSettings::RMC_GoalMedal;
        int medalIndex = RMC::Medals.Find(PluginSettings::RMC_GoalMedal);
        if (medalIndex > 0) BelowMedal = RMC::Medals[medalIndex - 1];

        UI::BeginDisabled(RMC::ClickedOnSkip || isSwitchingMap);
        if(UI::Button(Icons::PlayCircleO + " Skip" + (RMC::GotBelowMedal ? " and take " + BelowMedal + " medal" : ""))) {
            RMC::ClickedOnSkip = true;
            if (RMC::IsPaused) RMC::IsPaused = false;

            if (RMC::GotBelowMedal) {
                BelowMedalCount += 1;
                RMTPlayerScore@ playerScored = GetPlayerScore(playerGotBelowGoal);
                playerScored.AddBelowGoal();
            } else if (
                (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.HasPrepatchTags(currentMap)) ||
                (PluginSettings::RMC_EditedMedalsWarns && TM::HasEditedMedals())
            ) {
                RMC::EndTime += RMC::TimeSpentMap;
            }
#if DEPENDENCY_BETTERCHAT
            BetterChat::SendChatMessage(Icons::Users + " Skipping map...");
#endif
            startnew(CoroutineFunc(RMTSwitchMap));
        }
        UI::EndDisabled();
    }

    void RenderScores()
    {
        string BelowMedal = PluginSettings::RMC_GoalMedal;
        int medalIndex = RMC::Medals.Find(PluginSettings::RMC_GoalMedal);
        if (medalIndex > 0) BelowMedal = RMC::Medals[medalIndex - 1];

        if (UI::BeginTable("RMTScores", 3)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn(PluginSettings::RMC_GoalMedal, UI::TableColumnFlags::WidthFixed, 40);
            UI::TableSetupColumn(BelowMedal, UI::TableColumnFlags::WidthFixed, 40);
            UI::TableHeadersRow();

            UI::TableSetColumnEnabled(2, PluginSettings::RMC_GoalMedal != RMC::Medals[0]);

            UI::ListClipper clipper(m_playerScores.Length);
            while(clipper.Step()) {
                for(int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++)
                {
                    UI::TableNextRow();
                    UI::PushID("RMTScore"+i);
                    RMTPlayerScore@ s = m_playerScores[i];
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();
                    UI::Text(s.name);
                    UI::TableNextColumn();
                    UI::Text(tostring(s.goals));
                    UI::TableNextColumn();
                    if (PluginSettings::RMC_GoalMedal != RMC::Medals[0]) {
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
        if (TM::IsMapLoaded()) {
            auto map = GetApp().RootMap;

            uint objectiveTime = uint(-1);
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) objectiveTime = map.TMObjective_AuthorTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) objectiveTime = map.TMObjective_GoldTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) objectiveTime = map.TMObjective_SilverTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[0]) objectiveTime = map.TMObjective_BronzeTime;


            if (m_mapPersonalBests.Length > 0) {
                for (uint r = 0; r < m_mapPersonalBests.Length; r++) {
                    if (m_mapPersonalBests[r].time <= 0) continue;
                    if (m_mapPersonalBests[r].time <= objectiveTime) {
                        @playerGotGoal = m_mapPersonalBests[r];
                        return true;
                    }
                }
            }
        }
        return false;
    }

    bool isBelowObjectiveCompleted()
    {
        if (TM::IsMapLoaded()) {
            auto map = GetApp().RootMap;

            uint objectiveTime = uint(-1);
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) objectiveTime = map.TMObjective_GoldTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) objectiveTime = map.TMObjective_SilverTime;
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) objectiveTime = map.TMObjective_BronzeTime;


            if (m_mapPersonalBests.Length > 0) {
                for (uint r = 0; r < m_mapPersonalBests.Length; r++) {
                    if (m_mapPersonalBests[r].time <= 0) continue;
                    if (m_mapPersonalBests[r].time <= objectiveTime) {
                        @playerGotBelowGoal = m_mapPersonalBests[r];
                        return true;
                    }
                }
            }
        }
        return false;
    }

    void UpdateRecords() {
        auto newPBs = GetPlayersPBsMLFeed();
        if (newPBs.Length > 0) // empty arrays are returned on e.g., http error
            m_mapPersonalBests = newPBs;
    }

    array<PBTime@> GetPlayersPBsMLFeed() {
        array<PBTime@> ret;
#if DEPENDENCY_MLFEEDRACEDATA
        try {
            auto app = cast<CTrackMania>(GetApp());
            if (app.Network is null || app.Network.ClientManiaAppPlayground is null) return {};
            auto raceData = MLFeed::GetRaceData_V4();
            if (raceData is null) return {};
            auto @players = raceData.SortedPlayers_TimeAttack;
            if (players.Length == 0) return {};
            for (uint i = 0; i < players.Length; i++) {
                auto player = cast<MLFeed::PlayerCpInfo_V4>(players[i]);
                if (player is null) continue;
                if (player.bestTime < 1) continue;
                if (player.BestRaceTimes is null || player.BestRaceTimes.Length != raceData.CPsToFinish) continue;
                auto pbTime = PBTime(player);
                ret.InsertLast(pbTime);
            }
            ret.SortAsc();
        } catch {
            warn("Error while getting player PBs: " + getExceptionInfo());
        }
#endif
        return ret;
    }

    void UpdateRecordsLoop() {
        while (RMC::IsRunning) {
            sleep(500);
            if (!isSwitchingMap) UpdateRecords();
        }
    }

    RMTPlayerScore@ GetPlayerScore(PBTime@ _player) {
        for (uint i = 0; i < m_playerScores.Length; i++) {
            RMTPlayerScore@ score = m_playerScores[i];
            if (score.wsid == _player.wsid) return score;
        }

        auto newPlayer = RMTPlayerScore(_player);
        m_playerScores.InsertLast(newPlayer);

        return newPlayer;
    }

    void DrawPlayerProgress() {
        if (UI::CollapsingHeader("Current Runs")) {
#if DEPENDENCY_MLFEEDRACEDATA
            auto rd = MLFeed::GetRaceData_V4();
            if (rd is null) return;

            UI::ListClipper clip(rd.SortedPlayers_TimeAttack.Length);
            if (UI::BeginTable("player-curr-runs", 4, UI::TableFlags::SizingStretchProp | UI::TableFlags::ScrollY)) {
                UI::TableSetupScrollFreeze(0, 1);
                UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("CP", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Time", UI::TableColumnFlags::WidthStretch);
                UI::TableSetupColumn("Delta", UI::TableColumnFlags::WidthStretch);
                UI::TableHeadersRow();

                while (clip.Step()) {
                    for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                        auto p = rd.SortedPlayers_TimeAttack[i];
                        UI::PushID(i);

                        UI::TableNextRow();

                        UI::TableNextColumn();
                        UI::AlignTextToFramePadding();
                        UI::Text(p.Name);
                        UI::TableNextColumn();
                        UI::Text(tostring(p.CpCount));
                        UI::TableNextColumn();
                        UI::Text(Time::Format(p.LastCpOrRespawnTime));
                        UI::TableNextColumn();
                        auto best = p.BestRaceTimes;
                        if (best !is null && best.Length == rd.CPsToFinish) {
                            bool isBehind = false;
                            // best player times start with index 0 being CP 1 time
                            auto cpBest = p.CpCount == 0 ? 0 : int(best[p.CpCount - 1]);
                            auto lastCpTimeVirtual = p.LastCpOrRespawnTime;
                            // account for current race time via next cp
                            if (p.CpCount < int(best.Length) && p.CurrentRaceTime > int(best[p.CpCount])) {
                                // delta = last CP time - best CP time (for that CP)
                                // we are ahead when last < best
                                // so if we're behind, last > best, and the minimum difference to our pb is given by (last = current race time, and best = next CP time)
                                isBehind = true;
                                lastCpTimeVirtual = p.CurrentRaceTime;
                                cpBest = best[p.CpCount];
                            }
                            string time = (p.IsFinished ?  (lastCpTimeVirtual <= cpBest ? "\\$5f5" : "\\$f53") : (lastCpTimeVirtual <= cpBest && !isBehind) ? "\\$48f-" : "\\$f84+")
                                + Time::Format(p.IsFinished ? p.LastCpTime : Math::Abs(lastCpTimeVirtual - cpBest))
                                + (isBehind ? " (*)" : "");
                            UI::Text(time);
                        } else {
                            UI::Text("\\$888-:--.---");
                        }
                        UI::PopID();
                    }
                }
                UI::EndTable();
            }
#else
            // shouldn't show up, but w/e
            UI::Text("MLFeed required.");
#endif
        }
    }
}

class RMTPlayerScore {
    string name;
    string wsid;
    int goals;
    int belowGoals;

    RMTPlayerScore(PBTime@ _player) {
        this.wsid = _player.wsid;
        this.name = _player.name;
    }

    int AddGoal() {
        this.goals++;

        return this.goals;
    }

    int AddBelowGoal() {
        this.belowGoals++;

        return this.belowGoals;
    }

    int opCmp(RMTPlayerScore@ other) const {
        if (this.goals < other.goals) return -1;
        if (this.goals == other.goals) return 0;
        return 1;
    }
#else
    string GetModeName() override { return "Random Map Together (NOT SUPPORTED ON THIS GAME)";}
#endif
}
