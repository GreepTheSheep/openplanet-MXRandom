class RMT : RMC {
#if TMNEXT
    string LobbyMapUID = "";
    NadeoServices::ClubRoom@ RMTRoom;
    array<RMTPlayerScore@> m_playerScores;
    PBTime@ playerGotGoal;
    PBTime@ playerGotBelowGoal;

    string get_ModeName() override { return "Random Map Together";}

    RMC::GameMode get_Mode() override {
        return RMC::GameMode::Together;
    }

    void DevButtons() override {}

    void SubmitToLeaderboard() override { }

    void Render() override {
        if (RenderButtons) {
            if (UI::RedButton(Icons::Times + " Stop RMT")) {
                UserEndedRun = true;
                IsRunning = false;
                RMC::ShowTimer = false;
#if DEPENDENCY_BETTERCHAT
                BetterChat::SendChatMessage(Icons::Users + " " + ModeName + " stopped");
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

        if (PluginSettings::RMC_DisplayGoalTimes) {
            RenderGoalTimes();
        }

        RenderMVPPlayer();

        if (PluginSettings::RMC_DisplayPace) {
            RenderPace();
        }

        if (TM::IsInServer()) {
            if (PluginSettings::RMC_DisplayCurrentMap) {
                RenderCurrentMap();
            }

            if (IsRunning && RenderButtons) {
                UI::Separator();
                RenderPlayingButtons();
                UI::Separator();
                DrawPlayerProgress();
            }
        } else {
            UI::Separator();
            UI::Text("\\$f90" + Icons::ExclamationTriangle + " \\$zNot in a room.");

#if DEPENDENCY_BETTERROOMMANAGER
            if (UI::GreenButton(Icons::SignIn + " Rejoin room")) {
                startnew(MXNadeoServicesGlobal::JoinRMTRoom);
            }
#endif
        }
    }

    void Start() override {
        RMC::ShowTimer = true;
        Log::Trace("RMT: Getting lobby map UID from the room...");
        MXNadeoServicesGlobal::CheckNadeoRoomAsync();
        yield();
        @RMTRoom = MXNadeoServicesGlobal::foundRoom;
        LobbyMapUID = RMTRoom.room.currentMapUid;
        Log::Trace("RMT: Lobby map UID: " + LobbyMapUID);
#if DEPENDENCY_BETTERCHAT
        BetterChat::SendChatMessage(Icons::Users + " Starting " + ModeName + ". Have Fun!");
        sleep(200);
        BetterChat::SendChatMessage(Icons::Users + " Goal medal: " + tostring(PluginSettings::RMC_Medal));
#endif
        SetupMapStart();
    }

    void SetupMapStart() {
        IsStarting = true;
        IsSwitchingMap = true;

        while (!UserEndedRun) {
            @currentMap = MX::GetRandomMap();

            if (currentMap !is null) {
                if (PluginSettings::SkipSeenMaps) {
                    seenMaps.InsertLast(currentMap.MapUid);
                }

                break;
            }

            sleep(2000);
        }

        Log::Trace("[SetupMapStart] Loading map " + currentMap.toString());
        Log::LoadingMapNotification(currentMap);
        DataManager::SaveMapToRecentlyPlayed(currentMap);

        Log::Trace("[SetupMapStart] Setting up RMT room.");

        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMTRoom, currentMap.MapUid);
        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, TimeLimit / 1000);

        Log::Trace("[SetupMapStart] Waiting for server to be ready.");

        while (!TM::IsServerReady()) {
            yield();
        }

        Log::Trace("[SetupMapStart] Server is ready.");

        IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
        IsSwitchingMap = false;
        IsStarting = false;
        PreloadNextMap();
    }

    void SwitchMap() override {
        IsSwitchingMap = true;
        IsPaused = true;
        GotGoalMedal = false;
        GotBelowMedal = false;
        
        if (nextMap is null) {
            Log::Trace("[SwitchMap] Next map is null, preloading a new one.");
            PreloadNextMap();
        }

        @currentMap = nextMap;
        startnew(CoroutineFunc(PreloadNextMap));

        if (TimeSpentMap < 15000) {
            // Only notify if the server has spent fewer than 15 secs on the map
            UI::ShowNotification(Icons::InfoCircle + " RMT - Information on map switching", "Map switch might be prevented by Nadeo if done too quickly.\nIf the podium screen is not shown after 10 seconds, you can start a vote to change to the next map in the game pause menu.", Text::ParseHexColor("#420399"));
        }

        Log::Trace("RMC: Switching map to " + currentMap.toString());

        Log::LoadingMapNotification(currentMap);
        DataManager::SaveMapToRecentlyPlayed(currentMap);

        Log::Trace("[SwitchMap] Setting up next RMT map.");
        MXNadeoServicesGlobal::ClubRoomSetMapAndSwitchAsync(RMTRoom, currentMap.MapUid);

        Log::Trace("[SwitchMap] Waiting for correct map.");

        while (!TM::IsMapCorrect(currentMap.MapUid)) sleep(1000);

        Log::Trace("[SwitchMap] Correct map is loaded to room.");

        TimeSpentMap = 0;

        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, TimeLeft / 1000);

        Log::Trace("[SwitchMap] Waiting for server to be ready.");

        while (!TM::IsServerReady()) {
            yield();
        }

        Log::Trace("[SwitchMap] Server is ready.");

#if DEPENDENCY_BETTERCHAT
        if (!m_playerScores.IsEmpty()) {
            RMTPlayerScore@ p = m_playerScores[0];
            string currentStatChat = Icons::Users + " RMT Leaderboard: " + tostring(GoalMedalCount) + " " + tostring(PluginSettings::RMC_Medal) + " medals" + (ModeHasBelowMedal ? " - " + BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medals" : "") + "\n";
            currentStatChat += "Current MVP: " + p.name + ": " + p.goals + " " + tostring(PluginSettings::RMC_Medal) +
                (ModeHasBelowMedal ?
                    " - " + p.belowGoals + " " + tostring(Medals(PluginSettings::RMC_Medal - 1))
                : "");
            BetterChat::SendChatMessage(currentStatChat);
        }
#endif

        IsPaused = false;
        IsSwitchingMap = false;
    }

    void ResetToLobbyMap() {
        if (LobbyMapUID != "") {
            UI::ShowNotification("Returning to lobby map", "Please wait...", Text::ParseHexColor("#993f03"));
#if DEPENDENCY_BETTERCHAT
            sleep(200);
            BetterChat::SendChatMessage(Icons::Users + " Returning to lobby map...");
#endif
            MXNadeoServicesGlobal::SetMapToClubRoomAsync(RMTRoom, LobbyMapUID);
            if (UserEndedRun) MXNadeoServicesGlobal::ClubRoomSwitchMapAsync(RMTRoom);
            while (!TM::IsMapCorrect(LobbyMapUID)) sleep(1000);
        }
        MXNadeoServicesGlobal::ClubRoomSetCountdownTimer(RMTRoom, 0);
    }

    void TimerYield() override {
        int lastUpdate = Time::Now;

        while (IsRunning) {
            yield();

            if (!IsPaused) {
                if (!UserEndedRun && (!IsRunning || TimeLeft == 0)) {
                    IsRunning = false;
                    RMC::ShowTimer = false;
                    GameEndNotification();
#if DEPENDENCY_BETTERCHAT
                    BetterChat::SendChatMessage(Icons::Users + " " + ModeName + " ended, thanks for playing!");
                    sleep(200);
                    BetterChatSendLeaderboard();
#endif
                    ResetToLobbyMap();
                } else {
                    int delta = Time::Now - lastUpdate;
                    TimeLeft -= delta;
                    TotalTime += delta;
                    TimeSpentMap += delta;
                }
            }

            lastUpdate = Time::Now;
        }
    }

    void GameEndNotification() override {
        string notificationText = "Your team got " + GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal);

        if (ModeHasBelowMedal && BelowMedalCount > 0) {
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
            string currentStatsChat = Icons::Users + " RMT Leaderboard: " + tostring(GoalMedalCount) + " " + tostring(PluginSettings::RMC_Medal) + " medals" + (ModeHasBelowMedal ? " - " + BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medals" : "") + "\n\n";
            for (uint i = 0; i < m_playerScores.Length; i++) {
                RMTPlayerScore@ p = m_playerScores[i];
                currentStatsChat += tostring(i+1) + ". " + p.name + ": " + p.goals + " " + tostring(PluginSettings::RMC_Medal) + (ModeHasBelowMedal ? " - " + p.belowGoals + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)) : "") + "\n";
            }
            BetterChat::SendChatMessage(currentStatsChat);
        }
