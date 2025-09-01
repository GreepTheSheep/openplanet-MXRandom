class RMC {
    int BelowMedalCount = 0;
    int _TimeLeft = TimeLimit;
    int _TotalTime = 0;
    MX::MapInfo@ currentMap;
    MX::MapInfo@ nextMap;
    array<string> seenMaps;

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
        if (RMC::currentGameMode == RMC::GameMode::ChallengeChaos) {
            return "Random Map Chaos Challenge";
        }

        return "Random Map Challenge";
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

    void Render() {
        string lastLetter = tostring(RMC::currentGameMode).SubStr(0,1);
        if (RMC::IsRunning && (UI::IsOverlayShown() || PluginSettings::RMC_AlwaysShowBtns)) {
            if (UI::RedButton(Icons::Times + " Stop RM" + lastLetter)) {
                RMC::UserEndedRun = true;
                RMC::IsRunning = false;
                RMC::ShowTimer = false;
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCMode(false);
#endif
                int secondaryCount = RMC::currentGameMode == RMC::GameMode::Challenge ? BelowMedalCount : RMC::Survival.Skips;
                if (RMC::GoalMedalCount != 0 || secondaryCount != 0 || RMC::GotBelowMedal || RMC::GotGoalMedal) {
                    if (!PluginSettings::RMC_RUN_AUTOSAVE) {
                        Renderables::Add(SaveRunQuestionModalDialog());
                    } else {
                        RMC::CreateSave();
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
            try {
                float goalPace = ((TimeLimit / 60 / 1000) * RMC::GoalMedalCount / (TotalTime / 60 / 100));
                UI::Text("Pace: " + goalPace);
            } catch {
                UI::Text("Pace: 0");
            }
        }

        if (PluginSettings::RMC_DisplayCurrentMap) {
            RenderCurrentMap();
        }

#if TMNEXT
        RenderCustomSearchWarning();
#endif

        if (RMC::IsRunning && (UI::IsOverlayShown() || PluginSettings::RMC_AlwaysShowBtns)) {
            UI::Separator();
            RenderPlayingButtons();
        }
    }

    void RenderCustomSearchWarning() {
        if ((RMC::IsRunning || RMC::IsStarting) && PluginSettings::CustomRules) {
            UI::Separator();
            UI::Text("\\$fc0" + Icons::ExclamationTriangle + " \\$zInvalid for official leaderboards ");
            UI::SetPreviousTooltip("This run has custom search parameters enabled, meaning that you only get maps after the settings you configured. \nTo change this, toggle the \"Use these parameters in RMC\" under the \"Searching\" settings");
        }
    }

    void RenderTimer() {
        UI::PushFont(Fonts::TimerFont);
        if (RMC::IsRunning) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(TimeLeft));
            else UI::Text(RMC::FormatTimer(TimeLeft));
        } else {
            UI::TextDisabled(RMC::FormatTimer(TimeLimit));
        }
        UI::PopFont();
        UI::Dummy(vec2(0, 8));
        if (PluginSettings::RMC_DisplayMapTimeSpent) {
            UI::PushFont(Fonts::HeaderSub);
            UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
            UI::SetPreviousTooltip("Time spent on this map");
            UI::PopFont();
        }
        if (IS_DEV_MODE) {
            if (RMC::IsRunning || TimeLeft > 0) {
                if (RMC::IsPaused) UI::Text("Timer paused");
                else UI::Text("Timer running");
            } else UI::Text("Timer ended");
        }
    }

    void RenderGoalMedal() {
        UI::Image(Textures[PluginSettings::RMC_Medal], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(RMC::GoalMedalCount), Fonts::TimerFont);
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
        if (RMC::IsSwitchingMap) {
            UI::Separator();
            if (RMC::IsPaused) {
                UI::AlignTextToFramePadding();
                UI::Text("Switching map...");
                UI::SameLine();
                if (UI::Button("Force switch")) {
                    startnew(CoroutineFunc(SwitchMap));
                }
            }
            else RMC::IsPaused = true;
        } else if (RMC::IsInited && TM::IsMapLoaded()) {
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
        } else if (!RMC::IsStarting) {
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
            if (!PluginSettings::RMC_AutoSwitch && RMC::GotGoalMedal) {
                NextMapButton();
            }

            if (IS_DEV_MODE) {
                DevButtons();
            }
        }
    }

    void PausePlayButton() {
        if (UI::Button((RMC::IsPaused ? Icons::HourglassO + Icons::Play : Icons::AnimatedHourglass + Icons::Pause))) {
            RMC::IsPaused = !RMC::IsPaused;
        }
    }


    void SkipButtons() {
        Medals BelowMedal = PluginSettings::RMC_Medal;
        if (BelowMedal != Medals::Bronze) BelowMedal = Medals(BelowMedal - 1);

        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::IsSwitchingMap);
        if (PluginSettings::RMC_FreeSkipAmount > RMC::FreeSkipsUsed) {
            int skipsLeft = PluginSettings::RMC_FreeSkipAmount - RMC::FreeSkipsUsed;
            if (UI::Button(Icons::PlayCircleO + (RMC::GotBelowMedal ? " Take " + tostring(BelowMedal) + " medal" : "Free Skip (" + skipsLeft + " left)"))) {
                if (RMC::IsPaused) RMC::IsPaused = false;
                if (RMC::GotBelowMedal) {
                    BelowMedalCount++;
                } else {
                    RMC::FreeSkipsUsed++;
                    RMC::CurrentRunData["FreeSkipsUsed"] = RMC::FreeSkipsUsed;
                    DataManager::SaveCurrentRunData();
                }
                Log::Trace("RMC: Skipping map");
                UI::ShowNotification("Please wait...");
                startnew(CoroutineFunc(SwitchMap));
            }
        } else if (RMC::GotBelowMedal) {
            if (UI::Button(Icons::PlayCircleO + " Take " + tostring(BelowMedal) + " medal")) {
                if (RMC::IsPaused) RMC::IsPaused = false;
                BelowMedalCount++;
                Log::Trace("RMC: Skipping map");
                UI::ShowNotification("Please wait...");
                startnew(CoroutineFunc(SwitchMap));
            }
        } else {
            UI::NewLine();
        }
        if (!RMC::GotBelowMedal) UI::SetPreviousTooltip(
            "Free Skips are if the map is finishable but you still want to skip it for any reason.\n" +
            "Standard RMC rules allow 1 Free skip. If the map is broken, please use the button below instead."
        );

        if (UI::OrangeButton(Icons::PlayCircleO + "Skip broken Map")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            RMC::IsPaused = true;
            Renderables::Add(BrokenMapSkipWarnModalDialog(this));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");
        UI::EndDisabled();
    }

    void NextMapButton() {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::IsSwitchingMap);

        if (UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMC: Next map");
            UI::ShowNotification("Please wait...");
            startnew(CoroutineFunc(SwitchMap));
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To move to the next map, please exit the pause menu.");

        UI::EndDisabled();
    }

    void DevButtons() {
        if (UI::RoseButton("+1min")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            TimeLeft += (1*60*1000);
        }
        UI::SameLine();
        if (UI::RoseButton("-1min")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            TimeLeft = Math::Max(1*60*1000, TimeLeft - 1*60*1000);
        }
    }

    void StartTimer() {
        if (RMC::ContinueSavedRun) {
            TimeLeft = int(RMC::CurrentRunData["TimeLeft"]);
            TotalTime = int(RMC::CurrentRunData["TotalTime"]);
        }

        RMC::IsPaused = false;
        RMC::IsRunning = true;
        if (RMC::GotBelowMedal && RMC::GotGoalMedal) RMC::GotBelowMedal = false;
        if (RMC::GotBelowMedal) GotBelowGoalMedalNotification();
        if (RMC::GotGoalMedal) GotGoalMedalNotification();
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
        startnew(CoroutineFunc(PreloadNextMap));
    }

    void GameEndNotification() {
        string notificationText = "You got " + RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal);

        if (PluginSettings::RMC_Medal != Medals::Bronze && BelowMedalCount > 0) {
            notificationText += " and " + BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1));
        }
        notificationText += " medals!";

        UI::ShowNotification("\\$0f0" + ModeName + " ended!", notificationText);

