class RMC
{
    int BelowMedalCount = 0;
    int ModeStartTimestamp = -1;

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

    RMC()
    {
        print(GetModeName() + " loaded");
    }

    string GetModeName() { return "Random Map Challenge";}

    int TimeLimit() { return PluginSettings::RMC_Duration * 60 * 1000; }

    string IsoDateToDMY(const string &in isoDate)
    {
        string year = isoDate.SubStr(0, 4);
        string month = isoDate.SubStr(5, 2);
        string day = isoDate.SubStr(8, 2);
        return day + "-" + month + "-" + year;
    }

    void Render()
    {
        string lastLetter = tostring(RMC::currentGameMode).SubStr(0,1);
        if (RMC::IsRunning && (UI::IsOverlayShown() || PluginSettings::RMC_AlwaysShowBtns)) {
            if (UI::RedButton(Icons::Times + " Stop RM"+lastLetter))
            {
                RMC::UserEndedRun = true;
                RMC::EndTimeCopyForSaveData = RMC::EndTime;
                RMC::StartTimeCopyForSaveData = RMC::StartTime;
                RMC::IsRunning = false;
                RMC::ShowTimer = false;
                RMC::StartTime = -1;
                RMC::EndTime = -1;
                @MX::preloadedMap = null;

#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCMode(false);
#endif
                int secondaryCount = RMC::currentGameMode == RMC::GameMode::Challenge ? BelowMedalCount : RMC::Survival.Skips;
                if (RMC::GoalMedalCount != 0 || secondaryCount != 0 || RMC::GotBelowMedal || RMC::GotGoalMedal) {
                    if (!PluginSettings::RMC_RUN_AUTOSAVE) {
                        Renderables::Add(SaveRunQuestionModalDialog());
                        // sleeping here to wait for the dialog to be closed crashes the plugin, hence we just have a copy
                        // of the timers to use for the save file
                    } else {
                        RMC::CreateSave(true);
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
        if (IS_DEV_MODE) UI::Text(RMC::FormatTimer(RMC::StartTime - ModeStartTimestamp));
        UI::Separator();
        RenderGoalMedal();
        RenderBelowGoalMedal();

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
            UI::Text("\\$fc0"+ Icons::ExclamationTriangle + " \\$zInvalid for official leaderboards ");
            UI::SetPreviousTooltip("This run has custom search parameters enabled, meaning that you only get maps after the settings you configured. \nTo change this, toggle the \"Use these parameters in RMC\" under the \"Searching\" settings");
        }
    }

    void RenderTimer()
    {
        UI::PushFont(Fonts::TimerFont);
        if (RMC::IsRunning || RMC::EndTime > 0) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));
            else UI::Text(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));
        } else {
            UI::TextDisabled(RMC::FormatTimer(TimeLimit()));
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
            if (RMC::IsRunning || RMC::EndTime > 0) {
                if (RMC::IsPaused) UI::Text("Timer paused");
                else UI::Text("Timer running");
            } else UI::Text("Timer ended");
        }
    }

    void RenderGoalMedal()
    {
        UI::Image(Textures[PluginSettings::RMC_Medal], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
        UI::SameLine();
        UI::AlignTextToImage(tostring(RMC::GoalMedalCount), Fonts::TimerFont);
    }

    void RenderBelowGoalMedal()
    {
        if (PluginSettings::RMC_Medal != Medals::Bronze) {
            UI::HPadding(25);
            UI::Image(Textures[PluginSettings::RMC_Medal - 1], vec2(PluginSettings::RMC_ImageSize * 2 * UI::GetScale()));
            UI::SameLine();
            UI::AlignTextToImage(tostring(BelowMedalCount), Fonts::TimerFont);
        }
    }

    void RenderCurrentMap()
    {
        if (RMC::isSwitchingMap) {
            UI::Separator();
            if (RMC::IsPaused) {
                UI::AlignTextToFramePadding();
                UI::Text("Switching map...");
                UI::SameLine();
                if (UI::Button("Force switch")) startnew(RMC::SwitchMap);
            }
            else RMC::IsPaused = true;
        } else if (RMC::IsInited && TM::IsMapLoaded()) {
            if (TM::InRMCMap()) {
                UI::Separator();
                MX::MapInfo@ currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);

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
                    UI::Separator();
                    UI::TextDisabled("Map info unavailable");
                }
            } else {
                UI::Separator();
                UI::Text("\\$f30" + Icons::ExclamationTriangle + " \\$zActual map is not the same that we got.");
                UI::Text("Please change the map.");
                if (UI::Button("Change map")) startnew(RMC::SwitchMap);
            }
        } else if (!RMC::IsStarting) {
            UI::Separator();

            if (UI::Button("Return to map")) {
                UI::ShowNotification("Returning to current map...");
                TM::LoadRMCMap();
            }
        }
    }

    void RenderPlayingButtons()
    {
        if (TM::InRMCMap()) {
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

    void PausePlayButton()
    {
        if (UI::Button((RMC::IsPaused ? Icons::HourglassO + Icons::Play : Icons::AnimatedHourglass + Icons::Pause))) {
            if (RMC::IsPaused) RMC::EndTime = RMC::EndTime + (Time::Now - RMC::StartTime);
            RMC::IsPaused = !RMC::IsPaused;
        }
    }


    void SkipButtons()
    {
        Medals BelowMedal = PluginSettings::RMC_Medal;
        if (BelowMedal != Medals::Bronze) BelowMedal = Medals(BelowMedal - 1);

        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::ClickedOnSkip);
        if (PluginSettings::RMC_FreeSkipAmount > RMC::FreeSkipsUsed){
            int skipsLeft = PluginSettings::RMC_FreeSkipAmount - RMC::FreeSkipsUsed;
            if(UI::Button(Icons::PlayCircleO + (RMC::GotBelowMedal ? " Take " + tostring(BelowMedal) + " medal" : "Free Skip (" + skipsLeft + " left)"))) {
                RMC::ClickedOnSkip = true;
                if (RMC::IsPaused) RMC::IsPaused = false;
                if (RMC::GotBelowMedal) {
                    BelowMedalCount += 1;
                } else {
                    RMC::FreeSkipsUsed += 1;
                    RMC::CurrentRunData["FreeSkipsUsed"] = RMC::FreeSkipsUsed;
                    DataManager::SaveCurrentRunData();
                }
                Log::Trace("RMC: Skipping map");
                UI::ShowNotification("Please wait...");
                startnew(RMC::SwitchMap);
            }
        } else if (RMC::GotBelowMedal) {
            if (UI::Button(Icons::PlayCircleO + " Take " + tostring(BelowMedal) + " medal")) {
                RMC::ClickedOnSkip = true;
                if (RMC::IsPaused) RMC::IsPaused = false;
                BelowMedalCount += 1;
                Log::Trace("RMC: Skipping map");
                UI::ShowNotification("Please wait...");
                startnew(RMC::SwitchMap);
            }
        } else {
            UI::NewLine();
        }
        if (!RMC::GotBelowMedal) UI::SetPreviousTooltip(
            "Free Skips are if the map is finishable but you still want to skip it for any reason.\n"+
            "Standard RMC rules allow 1 Free skip. If the map is broken, please use the button below instead."
        );

        if (UI::OrangeButton(Icons::PlayCircleO + "Skip broken Map")) {
            if (!UI::IsOverlayShown()) UI::ShowOverlay();
            RMC::IsPaused = true;
            Renderables::Add(BrokenMapSkipWarnModalDialog());
        }

        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");
        UI::EndDisabled();
    }

    void NextMapButton()
    {
        UI::BeginDisabled(TM::IsPauseMenuDisplayed() || RMC::ClickedOnSkip);
        if(UI::GreenButton(Icons::Play + " Next map")) {
            RMC::ClickedOnSkip = true;
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMC: Next map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
        if (TM::IsPauseMenuDisplayed()) UI::SetPreviousTooltip("To skip the map, please exit the pause menu.");
        UI::EndDisabled();
    }

    void DevButtons()
    {
        if (UI::RoseButton("+1min")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            RMC::EndTime += (1*60*1000);
        }
        UI::SameLine();
        if (UI::RoseButton("-1min")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            RMC::EndTime -= (1*60*1000);

            if ((RMC::EndTime - RMC::StartTime) < (1*60*1000)) RMC::EndTime = RMC::StartTime + (1*60*1000);
        }
    }

    void StartTimer()
    {
        RMC::StartTime = Time::Now;
        RMC::EndTime = !RMC::ContinueSavedRun ? RMC::StartTime + TimeLimit() : RMC::StartTime + int(RMC::CurrentRunData["TimerRemaining"]);
        if (RMC::ContinueSavedRun) {
            ModeStartTimestamp = RMC::StartTime - (Time::Now - int(RMC::CurrentRunData["CurrentRunTime"]));

        } else {
            ModeStartTimestamp = Time::Now;
        }
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        if (RMC::GotBelowMedal && RMC::GotGoalMedal) RMC::GotBelowMedal = false;
        if (RMC::GotBelowMedal) GotBelowGoalMedalNotification();
        if (RMC::GotGoalMedal) GotGoalMedalNotification();
        startnew(CoroutineFunc(TimerYield));
        startnew(CoroutineFunc(PbLoop));
    }

    void GameEndNotification()
    {
        if (RMC::currentGameMode == RMC::GameMode::Challenge) {
#if TMNEXT
            RMCLeaderAPI::postRMC(RMC::GoalMedalCount, BelowMedalCount, PluginSettings::RMC_Medal);
#endif
            UI::ShowNotification(
                "\\$0f0Random Map Challenge ended!",
                "You got " + RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal) +
                (
                    PluginSettings::RMC_Medal != Medals::Bronze ?
                    (" and "+ BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)))
                    : ""
                ) + " medals!");
        }
