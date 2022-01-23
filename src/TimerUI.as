bool RMCStarted = false;
bool timerStarted = false;
bool displayTimer = false;
bool isPaused = false;
bool gotMedalOnceNotif = false;
bool gotAuthor = false;
int realStartTime = -1;
int startTime = -1;
int endTime = -1;
int authorCount = 0;
int goldCount = 0;
int survivalSkips = 0;
int mapsCount = 0;
Resources::Font@ timerFont = Resources::GetFont("src/Assets/Fonts/digital-7.mono.ttf", 20);
Resources::Texture@ AuthorTex = Resources::GetTexture("src/Assets/Images/Author.png");
Resources::Texture@ GoldTex = Resources::GetTexture("src/Assets/Images/Gold.png");
Resources::Texture@ SilverTex = Resources::GetTexture("src/Assets/Images/Silver.png");
Resources::Texture@ BronzeTex = Resources::GetTexture("src/Assets/Images/Bronze.png");
Resources::Texture@ SkipTex = Resources::GetTexture("src/Assets/Images/YEPSkip.png");
int TimerWindowFlags = UI::WindowFlags::NoDocking + UI::WindowFlags::NoResize + UI::WindowFlags::NoCollapse + UI::WindowFlags::AlwaysAutoResize;
string actualMedalName = "";
int lowerMedalInt = 0;
string lowerMedalName = "";
string windowTitle = MXColor+Icons::HourglassO + " \\$zRMC";

void Render(){
    if (!Setting_RMC_DisplayTimer) {
        // check if the timer is running
        if (RMCStarted){
            RMCStarted = false;
            timerStarted = false;
            displayTimer = false;
        }
        return;
    }

    if (!UI::IsOverlayShown()) TimerWindowFlags = UI::WindowFlags::NoDocking + UI::WindowFlags::NoResize + UI::WindowFlags::NoCollapse + UI::WindowFlags::AlwaysAutoResize + UI::WindowFlags::NoScrollbar + UI::WindowFlags::NoTitleBar;
    else TimerWindowFlags = UI::WindowFlags::NoDocking + UI::WindowFlags::NoResize + UI::WindowFlags::NoCollapse + UI::WindowFlags::AlwaysAutoResize;

    if (!displayTimer){
        if (UI::IsOverlayShown()){
            if (UI::Begin(windowTitle, Setting_RMC_DisplayTimer, TimerWindowFlags)){
#if TMNEXT
            if (!Permissions::PlayLocalMap()) UI::Text("\\$f00"+Icons::Times+" \\$zMissing permissions!");
            else {
#elif MP4
            if (!isTitePackLoaded()) UI::Text("\\$f00"+Icons::Times+" \\$zNo titlepack loaded");
            else {
#endif
                    if (RMCStarted){
                        UI::Text("Please wait until the map is found and loaded.");
                    } else {
                        UI::PushStyleColor(UI::Col::Button, vec4(0, 0.443, 0, 0.8));
                        UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0, 0.443, 0, 1));
                        UI::PushStyleColor(UI::Col::ButtonActive, vec4(0, 0.443, 0, 0.6));
                        if (UI::Button(Icons::Play+" Start Random Map Challenge")) {
                            Setting_RMC_Mode = RMCMode::Challenge;
                            RMCStarted = true;
                            startnew(loadFirstMapRMC);
                        }
                        if (UI::Button(Icons::Play+" Start Random Map Survival")) {
                            Setting_RMC_Mode = RMCMode::Survival;
                            RMCStarted = true;
                            startnew(loadFirstMapRMC);
                        }
                        UI::PopStyleColor(3);
                        if (UI::Button(Icons::Table + " Standings")) {
                            OpenBrowserURL("https://docs.google.com/spreadsheets/d/1hgjYu84s6RtQZTgDFS7ZeyqszALCH-5OpsmDtBNWK_U/edit?usp=sharing");
                        }
                        UI::SameLine();
                        int announcementsLength = 0;
                        if (IsPluginInfoAPILoaded()) announcementsLength = PluginInfoNet["announcements"].get_Length() - PluginData["announcements"]["read"].get_Length();
                        if (UI::Button(announcementsLength > 0 ? "\\$f0a" + Icons::Bullhorn+" \\$z"+announcementsLength : Icons::Kenney::InfoCircle)) {
                            WindowInfo_Show = true;
                        }
                    }
                }
                if (authorCount > 0 || goldCount > 0 || survivalSkips > 0 || mapsCount > 0){
                    UI::Separator();
                    UI::Text("Last run stats:");
                    RenderMedalsTable();
                }
            }
            UI::End();
        }
    } else {
        if (UI::Begin(windowTitle, Setting_RMC_DisplayTimer, TimerWindowFlags)){
            if (UI::IsOverlayShown() || (!UI::IsOverlayShown() && Setting_RMC_ShowBtns)){
                UI::PushStyleColor(UI::Col::Button, vec4(0.443, 0, 0, 0.8));
                UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.443, 0, 0, 1));
                UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.443, 0, 0, 0.6));
                if(UI::Button(Icons::Times + " Stop Random Map "+ changeEnumStyle(tostring(Setting_RMC_Mode)))){
                    timerStarted = false;
                    displayTimer = false;
                    RMCStarted = false;
                    }
                }
                UI::PopStyleColor(3);
                UI::Separator();
            }
            RenderTimer();
            UI::Dummy(vec2(0, 10));
            UI::Separator();
            RenderMedals();
            if (Setting_RMC_DisplayCurrentMap){
                UI::Separator();
                RenderCurrentMap();
            }
            if (UI::IsOverlayShown() || (!UI::IsOverlayShown() && Setting_RMC_ShowBtns)) RenderPlayingButtons();
            UI::End();
        }
    }
}

