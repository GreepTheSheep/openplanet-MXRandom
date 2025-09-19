class RMC {
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
    array<string> seenMaps;
    int TimeSpentMap = -1;
    int PBOnMap = -1; // for autosaves on PBs

    // Timer
    int _TimeLeft = TimeLimit;
    int _TotalTime = 0;

    bool ContinueSavedRun = false;
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

    RMC::GameMode get_GameMode() {
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
    }

    void CheckSave() {
        if (!DataManager::LoadRunData()) {
            DataManager::CreateSaveFile();
            return;
        }

        auto saveDialog = ContinueSavedRunModalDialog(this);
        Renderables::Add(saveDialog);

        while (!saveDialog.HasCompletedCheckbox) {
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

        if (!ContinueSavedRun) {
            MX::LoadRandomMap();
        }

        while (!TM::IsMapLoaded() || !TM::IsPlayerReady()) {
            yield();
        }

        @currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
        StartTimer();

        UI::ShowNotification("\\$080" + ModeName + " started!", "Good Luck!");
        IsInited = true;

        // Clear the currently saved data so you cannot load into the same state multiple times
        DataManager::RemoveCurrentSaveFile();
        DataManager::CreateSaveFile();
        IsStarting = false;
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

        DataManager::SaveCurrentRunData();
    }

    int get_TimeLimit() { return PluginSettings::RMC_Duration * 60 * 1000; }

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

    bool get_RenderButtons() {
        return PluginSettings::RMC_AlwaysShowBtns || UI::IsOverlayShown();
    }

    void Render() {
        string lastLetter = tostring(this.GameMode).SubStr(0,1);
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

            UI::Separator();
        }

        RenderTimer();
        if (IS_DEV_MODE) UI::Text(RMC::FormatTimer(TotalTime));
        UI::Separator();
        RenderGoalMedal();
        RenderBelowGoalMedal();

        if (PluginSettings::RMC_DisplayPace) {
            RenderPace();
        }

        if (PluginSettings::RMC_DisplayCurrentMap) {
            RenderCurrentMap();
        }

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

    void RenderCustomSearchWarning() {
        if ((IsRunning || IsStarting) && PluginSettings::CustomRules) {
            UI::Separator();
            UI::Text("\\$fc0" + Icons::ExclamationTriangle + " \\$zInvalid for official leaderboards");
            UI::SetPreviousTooltip("This run has custom search parameters enabled, you will only get maps based on the settings you configured.\n\nTo change this, toggle \"Use custom filter parameters\" in the \"Filters\" tab in the settings.");
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
            UI::SetPreviousTooltip("Time spent on this map");
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
        UI::Image(Textures[PluginSettings::RMC_Medal], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(GoalMedalCount), Fonts::TimerFont);
    }

    void RenderBelowGoalMedal() {
        if (PluginSettings::RMC_Medal != Medals::Bronze) {
            UI::HPadding(25);
            UI::Image(Textures[PluginSettings::RMC_Medal - 1], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
            UI::SameLine();
            UI::AlignTextToImage(tostring(BelowMedalCount), Fonts::TimerFont);
        }
    }

    void RenderCurrentMap() {
        if (IsSwitchingMap) {
            UI::Separator();
            if (IsPaused) {
                UI::AlignTextToFramePadding();
                UI::Text("Switching map...");
                UI::SameLine();
                if (UI::Button("Force switch")) {
                    startnew(CoroutineFunc(SwitchMap));
                }
            }
            else IsPaused = true;
        } else if (IsInited && TM::IsMapLoaded()) {
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

#if TMNEXT
                    if (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.HasPrepatchTags(currentMap)) {
                        RMCConfigMapTag@ tag = RMC::config.GetPrepatchTag(currentMap);
                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z" + tag.title);
                        UI::SetPreviousTooltip(tag.reason + (IS_DEV_MODE ? ("\nExeBuild: " + currentMap.ExeBuild) : ""));
                    }
#endif

                    if (PluginSettings::RMC_EditedMedalsWarns && TM::HasEditedMedals()) {
                        UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z Edited Medals");
                        UI::SetPreviousTooltip("The map has medal times that differ from the default.\n\nYou can broken skip it if preferred.");
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
            } else {
                UI::Separator();
                UI::Text("\\$f30" + Icons::ExclamationTriangle + " \\$zLoaded map is not the one we got.");
                UI::Text("Please change the map.");
                if (UI::Button("Change map")) {
                    startnew(CoroutineFunc(SwitchMap));
                }
            }
        } else if (!IsStarting) {
            UI::Separator();

            if (UI::Button("Return to map")) {
                UI::ShowNotification("Returning to current map...");
                startnew(TM::LoadMap, currentMap);
            }
        }
    }

    void RenderPlayingButtons() {
        if (InCurrentMap()) {
            PausePlayButton();
            UI::SameLine();
            SkipButtons();
            if (!PluginSettings::RMC_AutoSwitch && GotGoalMedal) {
                NextMapButton();
            }

            if (IS_DEV_MODE) {
                DevButtons();
            }
        }
    }

    void PausePlayButton() {
        UI::BeginDisabled(IsSwitchingMap || !IsRunning);

        if (UI::Button((IsPaused ? Icons::HourglassO + Icons::Play : Icons::AnimatedHourglass + Icons::Pause))) {
            IsPaused = !IsPaused;
        }

        UI::EndDisabled();
    }


    void SkipButtons() {
        Medals BelowMedal = PluginSettings::RMC_Medal;
        if (BelowMedal != Medals::Bronze) BelowMedal = Medals(BelowMedal - 1);

        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || IsSwitchingMap);
        if (PluginSettings::RMC_FreeSkipAmount > FreeSkipsUsed) {
            int skipsLeft = PluginSettings::RMC_FreeSkipAmount - FreeSkipsUsed;
            if (UI::Button(Icons::PlayCircleO + (GotBelowMedal ? " Take " + tostring(BelowMedal) + " medal" : "Free Skip (" + skipsLeft + " left)"))) {
                if (IsPaused) IsPaused = false;
                if (GotBelowMedal) {
                    BelowMedalCount++;
                } else {
                    FreeSkipsUsed++;
                    RMC::CurrentRunData["FreeSkipsUsed"] = FreeSkipsUsed;
                    DataManager::SaveCurrentRunData();
                }
                Log::Trace("RMC: Skipping map");
                UI::ShowNotification("Please wait...");
                startnew(CoroutineFunc(SwitchMap));
            }
        } else if (GotBelowMedal) {
            if (UI::Button(Icons::PlayCircleO + " Take " + tostring(BelowMedal) + " medal")) {
                if (IsPaused) IsPaused = false;
                BelowMedalCount++;
                Log::Trace("RMC: Skipping map");
                UI::ShowNotification("Please wait...");
                startnew(CoroutineFunc(SwitchMap));
            }
        } else {
            UI::NewLine();
        }
        if (!GotBelowMedal) UI::SetPreviousTooltip(
            "Free Skips are if the map is finishable but you still want to skip it for any reason.\n" +
            "Standard RMC rules allow 1 Free skip. If the map is broken, please use the button below instead."
        );

        if (UI::OrangeButton(Icons::PlayCircleO + "Skip broken Map")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            IsPaused = true;
            Renderables::Add(BrokenMapSkipWarnModalDialog(this));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");
        UI::EndDisabled();
    }

    void NextMapButton() {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || IsSwitchingMap);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            if (IsPaused) IsPaused = false;
            Log::Trace("RMC: Next map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To move to the next map, please exit the pause menu.");

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

    void GameEndNotification() {
        string notificationText = "You got " + GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal);

        if (PluginSettings::RMC_Medal != Medals::Bronze && BelowMedalCount > 0) {
            notificationText += " and " + BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1));
        }
        notificationText += " medals!";

        UI::ShowNotification("\\$0f0" + ModeName + " ended!", notificationText);

#if TMNEXT
        if (this.GameMode == RMC::GameMode::Challenge) {
            RMCLeaderAPI::postRMC(GoalMedalCount, BelowMedalCount, PluginSettings::RMC_Medal);
        }
#endif
    }

    void GotGoalMedalNotification() {
        Log::Trace("RMC: Got the " + tostring(PluginSettings::RMC_Medal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
            startnew(CoroutineFunc(SwitchMap));
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification() {
        Log::Trace("RMC: Got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal!");
        if (!GotBelowMedal)
            UI::ShowNotification(
                "\\$db4" + Icons::Trophy + " You got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal",
                "You can take the medal and skip the map"
            );
    }

    void TimerYield() {
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
                    }

                    if (PluginSettings::RMC_ExitMapOnEndTime) {
                        CTrackMania@ app = cast<CTrackMania>(GetApp());
                        app.BackToMainMenu();
                    }
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

    uint get_GoalTime() {
        if (InCurrentMap()) {
            auto app = cast<CTrackMania>(GetApp());
            auto map = app.RootMap;

            switch (PluginSettings::RMC_Medal) {
#if TMNEXT
                case Medals::WR: return TM::GetWorldRecordFromCache(map.IdName);
#endif
                case Medals::Author: return map.TMObjective_AuthorTime;
                case Medals::Gold: return map.TMObjective_GoldTime;
                case Medals::Silver: return map.TMObjective_SilverTime;
                case Medals::Bronze: return map.TMObjective_BronzeTime;
                default: return uint(-1);
            }
        }

        return uint(-1);
    }

    uint get_BelowGoalTime() {
        if (InCurrentMap()) {
            auto app = cast<CTrackMania>(GetApp());
            auto map = app.RootMap;

            switch (PluginSettings::RMC_Medal - 1) {
                case Medals::Author: return map.TMObjective_AuthorTime;
                case Medals::Gold: return map.TMObjective_GoldTime;
                case Medals::Silver: return map.TMObjective_SilverTime;
                case Medals::Bronze: return map.TMObjective_BronzeTime;
                default: return uint(-1);
            }
        }

        return uint(-1);
    }

    void PbLoop() {
        while (IsRunning) {
            yield();

            if (!IsPaused && !GotGoalMedal) {
                uint score = TM::GetFinishScore();
                bool inverse = TM::CurrentMapType() == MapTypes::Stunt;

                if (score == uint(-1)) {
                    sleep(50);
                    continue;
                }

                if ((!inverse && score <= GoalTime) || (inverse && score >= GoalTime)) {
                    GoalMedalCount++;
                    GotGoalMedalNotification();
                    GotGoalMedal = true;
                    CreateSave();
                } else if (!GotBelowMedal && PluginSettings::RMC_Medal != Medals::Bronze && ((!inverse && score <= BelowGoalTime) || (inverse && score >= BelowGoalTime))) {
                    GotBelowGoalMedalNotification();
                    GotBelowMedal = true;
                    CreateSave();
                }

                if (PBOnMap == -1 || (!inverse && int(score) < PBOnMap) || (inverse && int(score) > PBOnMap)) {
                    // PB
                    PBOnMap = score;
                    CreateSave();
                }

                sleep(1000);
            }
        }
    }

    void PreloadNextMap() {
        while (IsStarting || IsRunning) {
            @nextMap = MX::GetRandomMap();

            if (nextMap !is null) {
                if (PluginSettings::SkipSeenMaps) {
                    if (seenMaps.Find(nextMap.MapUid) != -1) {
                        Log::Trace("Map has been played already, skipping...");
                        sleep(2000);
                        continue;
                    }

                    seenMaps.InsertLast(nextMap.MapUid);
                }

                break;
            }

            sleep(2000);
        }
    }

    void SwitchMap() {
        IsPaused = true;
        IsSwitchingMap = true;

        yield(100);

        Log::LoadingMapNotification(nextMap);
        DataManager::SaveMapToRecentlyPlayed(nextMap);
        await(startnew(TM::LoadMap, nextMap));

        @currentMap = nextMap;

        while (!TM::IsMapLoaded()) {
            sleep(100);
        }

        IsSwitchingMap = false;
        GotGoalMedal = false;
        GotBelowMedal = false;
        TimeSpentMap = 0;
        PBOnMap = -1;

        while (!TM::IsPlayerReady()) {
            yield();
        }

        IsPaused = false;

        PreloadNextMap();
    }
}