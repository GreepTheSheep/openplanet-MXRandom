namespace RMC
{
    bool ShowTimer = false;
    bool IsRunning = false;
    bool IsPaused = false;
    bool GotGoalMedalOnCurrentMap = false;
    bool GotBelowMedalOnCurrentMap = false;
    int GoalMedalCount = 0;
    int StartTime = -1;
    int EndTime = -1;

    array<string> Medals = {
        "Bronze",
        "Silver",
        "Gold",
        "Author"
    };

    RMC Challenge;
    RMS Survival;

    enum GameMode
    {
        Challenge,
        Survival
    }
    GameMode selectedGameMode;

    string FormatTimer(int time) {
        int hundreths = time % 1000 / 10;
        time /= 1000;
        int hours = time / 60 / 60;
        int minutes = (time / 60) % 60;
        int seconds = time % 60;

        string result = "";

        if (hours > 0) {
            result += Text::Format("%02d", hours) + ":";
        }
        if (minutes > 0 || (hours > 0 && minutes < 10)) {
            result += Text::Format("%02d", minutes) + ":";
        }
        result += Text::Format("%02d", seconds) + "." + Text::Format("%02d", hundreths);

        return result;
    }

    void Start()
    {
        bool IsInited = false;
        ShowTimer = true;
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()){
            sleep(100);
        }
        while (true){
            yield();
            CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
            if (GamePlayground !is null){
                if (!IsInited) {
                    GoalMedalCount = 0;
                    Challenge.BelowMedalCount = 0;
                    Survival.Skips = 0;
                    UI::ShowNotification("\\$080Random Map "+ tostring(RMC::selectedGameMode) + " started!", "Good Luck!");
                    IsInited = true;
                }
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
                    if (RMC::selectedGameMode == GameMode::Challenge){
                        Challenge.StartTimer();
                    } else if (RMC::selectedGameMode == GameMode::Survival){
                        Survival.StartTimer();
                    }
                    break;
                }
            }
        }
    }

    void TimerYield() {
        while (IsRunning){
            yield();
            if (!IsPaused) {
                CGameCtnChallenge@ currentMap = cast<CGameCtnChallenge>(GetApp().RootMap);
                if (currentMap !is null) {
                    CGameCtnChallengeInfo@ currentMapInfo = currentMap.MapInfo;
                    if (currentMapInfo !is null) {
                        if (DataJson["recentlyPlayed"].Length > 0 && currentMapInfo.MapUid == DataJson["recentlyPlayed"][0]["TrackUID"]) {
                            StartTime = Time::get_Now();

                            if (RMC::selectedGameMode == GameMode::Survival) {
                                // Cap timer max
                                if ((EndTime - StartTime) > (PluginSettings::RMC_SurvivalMaxTime-Survival.Skips)*60*1000) {
                                    EndTime = StartTime + (PluginSettings::RMC_SurvivalMaxTime-Survival.Skips)*60*1000;
                                }
                            }

                            if (StartTime > EndTime) {
                                StartTime = -1;
                                EndTime = -1;
                                IsRunning = false;
                                ShowTimer = false;
                                if (RMC::selectedGameMode == GameMode::Challenge) UI::ShowNotification("\\$0f0Random Map Challenge ended!", "You got "+ GoalMedalCount + " " + tostring(PluginSettings::RMC_GoalMedal) + (PluginSettings::RMC_GoalMedal != RMC::Medals[0] ? (" and "+ Challenge.BelowMedalCount + " " + RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]) : "") + " medals!");
                                if (RMC::selectedGameMode == GameMode::Survival) UI::ShowNotification("\\$0f0Random Map Survival ended!", "You survived with a time of " + FormatTimer(Survival.SurvivedTime) + ".\nYou got "+ GoalMedalCount + " " + tostring(PluginSettings::RMC_GoalMedal) + " medals and " + Survival.Skips + " skips.");
                                if (PluginSettings::RMC_ExitMapOnEndTime){
                                    CTrackMania@ app = cast<CTrackMania>(GetApp());
                                    app.BackToMainMenu();
                                }
                            }
                        } else {
                            IsPaused = true;
                        }
                    }
                }
            } else {
                // pause timer
                StartTime = Time::get_Now() - (Time::get_Now() - StartTime);
                EndTime = Time::get_Now() - (Time::get_Now() - EndTime);
            }

            if (GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal) && !GotGoalMedalOnCurrentMap){
                Log::Trace("RMC: Got "+ tostring(PluginSettings::RMC_GoalMedal) + " medal!");
                GoalMedalCount += 1;
                GotGoalMedalOnCurrentMap = true;
                if (PluginSettings::RMC_AutoSwitch) {
                    UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "We're searching for another map...");

                    if (RMC::selectedGameMode == GameMode::Survival) {
                        EndTime += (3*60*1000);
                    }
                    startnew(SwitchMap);
                } else UI::ShowNotification("\\$071" + Icons::Trophy + " You got "+tostring(PluginSettings::RMC_GoalMedal)+" time!", "Select 'Next map' to change the map");
            }
            if (GetCurrentMapMedal() >= RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1 && !GotGoalMedalOnCurrentMap && RMC::selectedGameMode == RMC::GameMode::Challenge && PluginSettings::RMC_GoalMedal != RMC::Medals[0]){
                Log::Trace("RMC: Got "+ RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1] + " medal!");
                if (!GotBelowMedalOnCurrentMap) UI::ShowNotification("\\$db4" + Icons::Trophy + " You got "+RMC::Medals[RMC::Medals.Find(PluginSettings::RMC_GoalMedal)-1]+" medal", "You can take the medal and skip the map");
                GotBelowMedalOnCurrentMap = true;
            }
        }
    }

    int GetCurrentMapMedal()
    {
        auto app = cast<CTrackMania>(GetApp());
        auto map = app.RootMap;
        CGamePlayground@ GamePlayground = cast<CGamePlayground>(app.CurrentPlayground);
        int medal = -1;
        if (map !is null && GamePlayground !is null){
            int authorTime = map.TMObjective_AuthorTime;
            int goldTime = map.TMObjective_GoldTime;
            int silverTime = map.TMObjective_SilverTime;
            int bronzeTime = map.TMObjective_BronzeTime;
            int time = -1;

#if MP4
            CGameCtnPlayground@ GameCtnPlayground = cast<CGameCtnPlayground>(app.CurrentPlayground);
            if (GameCtnPlayground.PlayerRecordedGhost !is null){
                time = GameCtnPlayground.PlayerRecordedGhost.RaceTime;
            } else time = -1;
#elif TMNEXT
            CSmArenaRulesMode@ PlaygroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);
            if (PlaygroundScript !is null && GamePlayground.GameTerminals.get_Length() > 0) {
                CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].ControlledPlayer);
                if (GamePlayground.GameTerminals[0].UISequence_Current == CGameTerminal::ESGamePlaygroundUIConfig__EUISequence::Finish && player !is null) {
                    auto ghost = PlaygroundScript.Ghost_RetrieveFromPlayer(player.ScriptAPI);
                    if (ghost !is null) {
                        if (ghost.Result.Time > 0 && ghost.Result.Time < 4294967295) time = ghost.Result.Time;
                        PlaygroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                    } else time = -1;
                } else time = -1;
            } else time = -1;
#endif
            if (time != -1){
                if(time <= authorTime) medal = 3;
                else if(time <= goldTime) medal = 2;
                else if(time <= silverTime) medal = 1;
                else if(time <= bronzeTime) medal = 0;
                else medal = -1;
            }
        }
        return medal;
    }

    void SwitchMap()
    {
        IsPaused = true;
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()){
            sleep(100);
        }
        EndTime = EndTime + (Time::get_Now() - StartTime);
        IsPaused = false;
        GotGoalMedalOnCurrentMap = false;
        GotBelowMedalOnCurrentMap = false;
    }

    void LoadLatestMapFromList()
    {
        IsPaused = true;
        MX::LoadLatestMapFromList();
        while (!TM::IsMapLoaded()){
            sleep(100);
        }
        EndTime = EndTime + (Time::get_Now() - StartTime);
        IsPaused = false;
        GotGoalMedalOnCurrentMap = false;
        GotBelowMedalOnCurrentMap = false;
    }

}