class RMC {
    // Settings
    RunSettings@ RunConfig = RunSettings(this.Mode);

    // Medals
    int GoalMedalCount = 0;
    bool GotGoalMedal = false;
    int BelowMedalCount = 0;
    bool GotBelowMedal = false;
    int FreeSkipsUsed = 0;

    // Status
    bool IsInited = false;
    bool IsPaused = false;
    bool IsRunning = false;
    bool IsStarting = false;
    bool IsSwitchingMap = false;

    // Map
    MX::MapInfo@ currentMap;
    MX::MapInfo@ nextMap;
    array<MX::MapInfo@> playedMaps;
    int TimeSpentMap = -1;
    int PBOnMap = -1; // for autosaves on PBs
    bool IsMapInvalidated = false;

    // Timer
    int _TimeLeft = TimeLimit;
    int _TotalTime = 0;

    bool ContinueSavedRun = false;
    bool CancelledRun = false;
    bool UnpauseOnExit = false;
    bool UserEndedRun = false; // Check if the user has clicked on "Stop..." button

    UI::Texture@ WRTex = UI::LoadTexture("src/Assets/Images/WRTrophy.png");
    UI::Texture@ AuthorTex = UI::LoadTexture("src/Assets/Images/Author.png");
    UI::Texture@ GoldTex = UI::LoadTexture("src/Assets/Images/Gold.png");
    UI::Texture@ SilverTex = UI::LoadTexture("src/Assets/Images/Silver.png");
    UI::Texture@ BronzeTex = UI::LoadTexture("src/Assets/Images/Bronze.png");

    array<UI::Texture@> Textures = { 
        BronzeTex,
        SilverTex,
        GoldTex,
        AuthorTex,
        WRTex
    };

    string get_ModeName() { 
        return "Random Map Challenge";
    }

    RMC::GameMode get_Mode() {
        return RMC::GameMode::Challenge;
    }

    void LoadSave() {
        GoalMedalCount = RMC::CurrentRunData["PrimaryCounterValue"];
        BelowMedalCount = RMC::CurrentRunData["SecondaryCounterValue"];
        GotGoalMedal = RMC::CurrentRunData["GotGoalMedal"];
        PBOnMap = RMC::CurrentRunData["PBOnMap"];
        TimeSpentMap = RMC::CurrentRunData["TimeSpentOnMap"];
        GotBelowMedal = RMC::CurrentRunData["GotBelowMedal"];
        FreeSkipsUsed = RMC::CurrentRunData["FreeSkipsUsed"];
        TimeLeft = RMC::CurrentRunData["TimeLeft"];
        TotalTime = RMC::CurrentRunData["TotalTime"];

        if (RMC::CurrentRunData.HasKey("Settings")) {
            @RunConfig = RunSettings(RMC::CurrentRunData["Settings"]);
        }

        if (RMC::CurrentRunData.HasKey("IsMapInvalidated")) {
            IsMapInvalidated = bool(RMC::CurrentRunData["IsMapInvalidated"]);
        }

        if (RMC::CurrentRunData.HasKey("PlayedMaps")) {
            Json::Value@ saveMaps = RMC::CurrentRunData["PlayedMaps"];

            for (uint i = 0; i < saveMaps.Length; i++) {
                try {
                    Json::Value@ map = saveMaps[i];
                    playedMaps.InsertLast(MX::MapInfo(map));
                } catch {
                    Log::Error("Error converting map in save file.");
                }
            }
        }
    }

    void CheckSave() {
        if (!DataManager::LoadRunData()) {
            DataManager::CreateSaveFile();
            return;
        }

        auto saveDialog = ContinueSavedRunModalDialog(this);
        Renderables::Add(saveDialog);

        while (!saveDialog.HasCompletedCheckbox) {
            if (saveDialog.ShouldDisappear()) {
                CancelledRun = true;
                return;
            }

            sleep(100);
        }

        if (!ContinueSavedRun) {
            return;
        }

        LoadSave();

        MX::MapInfo@ map = MX::MapInfo(RMC::CurrentRunData["MapData"]);
        map.PlayedAt = Time::Stamp;
        Log::LoadingMapNotification(map);
        DataManager::SaveMapToRecentlyPlayed(map);
        await(startnew(TM::LoadMap, map));
    }