void startTimer() {
    isPaused = false;
    timerStarted = true;
    int timer = 60;
    if (Setting_RMC_Mode == RMCMode::Survival) timer = 15;
    realStartTime = Time::get_Now();
    startTime = Time::get_Now();
    endTime = startTime + (timer*60*1000);
}

void TimerYield() {
    if (timerStarted) {
        if (!isPaused){
            CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
            if (currentMap !is null) {
                CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
                if (currentMapInfo !is null) {
                    if (RecentlyPlayedMaps.Length > 0 && currentMapInfo.MapUid == RecentlyPlayedMaps[0]["UID"]) {
                        startTime = Time::get_Now();

                        if (Setting_RMC_Mode == RMCMode::Survival){
                            // Cap timer max
                            if ((endTime - startTime) > ((Setting_RMC_SurvivalMaxTime-survivalSkips)*60*1000)) {
                                endTime = startTime + ((Setting_RMC_SurvivalMaxTime-survivalSkips)*60*1000);
                            }
                        }

                        if (startTime > endTime) {
                            startTime = -1;
                            timerStarted = false;
                            RMCStarted = false;
                            displayTimer = false;
                            if (Setting_RMC_Mode == RMCMode::Challenge) UI::ShowNotification("\\$0f0Random Map Challenge ended!", "You got "+ authorCount + " author and "+ goldCount + " gold medals!");
                            else if (Setting_RMC_Mode == RMCMode::Survival) UI::ShowNotification("\\$0f0Random Map Survival ended!", "You survived with a time of " + FormatTimer(realStartTime - startTime) + ".\nYou got "+ authorCount + " author medals and " + survivalSkips + " skips.");
                            if (Setting_RMC_ExitMapOnEndTime){
                                CTrackMania@ app = cast<CTrackMania>(GetApp());
                                app.BackToMainMenu();
                            }
                        }
                    } else RecentlyPlayedMaps = loadRecentlyPlayed();
                }
            }
        } else {
            startTime = Time::get_Now() - (Time::get_Now() - startTime);
        }

        if (Setting_RMC_Goal == RMCGoal::Author) {
            actualMedalName = "Author";
            lowerMedalName = "Gold";
            lowerMedalInt = 3;
        } else if (Setting_RMC_Goal == RMCGoal::Gold) {
            actualMedalName = "Gold";
            lowerMedalName = "Silver";
            lowerMedalInt = 2;
        } else if (Setting_RMC_Goal == RMCGoal::Silver) {
            actualMedalName = "Silver";
            lowerMedalName = "Bronze";
            lowerMedalInt = 1;
        } else if (Setting_RMC_Goal == RMCGoal::Bronze) {
            actualMedalName = "Bronze";
            lowerMedalName = "";
            lowerMedalInt = 0;
        }

        if (GetCurrentMapMedal() >= Setting_RMC_Goal && !gotAuthor){
            print("RMC: Got "+ actualMedalName + " medal!");
            gotAuthor = true;
            authorCount += 1;
            if (Setting_RMC_AutoSwitch) {
                UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+actualMedalName+" time!", "We're searching for another map...");

                if (Setting_RMC_Mode == RMCMode::Survival) {
                    endTime += (3*60*1000);
                }
                startnew(loadMapRMC);
            } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+changeEnumStyle(tostring(Setting_RMC_Goal))+" time!", "Select 'Next map' to change the map");
        }
        if (GetCurrentMapMedal() >= lowerMedalInt && GetCurrentMapMedal() < Setting_RMC_Goal && !gotMedalOnceNotif && Setting_RMC_Mode == RMCMode::Challenge && Setting_RMC_Goal != RMCGoal::Bronze){
            print("RMC: Got "+ lowerMedalName + " medal!");
            if (!Setting_RMC_OnlySkip && mapsCount != 0) UI::ShowNotification("\\$db4" + Icons::Trophy + " You got "+lowerMedalName+" medal", "You can take the medal and skip the map");
            gotMedalOnceNotif = true;
        }
    }
}