#if DEPENDENCY_CHAOSMODE
        if (RMC::currentGameMode == RMC::GameMode::ChallengeChaos) {
            UI::ShowNotification(
                "\\$0f0Random Map Chaos Challenge ended!",
                "You got " + RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_Medal) +
                (
                    PluginSettings::RMC_Medal != Medals::Bronze ?
                    (" and "+ BelowMedalCount + " " + tostring(Medals(PluginSettings::RMC_Medal - 1)))
                    : ""
                ) + " medals!");
            ChaosMode::SetRMCMode(false);
        }
#endif
    }

    void GotGoalMedalNotification()
    {
        Log::Trace("RMC: Got the " + tostring(PluginSettings::RMC_Medal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "We're searching for another map...");
            startnew(RMC::SwitchMap);
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got the " + tostring(PluginSettings::RMC_Medal) + " medal!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification()
    {
        Log::Trace("RMC: Got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal!");
        if (!RMC::GotBelowMedal)
            UI::ShowNotification(
                "\\$db4" + Icons::Trophy + " You got the " + tostring(Medals(PluginSettings::RMC_Medal - 1)) + " medal",
                "You can take the medal and skip the map"
            );
    }

    void PendingTimerLoop(){}

    void TimerYield() {
        while (RMC::IsRunning){
            yield();
            if (!RMC::IsPaused) {
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(false);
#endif
                if (TM::InRMCMap()) {
                    RMC::StartTime = Time::Now;
                    RMC::TimeSpentMap = Time::Now - RMC::TimeSpawnedMap;
                    PendingTimerLoop();

                    if (RMC::StartTime > RMC::EndTime || !RMC::IsRunning || RMC::EndTime <= 0) {
                        RMC::StartTime = -1;
                        RMC::EndTime = -1;
                        RMC::IsRunning = false;
                        RMC::ShowTimer = false;
                        if (!RMC::UserEndedRun) {
                            GameEndNotification();
                            DataManager::RemoveCurrentSaveFile();  // run ended on time -> no point in saving it as it can't be continued
                        }
                        if (PluginSettings::RMC_ExitMapOnEndTime){
                            CTrackMania@ app = cast<CTrackMania>(GetApp());
                            app.BackToMainMenu();
                        }
                        @MX::preloadedMap = null;
                    }
                } else {
                    RMC::IsPaused = true;
                }
            } else {
                // pause timer
                RMC::StartTime = Time::Now - (Time::Now - RMC::StartTime);
                RMC::EndTime = Time::Now - (Time::Now - RMC::EndTime);
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(true);
#endif
            }
        }
    }

    uint get_GoalTime() {
        auto app = cast<CTrackMania>(GetApp());
        auto map = app.RootMap;

        if (map !is null && app.CurrentPlayground !is null) {
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
        auto app = cast<CTrackMania>(GetApp());
        auto map = app.RootMap;

        if (map !is null && app.CurrentPlayground !is null) {
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

                if (score == uint(-1)) {
                    sleep(50);
                    continue;
                }

                if (score <= GoalTime) {
                    GotGoalMedalNotification();
                    RMC::GoalMedalCount++;
                    RMC::GotGoalMedal = true;
                    RMC::CreateSave();
                } else if (!RMC::GotBelowMedal && PluginSettings::RMC_Medal != Medals::Bronze && score <= BelowGoalTime) {
                    GotBelowGoalMedalNotification();
                    RMC::GotBelowMedal = true;
                    RMC::CreateSave();
                }

                if (RMC::CurrentTimeOnMap == -1 || int(score) < RMC::CurrentTimeOnMap) {
                    // PB
                    RMC::CurrentTimeOnMap = score;
                    RMC::CreateSave();
                }

                sleep(1000);
            }
        }
    }
}