    void Start() {
        RMC::ShowTimer = true;
        IsStarting = true;

        CheckSave();

        if (CancelledRun) {
            IsStarting = false;
            RMC::ShowTimer = false;

            return;
        }

        if (!ContinueSavedRun) {
            MX::LoadRandomMap(RunConfig.CustomSearchFilters);
        }

        while (!TM::IsMapLoaded() || !TM::IsPlayerReady()) {
            yield();
        }

        @currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
        playedMaps.InsertLast(currentMap);
        StartTimer();

        UI::ShowNotification("\\$080" + ModeName + " started!", "Good Luck!");
        IsInited = true;

        // Clear the currently saved data so you cannot load into the same state multiple times
        DataManager::RemoveCurrentSaveFile();
        DataManager::CreateSaveFile();
        IsStarting = false;
    }

    void Reset() {
        GoalMedalCount = 0;
        BelowMedalCount = 0;
        TimeLeft = TimeLimit;
        TotalTime = 0;
        FreeSkipsUsed = 0;
        playedMaps.RemoveRange(0, playedMaps.Length);

        DataManager::RemoveCurrentSaveFile();
        DataManager::CreateSaveFile();

        Log::Info("Resetting " + ModeName + "...",  true);
        startnew(CoroutineFunc(SwitchMap));
    }

    void CreateSave() {
        RMC::CurrentRunData["PrimaryCounterValue"] = GoalMedalCount;
        RMC::CurrentRunData["SecondaryCounterValue"] = BelowMedalCount;
        RMC::CurrentRunData["FreeSkipsUsed"] = FreeSkipsUsed;
        RMC::CurrentRunData["GotGoalMedal"] = GotGoalMedal;
        RMC::CurrentRunData["GotBelowMedal"] = GotBelowMedal;
        RMC::CurrentRunData["MapData"] = currentMap.ToJson();
        RMC::CurrentRunData["TotalTime"] = TotalTime;
        RMC::CurrentRunData["TimeLeft"] = TimeLeft;
        RMC::CurrentRunData["TimeSpentOnMap"] = TimeSpentMap;
        RMC::CurrentRunData["PBOnMap"] = PBOnMap;
        RMC::CurrentRunData["Settings"] = RunConfig.ToJson();
        RMC::CurrentRunData["IsMapInvalidated"] = IsMapInvalidated;

        Json::Value mapsArray = Json::Array();
        for (uint i = 0; i < playedMaps.Length; i++) {
            mapsArray.Add(playedMaps[i].ToJson());
        }

        RMC::CurrentRunData["PlayedMaps"] = mapsArray;

        DataManager::SaveCurrentRunData();
    }

    int get_TimeLimit() { return RunConfig.MaxTimer * 60 * 1000; }

    int get_TimeLeft() {
        return Math::Max(0, Math::Min(TimeLimit, _TimeLeft));
    }

    void set_TimeLeft(int n) {
        _TimeLeft = Math::Clamp(n, 0, TimeLimit);
    }

    int get_TotalTime() {
        return _TotalTime;
    }

    void set_TotalTime(int n) {
        _TotalTime = Math::Max(0, n);
    }

    bool InCurrentMap() {
        return currentMap !is null && TM::IsMapCorrect(currentMap.MapUid);
    }