void RenderTimer(){
    UI::PushFont(timerFont);
    if (timerStarted) {
        if (!isPaused) UI::Text(FormatTimer(endTime - startTime));
        else UI::Text("\\$555" + FormatTimer(endTime - startTime));
    } else {
        int timer = 60;
        if (Setting_RMC_Mode == RMCMode::Survival) timer = 15;
        timer = timer*60*60*1000;
        UI::Text("\\$555" + FormatTimer(timer));
    }
    UI::PopFont();
}

string FormatTimer(int time) {
    int hundreths = time % 1000 / 10;
    time /= 1000;
    int hours = time / 3600;
    int minutes = (time / 60) % 60;
    int seconds = time % 60;

    return (hours != 0 ? Text::Format("%02d", hours) + ":" : "" ) + (minutes != 0 ? Text::Format("%02d", minutes) + ":" : "") + Text::Format("%02d", seconds) + "." + Text::Format("%02d", hundreths);
}

string FormatSeconds(int time) {
    int seconds = time % 60;
    return Text::Format("%02d", seconds);
}

void RenderMedals() {
    if (Setting_RMC_Goal == RMCGoal::Author) UI::Image(AuthorTex, vec2(50,50));
    else if (Setting_RMC_Goal == RMCGoal::Gold) UI::Image(GoldTex, vec2(50,50));
    else if (Setting_RMC_Goal == RMCGoal::Silver) UI::Image(SilverTex, vec2(50,50));
    else if (Setting_RMC_Goal == RMCGoal::Bronze) UI::Image(BronzeTex, vec2(50,50));
    UI::SameLine();
    vec2 pos_orig = UI::GetCursorPos();
    UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
    UI::PushFont(timerFont);
    UI::Text("" + authorCount);
    UI::PopFont();

    if (Setting_RMC_Mode == RMCMode::Challenge && Setting_RMC_Goal != RMCGoal::Bronze){
        UI::SetCursorPos(vec2(pos_orig.x+35, pos_orig.y));
        if (Setting_RMC_Goal == RMCGoal::Author) UI::Image(GoldTex, vec2(50,50));
        else if (Setting_RMC_Goal == RMCGoal::Gold) UI::Image(SilverTex, vec2(50,50));
        else if (Setting_RMC_Goal == RMCGoal::Silver) UI::Image(BronzeTex, vec2(50,50));
        UI::SameLine();
        pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+10));
        UI::PushFont(timerFont);
        UI::Text("" + goldCount);
        UI::PopFont();
    }

    if (Setting_RMC_Mode == RMCMode::Survival){
        UI::SetCursorPos(vec2(pos_orig.x+35, pos_orig.y));
        UI::Image(SkipTex, vec2(50,50));
        UI::SameLine();
        pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+10));
        UI::PushFont(timerFont);
        UI::Text("" + survivalSkips);
        UI::PopFont();
    }
}

