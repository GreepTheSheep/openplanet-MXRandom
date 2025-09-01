class RMT : RMC {
#if TMNEXT
    string LobbyMapUID = "";
    NadeoServices::ClubRoom@ RMTRoom;
    array<PBTime@> m_mapPersonalBests;
    array<RMTPlayerScore@> m_playerScores;
    PBTime@ playerGotGoal;
    PBTime@ playerGotBelowGoal;
    bool pressedStopButton = false;

    string get_ModeName() override { return "Random Map Together";}

    void DevButtons() override {}

    void Render() override {
        if (UI::IsOverlayShown() || PluginSettings::RMC_AlwaysShowBtns) {
            if (UI::RedButton(Icons::Times + " Stop RMT")) {
                pressedStopButton = true;
                RMC::IsRunning = false;
                RMC::ShowTimer = false;
#if DEPENDENCY_BETTERCHAT
                BetterChat::SendChatMessage(Icons::Users + " Random Map Together stopped");
                startnew(CoroutineFunc(BetterChatSendLeaderboard));
#endif
                startnew(CoroutineFunc(ResetToLobbyMap));
            }

            UI::Separator();
        }

        RenderTimer();
        if (IS_DEV_MODE) UI::Text(RMC::FormatTimer(TotalTime));
        UI::Separator();
        RenderGoalMedal();
        RenderBelowGoalMedal();
        RenderMVPPlayer();

        if (PluginSettings::RMC_DisplayPace) {
            try {
                float goalPace = ((TimeLimit / 60 / 1000) * RMC::GoalMedalCount / (TimeLeft / 60 / 100));
                UI::Text("Pace: " + goalPace);
            } catch {
                UI::Text("Pace: 0");
            }
        }

        if (PluginSettings::RMC_DisplayCurrentMap) {
            RenderCurrentMap();
        }

        if (RMC::IsRunning && (UI::IsOverlayShown() || PluginSettings::RMC_AlwaysShowBtns)) {
            UI::Separator();
            RenderPlayingButtons();
            UI::Separator();
            DrawPlayerProgress();
        }
    }

    void StartRMT() {
        RMC::GoalMedalCount = 0;
        RMC::ShowTimer = true;
        RMC::IsSwitchingMap = false;
        Log::Trace("RMT: Getting lobby map UID from the room...");
        MXNadeoServicesGlobal::CheckNadeoRoomAsync();
        yield();
        @RMTRoom = MXNadeoServicesGlobal::foundRoom;
        LobbyMapUID = RMTRoom.room.currentMapUid;
        Log::Trace("RMT: Lobby map UID: " + LobbyMapUID);
#if DEPENDENCY_BETTERCHAT
        BetterChat::SendChatMessage(Icons::Users + " Starting Random Map Together. Have Fun!");
        sleep(200);
        BetterChat::SendChatMessage(Icons::Users + " Goal medal: " + tostring(PluginSettings::RMC_Medal));
#endif
        SetupMapStart();
    }

    void SetupMapStart() {
        RMC::IsStarting = true;
        RMC::IsSwitchingMap = true;

        while (RMC:: IsStarting || RMC::IsRunning) {
            @currentMap = MX::GetRandomMap();

            if (currentMap !is null) {
                if (PluginSettings::SkipSeenMaps) {
                    seenMaps.InsertLast(currentMap.MapUid);
                }

                break;
            }

            sleep(2000);
        }

        Log::LoadingMapNotification(currentMap);
        DataManager::SaveMapToRecentlyPlayed(currentMap);

        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMTRoom, currentMap.MapUid);
        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, TimeLimit / 1000);

        RMC::GotGoalMedal = false;
        RMC::GotBelowMedal = false;

        while (!TM::IsServerReady()) {
            yield();
        }

        RMC::IsPaused = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(UpdateRecordsLoop));
        RMC::IsSwitchingMap = false;
        RMC::IsStarting = false;
        PreloadNextMap();
    }

    void RMTSwitchMap() {
        m_playerScores.SortDesc();
        RMC::IsSwitchingMap = true;
        m_mapPersonalBests = {};
        RMC::IsPaused = true;
        RMC::GotGoalMedal = false;
        RMC::GotBelowMedal = false;
        
        if (nextMap is null) {
            PreloadNextMap();
        }
        @currentMap = nextMap;

        if (RMC::TimeSpentMap < 15000) {
            // Only notify if the server has spent fewer than 15 secs on the map
            UI::ShowNotification(Icons::InfoCircle + " RMT - Information on map switching", "Map switch might be prevented by Nadeo if done too quickly.\nIf the podium screen is not shown after 10 seconds, you can start a vote to change to the next map in the game pause menu.", Text::ParseHexColor("#420399"));
        }

        Log::LoadingMapNotification(currentMap);
        DataManager::SaveMapToRecentlyPlayed(currentMap);
        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMTRoom, currentMap.MapUid);
        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);
        RMC::TimeSpentMap = 0;

        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, TimeLeft / 1000);

        while (!TM::IsServerReady()) {
            yield();
        }

        m_playerScores.SortDesc();