    void ReturnToMap() {
        UI::ShowNotification("Returning to current map...");
        await(startnew(TM::LoadMap, currentMap));

        Log::Trace("[ReturnToMap] Waiting to be back to the current map.");

        while (!TM::IsMapLoaded()) {
            sleep(100);
        }

        Log::Trace("[ReturnToMap] Back to current map!");
        Log::Trace("[ReturnToMap] Waiting for player to be ready.");

        while (!TM::IsPlayerReady()) {
            yield();
        }

        Log::Trace("[ReturnToMap] Player is ready, unpausing timer.");

        IsPaused = false;
    }

    bool get_ModeHasBelowMedal() {
        return RunConfig.GoalMedal != Medals::Bronze;
    }

    void RenderGoalTimes() {
        if (!InCurrentMap()) {
            return;
        }

        UI::Text(UI::GetMedalIcon(RunConfig.GoalMedal) + " Goal: " + UI::FormatTime(GoalTime, currentMap.Type));

        if (RunConfig.CalculateMedals && currentMap.IsMedalEdited(RunConfig.GoalMedal)) {
            UI::SameLine();
            UI::Text(Icons::Pencil);
            UI::SetItemTooltip("The author has edited the " + tostring(RunConfig.GoalMedal) + " medal to make it harder.\n\nThe plugin will use this time instead.");
        }

        if (!ModeHasBelowMedal) {
            return;
        }

        Medals belowMedal = Medals(RunConfig.GoalMedal - 1);
        UI::Text(UI::GetMedalIcon(belowMedal) + " Below goal: " + UI::FormatTime(BelowGoalTime, currentMap.Type));

        if (RunConfig.CalculateMedals && currentMap.IsMedalEdited(belowMedal)) {
            UI::SameLine();
            UI::Text(Icons::Pencil);
            UI::SetItemTooltip("The author has edited the " + tostring(belowMedal) + " medal to make it harder.\n\nThe plugin will use this time instead.");
        }
    }

    bool get_RenderButtons() {
        return PluginSettings::RMC_AlwaysShowBtns || UI::IsOverlayShown();
    }