void RenderCurrentMap(){
    CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
    if (currentMap !is null) {
        CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
        if (currentMapInfo !is null) {
            if (RecentlyPlayedMaps.Length > 0 && currentMapInfo.MapUid == RecentlyPlayedMaps[0]["UID"]) {
                UI::Text("Current Map:");
                if (RecentlyPlayedMaps.get_Length() > 0){
                    string mapName = RecentlyPlayedMaps[0]["name"];
                    string mapAuthor = RecentlyPlayedMaps[0]["author"];
                    string mapStyle = RecentlyPlayedMaps[0]["style"];
                    UI::Text("'" + mapName + "' by " + mapAuthor);
                    UI::Text("(Style: " + mapStyle + ")");
                } else {
                    UI::Text(":( Map info unavailable");
                }
            } else RecentlyPlayedMaps = loadRecentlyPlayed();
        }
    } else {
        if (isPaused) UI::Text("Switching map...");
        else isPaused = true;
    }
}

void RenderPlayingButtons(){
    if (timerStarted) {
        int HourGlassValue = Time::Stamp % 3;
        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
        CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
        if (currentMap !is null) {
            if (UI::Button((isPaused ? Icons::HourglassO + Icons::Play : Hourglass + Icons::Pause))) {
                if (isPaused) endTime = endTime + (Time::get_Now() - startTime);
                isPaused = !isPaused;
            }
            UI::SameLine();
        }
        if (!Setting_RMC_OnlySkip) {
            if (mapsCount == 0) {
                if (UI::Button(Icons::Repeat + " Restart")) {
                    if (isPaused) isPaused = false;
                    timerStarted = false;
                    displayTimer = false;
                    startnew(loadFirstMapRMC);
                }
            } else {
                if(!gotAuthor && UI::Button(Icons::PlayCircleO + " Skip" + (Setting_RMC_Mode == RMCMode::Challenge && gotMedalOnceNotif && Setting_RMC_Goal != RMCGoal::Bronze ? " and take "+lowerMedalName+" medal": ""))) {
                    if (isPaused) isPaused = false;
                    if (Setting_RMC_Mode == RMCMode::Challenge && gotMedalOnceNotif) {
                        goldCount += 1;
                    }
                    if (Setting_RMC_Mode == RMCMode::Survival) {
                        survivalSkips += 1;
                    }
                    print("RMC: Skipping map");
                    UI::ShowNotification("Please wait...", "Looking for another map");
                    startnew(loadMapRMC);
                }
            }
        } else {
            if(!gotAuthor && UI::Button(Icons::PlayCircleO + " Skip" + (Setting_RMC_Mode == RMCMode::Challenge && gotMedalOnceNotif && Setting_RMC_Goal != RMCGoal::Bronze ? " and take "+lowerMedalName+" medal": ""))) {
                if (isPaused) isPaused = false;
                if (Setting_RMC_Mode == RMCMode::Challenge && gotMedalOnceNotif) {
                    goldCount += 1;
                }
                if (Setting_RMC_Mode == RMCMode::Survival) {
                    survivalSkips += 1;
                }
                print("RMC: Skipping map");
                UI::ShowNotification("Please wait...", "Looking for another map");
                startnew(loadMapRMC);
            }
        }

        if (Setting_RMC_Mode == RMCMode::Survival){
            UI::SameLine();
            if(UI::Button(Icons::PlayCircleO + " Survival Free Skip")) {
                isPaused = true;
                Dialogs::Question("\\$f00"+Icons::ExclamationTriangle+" \\$zFree skips is only if the map is impossible or broken.\n\nAre you sure to skip?", function() {
                    isPaused = false;
                    print("RMC: Survival Free Skip");
                    UI::ShowNotification("Please wait...", "Looking for another map");
                    startnew(loadMapRMC);
                }, function(){isPaused = false;});
            }
        }
        if (!Setting_RMC_AutoSwitch && gotAuthor){
            UI::SameLine();
            if(UI::Button(Icons::Play + " Next map")) {
                if (isPaused) isPaused = false;
                if (Setting_RMC_Mode == RMCMode::Survival) {
                    endTime += (3*60*1000);
                }
                startnew(loadMapRMC);
            }
        }


        // Dev
        if (isDevMode()) {
            if (UI::Button("+1min")) {
                if (isPaused) isPaused = false;
                endTime += (1*60*1000);
            }
            UI::SameLine();
            if (UI::Button("-1min")) {
                if (isPaused) isPaused = false;
                endTime -= (1*60*1000);

                if ((endTime - startTime) < (1*60*1000)) endTime = startTime + (1*60*1000);
            }
        }
    }
}

