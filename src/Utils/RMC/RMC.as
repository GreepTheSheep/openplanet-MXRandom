class RMC
{
    bool Running = false;
    bool IsPaused = false;
    int StartTime = -1;
    int EndTime = -1;
    int GoalMedalCount = 0;
    int BelowMedalCount = 0;

    Resources::Font@ timerFont = Resources::GetFont("src/Assets/Fonts/digital-7.mono.ttf", 20);
    Resources::Texture@ AuthorTex = Resources::GetTexture("src/Assets/Images/Author.png");
    Resources::Texture@ GoldTex = Resources::GetTexture("src/Assets/Images/Gold.png");
    Resources::Texture@ SilverTex = Resources::GetTexture("src/Assets/Images/Silver.png");
    Resources::Texture@ BronzeTex = Resources::GetTexture("src/Assets/Images/Bronze.png");

    void Render()
    {
        string lastLetter = tostring(RMC::selectedGameMode).SubStr(0,1);
        if (UI::RedButton(Icons::Times + " Stop RM"+lastLetter))
        {
            RMC::IsRunning = false;
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

        if (Running) {
            UI::Separator();
            RenderPlayingButtons();
        }
    }

    void RenderTimer()
    {
        UI::PushFont(timerFont);
        if (Running) {
            if (IsPaused) UI::TextDisabled(RMC::FormatTimer(EndTime - StartTime));
            else UI::Text(RMC::FormatTimer(EndTime - StartTime));
        } else {
            UI::TextDisabled("--:--.--");
        }
        UI::PopFont();
    }

    void RenderGoalMedal()
    {
        if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[3]) UI::Image(AuthorTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[2]) UI::Image(GoldTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[1]) UI::Image(SilverTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[0]) UI::Image(BronzeTex, vec2(50,50));
        else UI::Text(PluginSettings::RMC_GoalMedal);
        UI::SameLine();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(timerFont);
        UI::Text(tostring(GoalMedalCount));
        UI::PopFont();
        UI::SetCursorPos(pos_orig);
    }

    void RenderBelowGoalMedal()
    {
        if (PluginSettings::RMC_GoalMedal != PluginSettings::Medals[0])
        {
            if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[3]) UI::Image(GoldTex, vec2(50,50));
            else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[2]) UI::Image(SilverTex, vec2(50,50));
            else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[1]) UI::Image(BronzeTex, vec2(50,50));
            else UI::Text(PluginSettings::RMC_GoalMedal);
            UI::SameLine();
            vec2 pos_orig = UI::GetCursorPos();
            UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
            UI::PushFont(timerFont);
            UI::Text(tostring(BelowMedalCount));
            UI::PopFont();
            UI::SetCursorPos(pos_orig);
        }
    }

    void RenderCurrentMap(){
        CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
        if (currentMap !is null) {
            CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
            if (currentMapInfo !is null) {
                if (DataJson["recentlyPlayed"].Length > 0 /*&& currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["TrackUID"]*/) {
                    UI::Separator();
                    MX::MapInfo@ CurrentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
                    UI::Text("Current Map:");
                    if (CurrentMap !is null) {
                        UI::Text(CurrentMap.Name);
                        UI::TextDisabled("by " + CurrentMap.Username);
                        if (CurrentMap.Tags.Length == 0) UI::TextDisabled("No tags");
                        else {
                            UI::Text("Tags:");
                            UI::SameLine();
                            for (uint i = 0; i < CurrentMap.Tags.Length; i++) {
                                Render::MapTag(CurrentMap.Tags[i]);
                                UI::SameLine();
                            }
                            UI::NewLine();
                        }
                    } else {
                        UI::Separator();
                        UI::TextDisabled("Map info unavailable");
                    }
                }
            }
        } else {
            UI::Separator();
            if (IsPaused) {
                UI::AlignTextToFramePadding();
                UI::Text("Switching map...");
                UI::SameLine();
                if (UI::Button("Force switch")) startnew(MX::LoadRandomMap);
            }
            else IsPaused = true;
        }
    }

    void RenderPlayingButtons()
    {
        int HourGlassValue = Time::Stamp % 3;
        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
        CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
        if (currentMap !is null) {
            if (UI::Button((IsPaused ? Icons::HourglassO + Icons::Play : Hourglass + Icons::Pause))) {
                if (IsPaused) EndTime = EndTime + (Time::get_Now() - StartTime);
                IsPaused = !IsPaused;
            }
            UI::SameLine();
        }
    }
}