    void Render() {
        string lastLetter = tostring(this.Mode).SubStr(0,1);
        if (IsRunning && RenderButtons) {
            if (UI::RedButton(Icons::Times + " Stop RM" + lastLetter)) {
                UserEndedRun = true;
                IsRunning = false;
                RMC::ShowTimer = false;

                if (GoalMedalCount != 0 || BelowMedalCount != 0 || GotBelowMedal || GotGoalMedal) {
                    if (!PluginSettings::RMC_RUN_AUTOSAVE) {
                        Renderables::Add(SaveRunQuestionModalDialog(this));
                    } else {
                        CreateSave();
                        vec4 color = UI::HSV(0.25, 1, 0.7);
                        UI::ShowNotification(PLUGIN_NAME, "Saved the state of the current run", color, 5000);
                    }
                } else {
                    // no saves for instant resets
                    DataManager::RemoveCurrentSaveFile();
                }
            }

            float buttonWidth = UI::GetItemRect().z;

            UI::SameLine();

            UI::BeginDisabled(!IsRunning || IsSwitchingMap);

            if (UI::OrangeButton(Icons::Refresh + " Reset", vec2(buttonWidth, 0))) {
                Reset();
            }

            UI::EndDisabled();

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

        if (PluginSettings::RMC_DisplayPace) {
            RenderPace();
        }

        RenderCurrentMap();

#if TMNEXT
        RenderCustomSearchWarning();
#endif

        if (IsRunning && RenderButtons) {
            UI::Separator();
            RenderPlayingButtons();
        }
    }

    void RenderPace() {
        try {
            int goalPace = int(Math::Floor(float(TimeLimit) * GoalMedalCount / float(TotalTime)));
            UI::Text("Pace: " + goalPace);
        } catch {
            UI::Text("Pace: 0");
        }
    }

    bool get_IsRunValid() {
        return RunConfig.Category != RMC::Category::Custom && FreeSkipsUsed <= 1 && TotalTime < 61 * 60 * 1000;
    }

    void RenderCustomSearchWarning() {
        if ((IsRunning || IsStarting) && !IsRunValid) {
            UI::Separator();
            UI::Text("\\$fc0" + Icons::ExclamationTriangle + " \\$zInvalid for official leaderboards");

            if (RunConfig.Category == RMC::Category::Custom) {
                UI::SetItemTooltip("This run is using custom run settings, you will only get maps based on the settings you configured.");
            } else {
                UI::SetItemTooltip("This run's duration / skips used are impossible under normal settings.");
            }
        }
    }

    void RenderTimer() {
        UI::PushFont(Fonts::TimerFont);

        if (IsPaused || !IsRunning) {
            UI::TextDisabled(RMC::FormatTimer(TimeLeft));
        } else {
            UI::Text(RMC::FormatTimer(TimeLeft));
        }

        UI::PopFont();

        UI::Dummy(vec2(0, 8));

        if (PluginSettings::RMC_DisplayMapTimeSpent) {
            UI::PushFont(Fonts::HeaderSub);
            UI::Text(Icons::Map + " " + RMC::FormatTimer(TimeSpentMap));
            UI::SetItemTooltip("Time spent on this map");
            UI::PopFont();
        }

        if (IS_DEV_MODE) {
            if (IsRunning || TimeLeft > 0) {
                if (IsPaused) UI::Text("Timer paused");
                else UI::Text("Timer running");
            } else UI::Text("Timer ended");
        }
    }

    void RenderGoalMedal() {
        UI::Image(Textures[RunConfig.GoalMedal], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(GoalMedalCount), Fonts::TimerFont);
    }

    void RenderBelowGoalMedal() {
        if (ModeHasBelowMedal) {
            UI::HPadding(25);
            UI::Image(Textures[RunConfig.GoalMedal - 1], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
            UI::SameLine();
            UI::AlignTextToImage(tostring(BelowMedalCount), Fonts::TimerFont);
        }
    }

    void RenderCurrentMap() {
        if (IsSwitchingMap && IsPaused) {
            UI::Separator();
            UI::AlignTextToFramePadding();
            UI::Text("Switching map...");
            UI::SameLine();

            if (UI::Button("Force switch")) {
                startnew(CoroutineFunc(SwitchMap));
            }
        } else if (IsInited && TM::IsMapLoaded()) {
            if (InCurrentMap()) {
                if (!PluginSettings::RMC_DisplayCurrentMap) {
                    return;
                }

                UI::Separator();

                if (currentMap !is null) {
                    UI::ScrollingText(currentMap.Name);

                    if (PluginSettings::RMC_ShowAwards) {
                        UI::SameLine();
                        UI::Text("\\$db4" + Icons::Trophy + "\\$z " + currentMap.AwardCount);
                    }

                    UI::TextDisabled("by " + currentMap.Username);

                    if (PluginSettings::RMC_DisplayMapDate) {
                        UI::TextDisabled(Time::FormatString("%F", currentMap.UpdatedAtTimestamp));
                    }

#if TMNEXT
                    if (PluginSettings::RMC_PrepatchTagsWarns && currentMap.IsPrepatch) {
                        PrepatchMapTag@ tag = currentMap.PrepatchTag;

                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z " + tag.title);
                        UI::SetItemTooltip(tag.reason + (IS_DEV_MODE ? ("\nExeBuild: " + currentMap.ExeBuild) : ""));
                    }

                    if (RunConfig.InvalidateGhosts && IsMapInvalidated) {
                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z Invalidated map");
                        UI::SetItemTooltip("You have watched a ghost on this map, you won't be able to get any remaining medals.\n\nYou will have to skip it or stop the run.");
                    }
#endif

                    if (PluginSettings::RMC_EditedMedalsWarns && RunConfig.CalculateMedals && currentMap.HasEditedMedals) {
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
                                if (tagsRender > 1 && i == tagsRender - 1) {
                                    float buttonWidth = UI::MeasureButton(currentMap.Tags[i].Name).x;

                                    if (buttonWidth >= UI::GetContentRegionAvail().x) {
                                        UI::NewLine();
                                    }
                                }

                                Render::MapTag(currentMap.Tags[i]);
                                UI::SameLine();
                            }

                            UI::NewLine();
                        }
                    }
                } else {
                    UI::TextDisabled("Map info unavailable");
                }
            } else {
                UI::Separator();
                UI::Text("\\$f30" + Icons::ExclamationTriangle + " \\$zLoaded map is not the one we got.");
                UI::Text("Please return to the correct map.");

                if (UI::Button("Return to map")) {
                    startnew(CoroutineFunc(ReturnToMap));
                }

                UI::SameLine();

                if (UI::Button("Force Switch")) {
                    startnew(CoroutineFunc(SwitchMap));
                }

                UI::SetItemTooltip("If returning to the map doesn't work, you can force switch instead.");
            }
        } else if (!IsStarting) {
            UI::Separator();

            if (UI::Button("Return to map")) {
                startnew(CoroutineFunc(ReturnToMap));
            }
        }
    }