#if DEPENDENCY_BETTERCHAT
        if (!m_playerScores.IsEmpty()) {
            RMTPlayerScore@ p = m_playerScores[0];
            string currentStatChat = Icons::Users + " RMT Leaderboard: " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_Medal) + " medals" + (PluginSettings::RMC_Medal != Medals::Bronze ? " - " + BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medals" : "") + "\n";
            currentStatChat += "Current MVP: " + p.name + ": " + p.goals + " " + tostring(PluginSettings::RMC_Medal) +
                (PluginSettings::RMC_Medal != Medals::Bronze ?
                    " - " + p.belowGoals + " " + tostring(Medals(PluginSettings::RMC_Medal - 1))
                : "");
            BetterChat::SendChatMessage(currentStatChat);
        }
#endif

        RMC::IsPaused = false;
        RMC::IsSwitchingMap = false;
        startnew(CoroutineFunc(PreloadNextMap));
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
        }
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, 0);
    }

    void TimerYield() override {
        int lastUpdate = Time::Now;

        while (RMC::IsRunning) {
            yield();

            if (!RMC::IsPaused) {
                if (!InCurrentMap()) {
                    RMC::IsPaused = true;
                } else if (!pressedStopButton && (!RMC::IsRunning || TimeLeft == 0)) {
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
                } else {
                    if (!RMC::GotGoalMedal && isObjectiveCompleted()) {
                        Log::Log(playerGotGoal.name + " got the goal medal with a time of " + playerGotGoal.time);
                        UI::ShowNotification(Icons::Trophy + " " + playerGotGoal.name + " got the " + tostring(PluginSettings::RMC_Medal) + " medal with a time of " + playerGotGoal.timeStr, "Switching map...", Text::ParseHexColor("#01660f"));
                        RMC::GoalMedalCount++;
                        RMC::GotGoalMedal = true;
                        RMTPlayerScore@ playerScored = GetPlayerScore(playerGotGoal);
                        playerScored.AddGoal();
                        m_playerScores.SortDesc();

    #if DEPENDENCY_BETTERCHAT
                        BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotGoal.name + " got the " + tostring(PluginSettings::RMC_Medal) + " medal with a time of " + playerGotGoal.timeStr);
                        sleep(200);
                        BetterChat::SendChatMessage(Icons::Users + " Switching map...");
    #endif

                        startnew(CoroutineFunc(RMTSwitchMap));
                    } else if (!RMC::GotGoalMedal && !RMC::GotBelowMedal && PluginSettings::RMC_Medal != Medals::Bronze && isBelowObjectiveCompleted()) {
                        Log::Log(playerGotBelowGoal.name + " got the below goal medal with a time of " + playerGotBelowGoal.time);
                        UI::ShowNotification(Icons::Trophy + " " + playerGotBelowGoal.name + " got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal with a time of " + playerGotBelowGoal.timeStr, "You can skip and take " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal", Text::ParseHexColor("#4d3e0a"));
                        RMC::GotBelowMedal = true;
    #if DEPENDENCY_BETTERCHAT
                        BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotBelowGoal.name + " got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal with a time of " + playerGotBelowGoal.timeStr);
                        sleep(200);
                        BetterChat::SendChatMessage(Icons::Users + " You can skip and take the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal");
    #endif
                    }
    
                    int delta = Time::Now - lastUpdate;
                    TimeLeft -= delta;
                    TotalTime += delta;
                    RMC::TimeSpentMap += delta;
                }
            }

            lastUpdate = Time::Now;
        }
    }

    void GameEndNotification() override {
        string notificationText = "Your team got " + RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal);

        if (PluginSettings::RMC_Medal != Medals::Bronze && BelowMedalCount > 0) {
            notificationText += " and " + BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1));
        }
        notificationText += " medals!";

        UI::ShowNotification("\\$0f0" + ModeName + " ended!", notificationText);
    }

    void RenderMVPPlayer() {
        if (!m_playerScores.IsEmpty()) {
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
        if (!m_playerScores.IsEmpty()) {
            string currentStatsChat = Icons::Users + " RMT Leaderboard: " + tostring(RMC::GoalMedalCount) + " " + tostring(PluginSettings::RMC_Medal) + " medals" + (PluginSettings::RMC_Medal != Medals::Bronze ? " - " + BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medals" : "") + "\n\n";
            for (uint i = 0; i < m_playerScores.Length; i++) {
                RMTPlayerScore@ p = m_playerScores[i];
                currentStatsChat += tostring(i+1) + ". " + p.name + ": " + p.goals + " " + tostring(PluginSettings::RMC_Medal) + (PluginSettings::RMC_Medal != Medals::Bronze ? " - " + p.belowGoals + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)) : "") + "\n";
            }
            BetterChat::SendChatMessage(currentStatsChat);
        }
#endif
    }

    void RenderCurrentMap() override {
        if (!RMC::IsSwitchingMap) {
            if (InCurrentMap()) {
                UI::Separator();

                if (currentMap !is null) {
                    UI::Text(currentMap.Name);

                    if (PluginSettings::RMC_ShowAwards) {
                        UI::SameLine();
                        UI::Text("\\$db4" + Icons::Trophy + "\\$z " + currentMap.AwardCount);
                    }

                    if (PluginSettings::RMC_DisplayMapDate) {
                        UI::TextDisabled(Date::FormatISO(currentMap.UpdatedAt, "%d-%m-%Y"));
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
                    UI::TextDisabled("Map info unavailable");
                }
            }
        } else {
            UI::Separator();
            UI::AlignTextToFramePadding();
            UI::Text("Switching map...");
            UI::SameLine();
            UI::TextDisabled(Icons::InfoCircle);
            UI::SetPreviousTooltip("Map switch might be prevented by Nadeo if done too quickly.\n\nIf the podium screen is not shown after 10 seconds, you can \nstart a vote to change to the next map in the game pause menu.");
        }
    }

    void RenderPlayingButtons() override {
        if (InCurrentMap()) {
            SkipButtons();
        }
    }

    void SkipButtons() override {
        Medals BelowMedal = PluginSettings::RMC_Medal;
        if (BelowMedal != Medals::Bronze) BelowMedal = Medals(BelowMedal - 1);

        UI::BeginDisabled(RMC::IsSwitchingMap);
        if (UI::Button(Icons::PlayCircleO + " Skip" + (RMC::GotBelowMedal ? " and take " + tostring(BelowMedal) + " medal" : ""))) {
            if (RMC::IsPaused) RMC::IsPaused = false;

            if (RMC::GotBelowMedal) {
                BelowMedalCount++;
                RMTPlayerScore@ playerScored = GetPlayerScore(playerGotBelowGoal);
                playerScored.AddBelowGoal();
            } else if (
                (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.HasPrepatchTags(currentMap)) ||
                (PluginSettings::RMC_EditedMedalsWarns && TM::HasEditedMedals())
            ) {
                TimeLeft += RMC::TimeSpentMap;
            }
#if DEPENDENCY_BETTERCHAT
            BetterChat::SendChatMessage(Icons::Users + " Skipping map...");
#endif
            startnew(CoroutineFunc(RMTSwitchMap));
        }
        UI::EndDisabled();
    }

    void RenderScores() {
        Medals BelowMedal = PluginSettings::RMC_Medal;
        if (BelowMedal != Medals::Bronze) BelowMedal = Medals(BelowMedal - 1);

        if (UI::BeginTable("RMTScores", 3, UI::TableFlags::Hideable)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn(tostring(PluginSettings::RMC_Medal), UI::TableColumnFlags::WidthFixed, 40);
            UI::TableSetupColumn(tostring(BelowMedal), UI::TableColumnFlags::WidthFixed, 40);
            UI::TableHeadersRow();

            UI::TableSetColumnEnabled(2, PluginSettings::RMC_Medal != Medals::Bronze);

            UI::ListClipper clipper(m_playerScores.Length);
            while (clipper.Step()) {
                for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                    UI::TableNextRow();
                    UI::PushID("RMTScore"+i);
                    RMTPlayerScore@ s = m_playerScores[i];
                    UI::TableNextColumn();
                    UI::AlignTextToFramePadding();
                    UI::Text(s.name);
                    UI::TableNextColumn();
                    UI::Text(tostring(s.goals));
                    UI::TableNextColumn();
                    if (PluginSettings::RMC_Medal != Medals::Bronze) {
                        UI::Text(tostring(s.belowGoals));
                    }
                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }

    bool isObjectiveCompleted() {
        if (InCurrentMap()) {
            if (!m_mapPersonalBests.IsEmpty()) {
                for (uint r = 0; r < m_mapPersonalBests.Length; r++) {
                    if (m_mapPersonalBests[r].time <= 0) continue;
                    if (m_mapPersonalBests[r].time <= GoalTime) {
                        @playerGotGoal = m_mapPersonalBests[r];
                        return true;
                    }
                }
            }
        }
        return false;
    }

    bool isBelowObjectiveCompleted() {
        if (InCurrentMap()) {
            if (!m_mapPersonalBests.IsEmpty()) {
                for (uint r = 0; r < m_mapPersonalBests.Length; r++) {
                    if (m_mapPersonalBests[r].time <= 0) continue;
                    if (m_mapPersonalBests[r].time <= BelowGoalTime) {
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
        if (!newPBs.IsEmpty()) // empty arrays are returned on e.g., http error
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
            if (players.IsEmpty()) return {};
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
            if (!RMC::IsSwitchingMap) UpdateRecords();
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
        if (RMC::IsStarting) {
            return;
        }

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
    string get_ModeName() override { return "Random Map Together (NOT SUPPORTED ON THIS GAME)";}
#endif
}
