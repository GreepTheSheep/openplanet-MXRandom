class RMC
{
    int BelowMedalCount = 0;

    Resources::Font@ TimerFont = Resources::GetFont("src/Assets/Fonts/digital-7.mono.ttf", 20);
    Resources::Texture@ AuthorTex = Resources::GetTexture("src/Assets/Images/Author.png");
    Resources::Texture@ GoldTex = Resources::GetTexture("src/Assets/Images/Gold.png");
    Resources::Texture@ SilverTex = Resources::GetTexture("src/Assets/Images/Silver.png");
    Resources::Texture@ BronzeTex = Resources::GetTexture("src/Assets/Images/Bronze.png");

    int TimeLimit() { return 60 * 60 * 1000; }

    void Render()
    {
        string lastLetter = tostring(RMC::selectedGameMode).SubStr(0,1);
        if (UI::RedButton(Icons::Times + " Stop RM"+lastLetter))
        {
            RMC::IsRunning = false;
            RMC::StartTime = -1;
            RMC::EndTime = -1;
        }

        UI::Separator();

        UI::Dummy(vec2(0, 5));
        RenderTimer();
        UI::Dummy(vec2(0, 10));
        UI::Separator();

        UI::Dummy(vec2(0, 10));
        RenderGoalMedal();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x+50, pos_orig.y));
        RenderBelowGoalMedal();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+70));

        if (PluginSettings::RMC_DisplayCurrentMap)
        {
            RenderCurrentMap();
        }

        if (RMC::IsRunning) {
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
            UI::TextDisabled("--:--.--");
        }
        UI::PopFont();
    }

    void RenderGoalMedal()
    {
        if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) UI::Image(AuthorTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) UI::Image(GoldTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) UI::Image(SilverTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == RMC::Medals[0]) UI::Image(BronzeTex, vec2(50,50));
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
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[3]) UI::Image(GoldTex, vec2(50,50));
            else if (PluginSettings::RMC_GoalMedal == RMC::Medals[2]) UI::Image(SilverTex, vec2(50,50));
            else if (PluginSettings::RMC_GoalMedal == RMC::Medals[1]) UI::Image(BronzeTex, vec2(50,50));
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
                if (DataJson["recentlyPlayed"].Length > 0 /*&& currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["TrackUID"]*/) {
                    UI::Separator();
                    MX::MapInfo@ CurrentMapFromJson = MX::MapInfo(DataJson["recentlyPlayed"][0]);
                    UI::Text("Current Map:");
                    if (CurrentMapFromJson !is null) {
                        UI::Text(CurrentMapFromJson.Name);
                        UI::TextDisabled("by " + CurrentMapFromJson.Username);
                        if (CurrentMapFromJson.Tags.Length == 0) UI::TextDisabled("No tags");
                        else {
                            UI::Text("Tags:");
                            UI::SameLine();
                            for (uint i = 0; i < CurrentMapFromJson.Tags.Length; i++) {
                                Render::MapTag(CurrentMapFromJson.Tags[i]);
                                UI::SameLine();
                            }
                            UI::NewLine();
                        }
                    } else {
                        UI::Separator();
                        UI::TextDisabled("Map info unavailable");
                    }
                } else {
                    UI::Separator();
                    UI::TextDisabled("Error on getting current map");
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
            PausePlayButton();
            UI::SameLine();
            SkipButton();
            if (!PluginSettings::RMC_AutoSwitch) {
                UI::SameLine();
                NextMapButton();
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
            Log::Trace("RMC: Skipping map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
    }

    void NextMapButton()
    {
        if(UI::Button(Icons::Play + " Next map")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            Log::Trace("RMC: Next map");
            UI::ShowNotification("Please wait...");
            startnew(RMC::SwitchMap);
        }
    }

    void DevButtons()
    {
        if (UI::Button("+1min")) {
            if (RMC::IsPaused) RMC::IsPaused = false;
            RMC::EndTime += (1*60*1000);
        }
        UI::SameLine();
        if (UI::Button("-1min")) {
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
        startnew(RMC::TimerYield);
    }

}