#endif
    }

    void RenderCurrentMap() override {
        if (!IsSwitchingMap) {
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

                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z " + tag.title);
                        UI::SetPreviousTooltip(tag.reason + (IS_DEV_MODE ? ("\nExeBuild: " + currentMap.ExeBuild) : ""));
                    }

                    if (PluginSettings::RMC_EditedMedalsWarns && currentMap.HasEditedMedals) {
                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z Edited Medals");

                        if (UI::BeginItemTooltip()) {
                            UI::Text("The map has medal times that differ from the default. The plugin will use the default times instead.");
                            
                            if (!PluginSettings::RMC_DisplayGoalTimes) {
                                UI::NewLine();
                                UI::Text("You can enable \"Display goal times\" in the settings or use the \"Default Medals\" plugin to see the times.");
                            }
                            UI::EndTooltip();
                        }
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
            BrokenSkipButton();
        }
    }

    void SkipButtons() override {
        UI::BeginDisabled(IsSwitchingMap);

        if (!GotBelowMedal) {
            int skipsLeft = Math::Max(0, PluginSettings::RMC_FreeSkipAmount - FreeSkipsUsed);

            UI::BeginDisabled(skipsLeft == 0);

            if (UI::Button(Icons::PlayCircleO + "Free Skip (" + skipsLeft + " left)")) {
                FreeSkipsUsed++;
                Log::Trace("RMT: Skipping map");
                UI::ShowNotification("Please wait...");

#if DEPENDENCY_BETTERCHAT
                BetterChat::SendChatMessage(Icons::Users + " Skipping map...");
#endif

                startnew(CoroutineFunc(SwitchMap));
            }

            UI::EndDisabled();

            UI::SetPreviousTooltip(
                "Free Skips are if the map is finishable but your team still want to skip it for any reason.\n\n" +
                "If the map is broken, please use the button below instead."
            );
        } else if (ModeHasBelowMedal && UI::Button(Icons::PlayCircleO + " Take " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal")) {
            BelowMedalCount++;
            RMTPlayerScore@ playerScored = GetPlayerScore(playerGotBelowGoal);
            playerScored.AddBelowGoal();
            m_playerScores.SortDesc();
            Log::Trace("RMT: Skipping map");
            UI::ShowNotification("Please wait...");
#if DEPENDENCY_BETTERCHAT
            BetterChat::SendChatMessage(Icons::Users + " Skipping map...");
#endif
            startnew(CoroutineFunc(SwitchMap));
        }

        UI::EndDisabled();
    }

    void RenderScores() {
        Medals BelowMedal = PluginSettings::RMC_Medal;
        if (ModeHasBelowMedal) BelowMedal = Medals(BelowMedal - 1);

        if (UI::BeginTable("RMTScores", 3, UI::TableFlags::Hideable)) {
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn(tostring(PluginSettings::RMC_Medal), UI::TableColumnFlags::WidthFixed);
            UI::TableSetupColumn(tostring(BelowMedal), UI::TableColumnFlags::WidthFixed);
            UI::TableHeadersRow();

            UI::TableSetColumnEnabled(2, ModeHasBelowMedal);

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
                    if (ModeHasBelowMedal) {
                        UI::Text(tostring(s.belowGoals));
                    }
                    UI::PopID();
                }
            }
            UI::EndTable();
        }
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

    RMTPlayerScore@ GetPlayerScore(PBTime@ _player) {
        for (uint i = 0; i < m_playerScores.Length; i++) {
            RMTPlayerScore@ score = m_playerScores[i];
            if (score.wsid == _player.wsid) return score;
        }

        auto newPlayer = RMTPlayerScore(_player);
        m_playerScores.InsertLast(newPlayer);
        m_playerScores.SortDesc();

        return newPlayer;
    }

    void DrawPlayerProgress() {
        if (IsStarting) {
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

    void GotGoalMedalNotification() override {
        Log::Info(playerGotGoal.name + " got the goal medal with a time of " + playerGotGoal.time);
        UI::ShowNotification(Icons::Trophy + " " + playerGotGoal.name + " got the " + tostring(PluginSettings::RMC_Medal) + " medal with a time of " + playerGotGoal.timeStr, "Switching map...", Text::ParseHexColor("#01660f"));

#if DEPENDENCY_BETTERCHAT
        BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotGoal.name + " got the " + tostring(PluginSettings::RMC_Medal) + " medal with a time of " + playerGotGoal.timeStr);
        sleep(200);
        BetterChat::SendChatMessage(Icons::Users + " Switching map...");
#endif
    }

    void GotBelowGoalMedalNotification() override {
        Log::Info(playerGotBelowGoal.name + " got the below goal medal with a time of " + playerGotBelowGoal.time);
        UI::ShowNotification(Icons::Trophy + " " + playerGotBelowGoal.name + " got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal with a time of " + playerGotBelowGoal.timeStr, "You can skip and take " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal", Text::ParseHexColor("#4d3e0a"));

#if DEPENDENCY_BETTERCHAT
        BetterChat::SendChatMessage(Icons::Trophy + " " + playerGotBelowGoal.name + " got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal with a time of " + playerGotBelowGoal.timeStr);
        sleep(200);
        BetterChat::SendChatMessage(Icons::Users + " You can skip and take the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal");
#endif
    }

    void PbLoop() override {
        while (IsRunning) {
            if (!IsPaused && !IsSwitchingMap && !GotGoalMedal) {
                array<PBTime@> m_mapPersonalBests = GetPlayersPBsMLFeed();
                PBTime@ bestPB;

                for (uint r = 0; r < m_mapPersonalBests.Length; r++) {
                    if (m_mapPersonalBests[r].time <= 0) {
                        continue;
                    }

                    if (bestPB is null || m_mapPersonalBests[r].time < bestPB.time) {
                        @bestPB = m_mapPersonalBests[r];

                        if (bestPB.time <= GoalTime) {
                            break;
                        }
                    }
                }

                if (bestPB is null) {
                    sleep(200);
                    continue;
                }

                if (bestPB.time <= GoalTime) {
                    GotGoalMedal = true;
                    GoalMedalCount++;
                    @playerGotGoal = bestPB;
                    RMTPlayerScore@ playerScored = GetPlayerScore(playerGotGoal);
                    playerScored.AddGoal();
                    m_playerScores.SortDesc();
                    GotGoalMedalNotification();
                    startnew(CoroutineFunc(SwitchMap));
                } else if (!GotBelowMedal && ModeHasBelowMedal && bestPB.time <= BelowGoalTime) {
                    GotBelowMedal = true;
                    @playerGotBelowGoal = bestPB;
                    GotBelowGoalMedalNotification();
                }
            }

            sleep(200);
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
        if (this.goals == other.goals) {
            if (this.belowGoals == other.belowGoals) {
                return SortString(this.name, other.name);
            }

            return Math::Clamp(this.belowGoals - other.belowGoals, -1, 1);
        }

        return Math::Clamp(this.goals - other.goals, -1, 1);
    }
#endif
}