void RenderMedalsTable(){
    if(UI::BeginTable("##medals", 2, UI::TableFlags::SizingFixedFit)) {
        // Author
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("\\$071"+ Icons::Circle + "\\$z Author");
        UI::TableNextColumn();
        UI::Text("" + authorCount);

        if (Setting_RMC_Mode == RMCMode::Challenge) {
            // Gold
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text("\\$db4"+ Icons::Circle + "\\$z Gold");
            UI::TableNextColumn();
            UI::Text("" + goldCount);
        }

        if (Setting_RMC_Mode == RMCMode::Survival) {
            // Skips
            UI::TableNextRow();
            UI::TableNextColumn();
            UI::Text("\\$f30"+ Icons::Circle + "\\$z Skips");
            UI::TableNextColumn();
            UI::Text("" + survivalSkips);
        }

        // Maps
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("\\$6cf"+ Icons::Circle + "\\$z Maps played");
        UI::TableNextColumn();
        UI::Text("" + mapsCount);

        UI::EndTable();
    }
}

void loadFirstMapRMC(){
    print("RMC started in " + changeEnumStyle(tostring(Setting_RMC_Mode)) + " mode.");

    CTrackMania@ app = cast<CTrackMania>(GetApp());
    app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
    while(!app.ManiaTitleControlScriptAPI.IsReady) {
        yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
    }
    RandomMapProcess = true;
    isSearching = true;
    while (!IsMapLoaded()){
        sleep(100);
    }
    while (true){
        yield();
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
        if (GamePlayground !is null){
            goldCount = 0;
            authorCount = 0;
            survivalSkips = 0;
            mapsCount = 0;
            gotAuthor = false;
            gotMedalOnceNotif = false;
            if (!displayTimer) UI::ShowNotification("\\$080Random Map "+ changeEnumStyle(tostring(Setting_RMC_Mode)) + " started!", "Good Luck!");
            displayTimer = true;
#if MP4
            CTrackManiaPlayer@ player = cast<CTrackManiaPlayer>(GamePlayground.GameTerminals[0].GUIPlayer);
#elif TMNEXT
            CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].GUIPlayer);
#endif
            if (player !is null){
#if MP4
                while (player.RaceState != CTrackManiaPlayer::ERaceState::Running){
                    yield();
                }
#elif TMNEXT
                while (player.ScriptAPI.CurrentRaceTime < 0){
                    yield();
                }
#endif
                startTimer();
                break;
            }
        }
    }
}

void loadMapRMC(){
    print("RMC: Switching map.");
    isPaused = true;
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
    while(!app.ManiaTitleControlScriptAPI.IsReady) {
        yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
    }
    RandomMapProcess = true;
    isSearching = true;
    while (!IsMapLoaded()){
        sleep(100);
    }
    endTime = endTime + (Time::get_Now() - startTime);
    isPaused = false;
    gotMedalOnceNotif = false;
    gotAuthor = false;
    mapsCount += 1;
}