#if TMNEXT
        if (RMC::currentGameMode == RMC::GameMode::Challenge) {
            RMCLeaderAPI::postRMC(RMC::GoalMedalCount, BelowMedalCount, PluginSettings::RMC_Medal);
        }
#if DEPENDENCY_CHAOSMODE
        else if (RMC::currentGameMode == RMC::GameMode::ChallengeChaos) {
            ChaosMode::SetRMCMode(false);
        }
#endif
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
        if (!RMC::GotBelowMedal)
            UI::ShowNotification(
                "\\$db4" + Icons::Trophy + " You got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal",
                "You can take the medal and skip the map"
            );
    }

    void TimerYield() {
        int lastUpdate = Time::Now;

        while (RMC::IsRunning) {
            yield();

#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(RMC::IsPaused);
#endif

            if (!RMC::IsPaused) {
                if (!InCurrentMap()) {
                    RMC::IsPaused = true;
                } else if (!RMC::IsRunning || TimeLeft == 0) {
                    RMC::IsRunning = false;
                    RMC::ShowTimer = false;

                    if (!RMC::UserEndedRun) {
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
                    RMC::TimeSpentMap += delta;
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
        while (RMC::IsRunning) {
            yield();

            if (!RMC::IsPaused && !RMC::GotGoalMedal) {
                uint score = TM::GetFinishScore();
                bool inverse = TM::CurrentMapType() == MapTypes::Stunt;

                if (score == uint(-1)) {
                    sleep(50);
                    continue;
                }

                if ((!inverse && score <= GoalTime) || (inverse && score >= GoalTime)) {
                    RMC::GoalMedalCount++;
                    GotGoalMedalNotification();
                    RMC::GotGoalMedal = true;
                    RMC::CreateSave();
                } else if (!RMC::GotBelowMedal && PluginSettings::RMC_Medal != Medals::Bronze && ((!inverse && score <= BelowGoalTime) || (inverse && score >= BelowGoalTime))) {
                    GotBelowGoalMedalNotification();
                    RMC::GotBelowMedal = true;
                    RMC::CreateSave();
                }

                if (RMC::PBOnMap == -1 || (!inverse && int(score) < RMC::PBOnMap) || (inverse && int(score) > RMC::PBOnMap)) {
                    // PB
                    RMC::PBOnMap = score;
                    RMC::CreateSave();
                }

                sleep(1000);
            }
        }
    }

    void PreloadNextMap() {
        while (RMC::IsStarting || RMC::IsRunning) {
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
        RMC::IsPaused = true;
        RMC::IsSwitchingMap = true;

        yield(100);

        Log::LoadingMapNotification(nextMap);
        DataManager::SaveMapToRecentlyPlayed(nextMap);
        await(startnew(TM::LoadMap, nextMap));

        @currentMap = nextMap;

        while (!TM::IsMapLoaded()) {
            sleep(100);
        }

        RMC::IsSwitchingMap = false;
        RMC::GotGoalMedal = false;
        RMC::GotBelowMedal = false;
        RMC::TimeSpentMap = 0;
        RMC::PBOnMap = -1;

        while (!TM::IsPlayerReady()) {
            yield();
        }

        RMC::IsPaused = false;

        PreloadNextMap();
    }
}