    void RenderPlayingButtons() {
        if (InCurrentMap()) {
            PausePlayButton();
            UI::SameLine();
            SkipButtons();

            BrokenSkipButton();

            if (!PluginSettings::RMC_AutoSwitch && GotGoalMedal) {
                NextMapButton();
            }

            if (IS_DEV_MODE) {
                DevButtons();
            }
        }
    }

    void PausePlayButton() {
        UI::BeginDisabled(IsSwitchingMap || !IsRunning || IsMapInvalidated);

        if (UI::Button((IsPaused ? Icons::HourglassO + Icons::Play : Icons::AnimatedHourglass + Icons::Pause))) {
            IsPaused = !IsPaused;
        }

        UI::EndDisabled();
    }


    void SkipButtons() {
        UI::BeginDisabled(IsSwitchingMap);

        if (!GotBelowMedal) {
            int skipsLeft = Math::Max(0, RunConfig.FreeSkips - FreeSkipsUsed);

            UI::BeginDisabled(skipsLeft == 0);

            if (UI::FlexButton(Icons::PlayCircleO + "Free Skip (" + skipsLeft + " left)")) {
                FreeSkipsUsed++;
                CreateSave();
                Log::Trace("RMC: Skipping map");
                UI::ShowNotification("Please wait...");
                startnew(CoroutineFunc(SwitchMap));
            }

            UI::EndDisabled();

            UI::SetItemTooltip(
                "Free Skips are if the map is finishable but you still want to skip it for any reason.\n\n" +
                "Standard RMC rules allow 1 Free skip. If the map is broken, please use the button below instead."
            );
        } else if (ModeHasBelowMedal && UI::FlexButton(Icons::PlayCircleO + " Take " + tostring(Medals(RunConfig.GoalMedal - 1)) + " medal")) {
            BelowMedalCount++;
            Log::Trace("RMC: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        UI::EndDisabled();
    }

    void BrokenSkipButton() {
        UI::BeginDisabled(IsSwitchingMap);

        if (UI::OrangeButton(Icons::PlayCircleO + " Skip broken Map")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            IsPaused = true;
            UnpauseOnExit = false;
            Renderables::Add(BrokenMapSkipWarnModalDialog(this));
        }

        UI::EndDisabled();
    }

    void NextMapButton() {
        UI::BeginDisabled(IsSwitchingMap);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            Log::Trace("RMC: Next map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        UI::EndDisabled();
    }

    void DevButtons() {
        if (UI::RoseButton("-1min")) {
            TimeLeft = Math::Max(1*60*1000, TimeLeft - 1*60*1000);
        }

        UI::SameLine();

        if (UI::RoseButton("+1min")) {
            TimeLeft += (1*60*1000);
        }
    }

    void StartTimer() {
        IsRunning = true;

        if (GotBelowMedal && GotGoalMedal) GotBelowMedal = false;
        if (GotBelowMedal) GotBelowGoalMedalNotification();
        if (GotGoalMedal) GotGoalMedalNotification();

        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
        startnew(CoroutineFunc(PreloadNextMap));
    }

    void SubmitToLeaderboard() {
#if TMNEXT
        if (IsRunValid) {
            RMCLeaderAPI::postRMC(GoalMedalCount, BelowMedalCount, RunConfig);
        }
#endif
    }

    void GameEndNotification() {
        string notificationText = "You got " + GoalMedalCount + " " + tostring(RunConfig.GoalMedal);

        if (ModeHasBelowMedal && BelowMedalCount > 0) {
            notificationText += " and " + BelowMedalCount + " " + tostring(Medals(RunConfig.GoalMedal - 1));
        }
        notificationText += " medals!";

        UI::ShowNotification("\\$0f0" + ModeName + " ended!", notificationText);
    }

    void GotGoalMedalNotification() {
        Log::Trace("RMC: Got the " + tostring(RunConfig.GoalMedal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(RunConfig.GoalMedal) + " medal!", "We're searching for another map...");
            startnew(CoroutineFunc(SwitchMap));
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(RunConfig.GoalMedal) + " medal!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification() {
        Log::Trace("RMC: Got the " + tostring(Medals(RunConfig.GoalMedal - 1)) + " medal!");
        if (!GotBelowMedal)
            UI::ShowNotification(
                "\\$db4" + Icons::Trophy + " You got the " + tostring(Medals(RunConfig.GoalMedal - 1)) + " medal",
                "You can take the medal and skip the map"
            );
    }

    void TimerYield() {
        auto app = cast<CTrackMania>(GetApp());
        int lastUpdate = Time::Now;

        while (IsRunning) {
            yield();

            if (!IsPaused) {
                if (!InCurrentMap()) {
                    IsPaused = true;
                } else if (!IsRunning || TimeLeft == 0) {
                    IsRunning = false;
                    RMC::ShowTimer = false;

                    if (!UserEndedRun) {
                        GameEndNotification();
                        DataManager::RemoveCurrentSaveFile();  // run ended on time -> no point in saving it as it can't be continued
                        startnew(CoroutineFunc(SubmitToLeaderboard));
                    }

                    if (PluginSettings::RMC_ExitMapOnEndTime) {
                        app.BackToMainMenu();
                    }
                } else if (PluginSettings::RMC_PauseWhenMenuOpen && TM::IsPauseMenuDisplayed()) {
                    Log::Info("Pause menu opened, paused timer!", true);
                    IsPaused = true;
                    UnpauseOnExit = true;
                } else {
                    int delta = Time::Now - lastUpdate;
                    TimeLeft -= delta;
                    TotalTime += delta;
                    TimeSpentMap += delta;
                }
            } else if (UnpauseOnExit && !TM::IsPauseMenuDisplayed()) {
                Log::Info("Pause menu closed, resuming timer!", true);
                UnpauseOnExit = false;
                IsPaused = false;
            }

            lastUpdate = Time::Now;
        }
    }

    uint get_GoalTime() {
        if (InCurrentMap()) {
            if (RunConfig.CalculateMedals && currentMap.IsMedalEdited(RunConfig.GoalMedal)) {
                return currentMap.GetDefaultMedalTime(RunConfig.GoalMedal);
            }

            return currentMap.GetMedalTime(RunConfig.GoalMedal);
        }

        return uint(-1);
    }

    uint get_BelowGoalTime() {
        if (ModeHasBelowMedal && InCurrentMap()) {
            Medals belowMedal = Medals(RunConfig.GoalMedal - 1);

            if (RunConfig.CalculateMedals && currentMap.IsMedalEdited(belowMedal)) {
                return currentMap.GetDefaultMedalTime(belowMedal);
            }

            return currentMap.GetMedalTime(belowMedal);
        }

        return uint(-1);
    }

    void PbLoop() {
        while (IsRunning) {
            yield();

            if (!GotGoalMedal && !IsMapInvalidated) {
#if TMNEXT
                if (RunConfig.InvalidateGhosts && TM::IsWatchingOtherGhost()) {
                    IsPaused = true;
                    IsMapInvalidated = true;
                    Log::Warn("You can't watch ghosts while in a run! Map has been invalidated, you will have to skip it or stop the run.", true);
                    continue;
                }
#endif
                if (!IsPaused) {
                    uint score = TM::GetFinishScore();
                    bool inverse = TM::CurrentMapType() == MapTypes::Stunt;

                    if (score == uint(-1)) {
                        sleep(50);
                        continue;
                    }

                    if (RunConfig.UseNoRespawnTime && TM::CurrentMapType() == MapTypes::Race) {
                        uint noRespawnTime = TM::GetNoRespawnTime();

                        if (noRespawnTime != uint(-1)) {
                            score = Math::Min(score, TM::GetNoRespawnTime());
                        }
                    }

                    if ((!inverse && score <= GoalTime) || (inverse && score >= GoalTime)) {
                        GoalMedalCount++;
                        GotGoalMedalNotification();
                        GotGoalMedal = true;
                        CreateSave();
                    } else if (ModeHasBelowMedal && !GotBelowMedal && ((!inverse && score <= BelowGoalTime) || (inverse && score >= BelowGoalTime))) {
                        GotBelowGoalMedalNotification();
                        GotBelowMedal = true;
                        CreateSave();
                    }

                    if (PBOnMap == -1 || (!inverse && int(score) < PBOnMap) || (inverse && int(score) > PBOnMap)) {
                        // PB
                        PBOnMap = score;
                        CreateSave();
                    }
                }

                sleep(1000);
            }
        }
    }

    void PreloadNextMap() {
        Log::Trace("[PreloadNextMap] Preloading a new map.");

        while (IsStarting || IsRunning) {
            @nextMap = MX::GetRandomMap(RunConfig.CustomSearchFilters);

            if (nextMap !is null) {
                if (RunConfig.SkipDuplicateMaps) {
                    if (playedMaps.Find(nextMap) != -1) {
                        Log::Trace("Map has been played already, skipping...");
                        sleep(2000);
                        continue;
                    }
                }

                break;
            }

            sleep(2000);
        }

        Log::Trace("[PreloadNextMap] Preloaded " + nextMap.toString());
    }

    void SwitchMap() {
        UnpauseOnExit = false;
        IsPaused = true;
        IsSwitchingMap = true;

        yield(150);

        if (nextMap is null) {
            // Shouldn't happen normally
            Log::Trace("[SwitchMap] Next map is null, preloading a new one.");
            PreloadNextMap();
        }

        Log::Trace("[SwitchMap] Switching map to " + nextMap.toString());

        Log::LoadingMapNotification(nextMap);
        DataManager::SaveMapToRecentlyPlayed(nextMap);
        await(startnew(TM::LoadMap, nextMap));

        @currentMap = nextMap;
        playedMaps.InsertLast(currentMap);
        startnew(CoroutineFunc(PreloadNextMap));

        Log::Trace("[SwitchMap] Waiting for map to be loaded.");

        while (!TM::IsMapLoaded()) {
            sleep(100);
        }

        Log::Trace("[SwitchMap] Map is loaded!");

        IsSwitchingMap = false;
        GotGoalMedal = false;
        GotBelowMedal = false;
        TimeSpentMap = 0;
        PBOnMap = -1;
        IsMapInvalidated = false;

        Log::Trace("[SwitchMap] Waiting for player to be ready.");

        while (!TM::IsPlayerReady()) {
            yield();
        }

        Log::Trace("[SwitchMap] Player is ready, unpausing timer.");

        IsPaused = false;
    }
}