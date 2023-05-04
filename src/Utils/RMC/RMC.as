class RMC
{
    int BelowMedalCount = 0;

    UI::Font@ TimerFont = UI::LoadFont("src/Assets/Fonts/digital-7.mono.ttf", 20);
    UI::Texture@ AuthorTex = UI::LoadTexture("src/Assets/Images/Author.png");
    UI::Texture@ GoldTex = UI::LoadTexture("src/Assets/Images/Gold.png");
    UI::Texture@ SilverTex = UI::LoadTexture("src/Assets/Images/Silver.png");
    UI::Texture@ BronzeTex = UI::LoadTexture("src/Assets/Images/Bronze.png");

    RMC()
    {
        print(GetModeName() + " loaded");
    }

    string GetModeName() { return "Random Map Challenge";}

    int TimeLimit() { return 60 * 60 * 1000; }

    string IsoDateToDMY(string isoDate)
    {
        string year = isoDate.SubStr(0, 4);
        string month = isoDate.SubStr(5, 2);
        string day = isoDate.SubStr(8, 2);
        return day + "-" + month + "-" + year;
    }

    void Render()
    {
        string lastLetter = tostring(RMC::selectedGameMode).SubStr(0,1);
        if (RMC::IsRunning && (UI::IsOverlayShown() || (!UI::IsOverlayShown() && PluginSettings::RMC_AlwaysShowBtns))) {
            if (UI::RedButton(Icons::Times + " Stop RM"+lastLetter))
            {
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCMode(false);
#endif
                RMC::IsRunning = false;
                RMC::ShowTimer = false;
                RMC::StartTime = -1;
                RMC::EndTime = -1;
            }

            UI::Separator();
        }

        RenderTimer();
        UI::Separator();
        RenderGoalMedal();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x+50, pos_orig.y));
        RenderBelowGoalMedal();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+60));

        if (PluginSettings::RMC_DisplayCurrentMap)
        {
            RenderCurrentMap();
        }

        if (RMC::IsRunning && (UI::IsOverlayShown() || (!UI::IsOverlayShown() && PluginSettings::RMC_AlwaysShowBtns))) {
            UI::Separator();
            RenderPlayingButtons();
        }
    }

    void RenderTimer()
    {
        UI::PushFont(TimerFont);
        if (RMC::IsRunning || RMC::EndTime > 0) {
            if (RMC::IsPaused) UI::TextDisabled(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));
            else UI::Text(RMC::FormatTimer(RMC::EndTime - RMC::StartTime));
        } else {
            UI::TextDisabled(RMC::FormatTimer(TimeLimit()));
        }
        UI::PopFont();
        UI::Dummy(vec2(0, 8));
        if (PluginSettings::RMC_DisplayMapTimeSpent) {
            UI::PushFont(g_fontHeaderSub);
            UI::Text(Icons::Map + " " + RMC::FormatTimer(RMC::TimeSpentMap));
            UI::SetPreviousTooltip("Time spent on this map");
            UI::PopFont();
        }
        if (IS_DEV_MODE) {
            if (RMC::IsRunning || RMC::EndTime > 0) {
                if (RMC::IsPaused) UI::Text("Timer en pause");
                else UI::Text("Timer en cours");
            } else UI::Text("Fin du timer");
        }
    }

    void RenderGoalMedal()
    {
        if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) UI::Image(AuthorTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) UI::Image(GoldTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) UI::Image(SilverTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[0]) UI::Image(BronzeTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
        else UI::Text(PluginSettings::RMC_GoalMedal);
        UI::SameLine();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(TimerFont);
        UI::Text(tostring(RMC::GoalMedalCount));
        UI::PopFont();
        UI::SetCursorPos(pos_orig);
    }

    void RenderBelowGoalMedal()
    {
        if (PluginSettings::RMC_GoalMedal != RMC::Medals[0])
        {
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) UI::Image(GoldTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
            else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) UI::Image(SilverTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
            else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) UI::Image(BronzeTex, vec2(PluginSettings::RMC_ImageSize*2,PluginSettings::RMC_ImageSize*2));
            else UI::Text(PluginSettings::RMC_GoalMedal);
            UI::SameLine();
            vec2 pos_orig = UI::GetCursorPos();
            UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
            UI::PushFont(TimerFont);
            UI::Text(tostring(BelowMedalCount));
            UI::PopFont();
            UI::SetCursorPos(pos_orig);
        }
    }

    void RenderCurrentMap()
    {
        CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
        if (currentMap !is null) {
            CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
            if (currentMapInfo !is null) {
                if (DataJson["recentlyPlayed"].Length > 0 && currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["TrackUID"]) {
                    UI::Separator();
                    MX::MapInfo@ CurrentMapFromJson = MX::MapInfo(DataJson["recentlyPlayed"][0]);
                    if (CurrentMapFromJson !is null) {
                        UI::Text(CurrentMapFromJson.Name);
                        if(PluginSettings::RMC_DisplayMapDate) {
                            UI::TextDisabled(IsoDateToDMY(CurrentMapFromJson.UpdatedAt));
                            UI::SameLine();
                        }
                        UI::TextDisabled("by " + CurrentMapFromJson.Username);
#if TMNEXT
                        if (PluginSettings::RMC_PrepatchTagsWarns && RMC::config.isMapHasPrepatchMapTags(CurrentMapFromJson)) {
                            RMCConfigMapTag@ prepatchTag = RMC::config.getMapPrepatchMapTag(CurrentMapFromJson);
                            UI::Text("\\$f80" + Icons::ExclamationTriangle + "\\$z"+prepatchTag.title);
                            UI::SetPreviousTooltip(prepatchTag.reason + (IS_DEV_MODE ? ("\nExeBuild: " + CurrentMapFromJson.ExeBuild) : ""));
                        }
#endif
                        if (PluginSettings::RMC_TagsLength != 0) {
                            if (CurrentMapFromJson.Tags.Length == 0) UI::TextDisabled("No tags");
                            else {
                                uint tagsLength = CurrentMapFromJson.Tags.Length;
                                if (CurrentMapFromJson.Tags.Length > PluginSettings::RMC_TagsLength) tagsLength = PluginSettings::RMC_TagsLength;
                                for (uint i = 0; i < tagsLength; i++) {
                                    Render::MapTag(CurrentMapFromJson.Tags[i]);
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
            }
        } else {
            UI::Separator();
            if (RMC::IsPaused) {
                UI::AlignTextToFramePadding();
                UI::Text("Switching map...");
                UI::SameLine();
                if (UI::Button("Force switch")) startnew(RMC::SwitchMap);
            }
            else RMC::IsPaused = true;
        }
    }

    void RenderPlayingButtons()
    {
        CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
        if (currentMap !is null) {
            CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
            if (DataJson["recentlyPlayed"].Length > 0 && currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["TrackUID"]) {
                PausePlayButton();
                UI::SameLine();
                SkipButton();
                if (!PluginSettings::RMC_AutoSwitch && RMC::GotGoalMedalOnCurrentMap) {
                    NextMapButton();
                }
            }
            if (IS_DEV_MODE) {
                DevButtons();
            }
        }
    }

    void PausePlayButton()
    {
        int HourGlassValue = Time::Stamp % 3;
        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
        if (UI::Button((RMC::IsPaused ? Icons::HourglassO + Icons::Play : Hourglass + Icons::Pause))) {
            if (RMC::IsPaused) RMC::EndTime = RMC::EndTime + (Time::get_Now() - RMC::StartTime);
            RMC::IsPaused = !RMC::IsPaused;
        }
    }

    void SkipButton()
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
            }
            MX::MapInfo@ CurrentMapFromJson = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            if (
#if TMNEXT
                PluginSettings::RMC_PrepatchTagsWarns &&
                RMC::config.isMapHasPrepatchMapTags(CurrentMapFromJson) &&
#endif
                !RMC::GotBelowMedalOnCurrentMap
            ) RMC::EndTime += RMC::TimeSpentMap;
            Log::Trace("RMC: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
    }

    void NextMapButton()
    {
        if(UI::GreenButton(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMC: Next map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
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
        RMC::StartTime = Time::get_Now();
        RMC::EndTime = RMC::StartTime + TimeLimit();
        RMC::IsPaused = false;
        RMC::IsRunning = true;
        startnew(CoroutineFunc(TimerYield));
    }

    void GameEndNotification()
    {
        if (RMC::selectedGameMode == RMC::GameMode::Challenge)
            UI::ShowNotification(
                "\\$0f0Random Map Challenge ended!",
                "You got "+ RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_GoalMedal) +
                (
                    PluginSettings::RMC_GoalMedal != RMC::Medals[0] ?
                    (" and "+ BelowMedalCount + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1])
                    : ""
                ) + " medals!");
#if DEPENDENCY_CHAOSMODE
        if (RMC::selectedGameMode == RMC::GameMode::ChallengeChaos) {
            UI::ShowNotification(
                "\\$0f0Random Map Chaos Challenge ended!",
                "You got "+ RMC::GoalMedalCount + " " + tostring(PluginSettings::RMC_GoalMedal) +
                (
                    PluginSettings::RMC_GoalMedal != RMC::Medals[0] ?
                    (" and "+ BelowMedalCount + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1])
                    : ""
                ) + " medals!");
            ChaosMode::SetRMCMode(false);
        }
#endif
    }

    void GotGoalMedalNotification()
    {
        Log::Trace("RMC: Got "+ tostring(PluginSettings::RMC_GoalMedal) + " medal!");
        if (PluginSettings::RMC_AutoSwitch) {
            UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "We're searching for another map...");
            startnew(RMC::SwitchMap);
        } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "Select 'Next map' to change the map");
    }

    void GotBelowGoalMedalNotification()
    {
        Log::Trace("RMC: Got "+ RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medal!");
        if (!RMC::GotBelowMedalOnCurrentMap)
            UI::ShowNotification(
                "\\$db4" + Icons::Trophy + " You got "+RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]+" medal",
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
                CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
                if (currentMap !is null) {
                    CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
                    if (currentMapInfo !is null) {
                        if (DataJson["recentlyPlayed"].Length > 0 && currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["TrackUID"]) {
                            RMC::StartTime = Time::Now;
                            RMC::TimeSpentMap = Time::Now - RMC::TimeSpawnedMap;
                            PendingTimerLoop();

                            if (RMC::StartTime > RMC::EndTime) {
                                RMC::StartTime = -1;
                                RMC::EndTime = -1;
                                RMC::IsRunning = false;
                                RMC::ShowTimer = false;
                                GameEndNotification();
                                if (PluginSettings::RMC_ExitMapOnEndTime){
                                    CTrackMania@ app = cast<CTrackMania>(GetApp());
                                    app.BackToMainMenu();
                                }
                            }
                        } else {
                            RMC::IsPaused = true;
                        }
                    }
                }
            } else {
                // pause timer
                RMC::StartTime = Time::get_Now() - (Time::get_Now() - RMC::StartTime);
                RMC::EndTime = Time::get_Now() - (Time::get_Now() - RMC::EndTime);
#if DEPENDENCY_CHAOSMODE
                ChaosMode::SetRMCPaused(true);
#endif
            }

            if (RMC::GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal) && !RMC::GotGoalMedalOnCurrentMap){
                GotGoalMedalNotification();
                RMC::GoalMedalCount += 1;
                RMC::GotGoalMedalOnCurrentMap = true;
            }
            if (
                RMC::GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1 &&
                !RMC::GotGoalMedalOnCurrentMap &&
                PluginSettings::RMC_GoalMedal != RMC::Medals[0])
            {
                GotBelowGoalMedalNotification();
                RMC::GotBelowMedalOnCurrentMap = true;
            }
        }
    }

}