bool RMCStarted = false;
bool timerStarted = false;
bool countdownStarted = false;
int countdownCompare = -1;
int startTime = -1;
int endTime = -1;
uint compareMedal = 0;
int authorCount = 0;
int goldCount = 0;
Resources::Font@ timerFont = Resources::GetFont("src/Assets/Fonts/digital-7.regular.ttf", 20);
int TimerWindowFlags = 2097154+32+64;
string windowTitle = MXColor+Icons::HourglassO + " \\$zRMC \\$666(Part of MXRandom)";

void Render(){
    if (!Setting_RMC_DisplayTimer) return;

    if (!UI::IsOverlayShown()) TimerWindowFlags = 2097154+32+64+1;
    else TimerWindowFlags = 2097154+32+64;

    if (!timerStarted){
        if (UI::IsOverlayShown()){
            if (UI::Begin(windowTitle, Setting_RMC_DisplayTimer, TimerWindowFlags)){
#if TMNEXT
            if (!Permissions::PlayLocalMap()) UI::Text("\\$f00"+Icons::Times+" \\$zMissing permissions!");
            else {
#elif MP4
            if (!isTitePackLoaded()) UI::Text("\\$f00"+Icons::Times+" \\$zNo titlepack loaded");
            else {
#endif
                    UI::PushStyleColor(UI::Col::Button, vec4(0, 0.443, 0, 0.8));
                    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0, 0.443, 0, 1));
                    UI::PushStyleColor(UI::Col::ButtonActive, vec4(0, 0.443, 0, 0.6));
                    if (RMCStarted){
                        UI::Text("Please wait until the map is found and loaded.");
                    } else {
                        if (UI::Button(Icons::Play+" Start Random Map "+ changeEnumStyle(tostring(Setting_RMC_Mode)))) {
                            RMCStarted = true;
                            startnew(loadFirstMapRMC);
                        }
                    }
                    UI::PopStyleColor(3);
                }
                if (UI::Button(Icons::Kenney::InfoCircle+" Help")) {
                    OpenBrowserURL("https://flinkblog.de/RMC");
                }
                if (authorCount > 0 || goldCount > 0){
                    UI::Separator();
                    RenderMedals();
                }
                UI::End();
            }
        }
    } else {
        if (UI::Begin(windowTitle, Setting_RMC_DisplayTimer, TimerWindowFlags)){
            if (UI::IsOverlayShown()){
                UI::PushStyleColor(UI::Col::Button, vec4(0.443, 0, 0, 0.8));
                UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.443, 0, 0, 1));
                UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.443, 0, 0, 0.6));
                if(UI::Button(Icons::Times + " Stop Random Map "+ changeEnumStyle(tostring(Setting_RMC_Mode)))){
                    timerStarted = false;
                    RMCStarted = false;
                }
                UI::PopStyleColor(3);
                UI::Separator();
            }
            RenderTimer();
            UI::Dummy(vec2(0, 10));
            UI::Separator();
            RenderMedals();
            UI::End();
        }
    }
}

void startCountdown(){
    UI::ShowNotification("\\$080Random Map "+ changeEnumStyle(tostring(Setting_RMC_Mode)) + " started!", "Good Luck!");
    countdownStarted = true;
    timerStarted = true;
    startTime = Time::get_Now();
    endTime = startTime + (10*999);
}

void startTimer() {
    int timer = 60;
    if (Setting_RMC_Mode == RMCMode::Survival) timer = 15;
    startTime = Time::get_Now();
    endTime = startTime + (timer*60*1000);
}

void Update(float dt) {
    if (startTime < 0 || (!timerStarted && !countdownStarted)) {
        return;
    }
    startTime = Time::get_Now();

    if (countdownStarted) {
        if (countdownCompare == -1) countdownCompare = startTime;
        if (startTime - countdownCompare > 999) {
            countdownCompare = startTime;
        }
    }

    if (startTime > endTime) {
        if (countdownStarted) {
            countdownStarted = false;
            countdownCompare = -1;
            startnew(RMCPlaySoundCountdownStart);
            startTimer();
        } else {
            startTime = -1;
            timerStarted = false;
            RMCStarted = false;
            startnew(RMCPlaySoundTimerEnd);
            UI::ShowNotification("\\$0f0Random Map "+ changeEnumStyle(tostring(Setting_RMC_Mode)) + " ended!", "You got "+ authorCount + " authors and "+ goldCount + " gold medals!");
        }
    }

    if (timerStarted && !countdownStarted){
        if (compareMedal != 99) compareMedal = GetCurrentMapMedal();
        if (compareMedal == 4){
            UI::ShowNotification("\\$0f0" + Icons::Trophy + " You got author time!", "We're searching for another map...");
            compareMedal = 99;
            startnew(loadMapRMC);
        } else if (compareMedal == 3){
            UI::ShowNotification(Icons::Trophy + "You got gold medal", "You can skip the map to get another one");
            compareMedal == 99;
        }
        if (compareMedal != 99) compareMedal = 0;
    }
}

void RMCPlaySoundCountdownStart(){
    PlaySound("RaceGo.wav");
}
void RMCPlaySoundTimerEnd(){
    PlaySound("RaceGo.wav");
}

void RenderTimer(){
    UI::PushFont(timerFont);
    if (countdownStarted) UI::Text("\\$0f0- " + FormatTimer(endTime - startTime));
    else UI::Text(FormatTimer(endTime - startTime));
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

void RenderMedals(){
    if(UI::BeginTable("##medals", 3, UI::TableFlags::SizingFixedFit)) {
        // Author
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("\\$071"+ Icons::Circle + "\\$z Author");
        UI::TableNextColumn();
        UI::Text("" + authorCount);

        // Gold
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text("\\$db4"+ Icons::Circle + "\\$z Gold");
        UI::TableNextColumn();
        UI::Text("" + goldCount);

        UI::TableNextColumn();
        if(UI::IsOverlayShown() && GetCurrentMapMedal() == 3 && UI::Button("Skip")) {
            goldCount += 1;
            if (goldCount < 0) {
                goldCount = 0;
            }
            UI::ShowNotification("Please wait...", "Looking for another map");
            startnew(loadMapRMC);
        }

        UI::EndTable();
    }
}

void loadFirstMapRMC(){
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
    while(!app.ManiaTitleControlScriptAPI.IsReady) {
        yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
    }
    RandomMapProcess = true;
    isSearching = !isSearching;
    while (true){
        sleep(100);
        if (IsMapLoaded()){
            startCountdown();
            compareMedal = 0;
            break;
        }
    }
}

void loadMapRMC(){
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
    while(!app.ManiaTitleControlScriptAPI.IsReady) {
        yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
    }
    RandomMapProcess = true;
    isSearching = !isSearching;
    while (true){
        sleep(100);
        if (IsMapLoaded()){
            compareMedal = 0;
            break;
        }
    }
}


void test(){
    while (true){
        yield(); 
        // print(GetCurrentMapMedal());
    }
}