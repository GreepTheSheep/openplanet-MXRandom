namespace RMC
{
    bool ShowTimer = false;
    bool IsStarting = false;
    bool IsRunning = false;
    bool IsPaused = false;
    bool ClickedOnSkip = false;
    bool GotGoalMedalOnCurrentMap = false;
    bool GotBelowMedalOnCurrentMap = false;
    bool UserEndedRun = false; // Check if the user has clicked on "Stop..." button
    int GoalMedalCount = 0;
    int StartTime = -1;
    int EndTime = -1;
    int TimeSpentMap = -1;
    int TimeSpawnedMap = -1;
    Json::Value CurrentMapJsonData = Json::Object();
    bool ContinueSavedRun = false;
    bool IsInited = false;
    bool HasCompletedCheckbox = false;
    Json::Value CurrentRunData = Json::Object();
    int StartTimeCopyForSaveData = -1;
    int EndTimeCopyForSaveData = -1;
    RMCConfig@ config;
    int FreeSkipsUsed = 0;
    int CurrentTimeOnMap = -1; // for autosaves on PBs
    int CurrentMedal = -1;
    bool HandledRun = false;
    int LastRun = -1;

    array<string> Medals = {
        "Bronze",
        "Silver",
        "Gold",
        "Author"
#if TMNEXT
        ,"World Record"
#endif
    };

    const int allowedMaxLength = 180000;

    RMC@ Challenge;
    RMS@ Survival;
    RMObjective@ Objective;
    RMT@ Together;

    enum GameMode
    {
        Challenge,
        Survival,
        ChallengeChaos,
        SurvivalChaos,
        Objective,
        Together
    }
    GameMode selectedGameMode;

    void FetchConfig() {
        Log::Trace("Fetching RMC configs from openplanet.dev...");
        string url = "https://openplanet.dev/plugin/mxrandom/config/rmc-config";
        RMCConfigs@ cfgs = RMCConfigs(API::GetAsync(url));
#if TMNEXT
        @config = cfgs.cfgNext;
#else
        @config = cfgs.cfgMP4;
#endif
        Log::Trace("Fetched and loaded RMC configs!", IS_DEV_MODE);
    }

    void InitModes() {
        @Challenge = RMC();
        @Survival = RMS();
        @Objective = RMObjective();
        @Together = RMT();
    }

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
        IsInited = false;
        ShowTimer = true;
        IsStarting = true;
        ClickedOnSkip = false;
        ContinueSavedRun = false;
        HasCompletedCheckbox = false;
        UserEndedRun = false;
        HandledRun = false;
        CurrentMedal = -1;
        LastRun = -1;

        if (RMC::selectedGameMode == GameMode::Challenge || RMC::selectedGameMode == GameMode::Survival) {
            bool hasRun = DataManager::LoadRunData();
            if (!hasRun) {
                DataManager::CreateSaveFile();
            } else {
                Renderables::Add(ContinueSavedRunModalDialog());
                while (!HasCompletedCheckbox) {
                    sleep(100);
                }
            }
        }
        if (RMC::ContinueSavedRun) {
            RMC::CurrentMapJsonData = CurrentRunData["MapData"];
        }
        if (MX::preloadedMap !is null) {
            @MX::preloadedMap = null;
        }
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()){
            sleep(100);
        }
        while (true){
            yield();
            CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
            if (GamePlayground !is null){
                if (!IsInited) {
                    if (!ContinueSavedRun) {
                        TimeSpentMap = -1;
                        GoalMedalCount = 0;
                        Challenge.BelowMedalCount = 0;
                        Survival.Skips = 0;
                        FreeSkipsUsed = 0;
                        CurrentTimeOnMap = -1;
                        GotBelowMedalOnCurrentMap = false;
                        GotGoalMedalOnCurrentMap = false;
                    } else {
                        GoalMedalCount = CurrentRunData["PrimaryCounterValue"];
                        if (selectedGameMode == GameMode::Challenge) {
                            Challenge.BelowMedalCount = CurrentRunData["SecondaryCounterValue"];
                            Survival.Skips = 0;
                            GotBelowMedalOnCurrentMap = CurrentRunData["GotBelowMedalOnMap"];
                            FreeSkipsUsed = CurrentRunData["FreeSkipsUsed"];
                        } else {
                            Challenge.BelowMedalCount = 0;
                            Survival.Skips = CurrentRunData["SecondaryCounterValue"];
                            Survival.SurvivedTime = CurrentRunData["CurrentRunTime"];
                            Challenge.ModeStartTimestamp = -1;
                        }
                        GotGoalMedalOnCurrentMap = CurrentRunData["GotGoalMedalOnMap"];
                        CurrentTimeOnMap = CurrentRunData["PBOnMap"];
                    }
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
                    CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
                    while (playerScriptAPI.Post == 0){
                        yield();
                    }
#endif
                    if (RMC::selectedGameMode == GameMode::Challenge || RMC::selectedGameMode == GameMode::ChallengeChaos){
                        Challenge.StartTimer();
                    } else if (RMC::selectedGameMode == GameMode::Survival || RMC::selectedGameMode == GameMode::SurvivalChaos){
                        Survival.StartTimer();
                    } else if (RMC::selectedGameMode == GameMode::Objective){
                        Objective.StartTimer();
                    }
                    TimeSpawnedMap = !RMC::ContinueSavedRun ? Time::Now : int(Time::Now) - int(CurrentRunData["TimeSpentOnMap"]);
                    // Clear the currently saved data so you cannot load into the same state multiple times
                    DataManager::RemoveCurrentSaveFile();
                    DataManager::CreateSaveFile();
                    IsStarting = false;
                    MX::PreloadRandomMap();
                    break;
                }
            }
        }
    }

    int GetCurrentMapMedal()
    {
        auto app = cast<CTrackMania>(GetApp());
        auto map = app.RootMap;
        int medal = -1;

        if (map !is null) {
            int worldRecordTime = TM::GetWorldRecordFromCache(map.MapInfo.MapUid);
            int authorTime = map.TMObjective_AuthorTime;
            int goldTime = map.TMObjective_GoldTime;
            int silverTime = map.TMObjective_SilverTime;
            int bronzeTime = map.TMObjective_BronzeTime;
            int time = -1;

#if MP4
            CGameCtnPlayground@ playground = cast<CGameCtnPlayground>(app.CurrentPlayground);

            if (playground !is null && playground.PlayerRecordedGhost !is null) {
                if (playground.PlayerRecordedGhost.RaceTime != LastRun) {
                    HandledRun = false;
                    time = playground.PlayerRecordedGhost.RaceTime;
                }
            }
#elif TMNEXT
            CGamePlayground@ playground = cast<CGamePlayground>(app.CurrentPlayground);
            CSmArenaRulesMode@ script = cast<CSmArenaRulesMode>(app.PlaygroundScript);

            if (playground !is null && script !is null && playground.GameTerminals.Length > 0) {
                CSmPlayer@ player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);

                if (player !is null) {
                    auto UISequence = playground.GameTerminals[0].UISequence_Current;
                    bool finished = UISequence == SGamePlaygroundUIConfig::EUISequence::Finish;

                    if (HandledRun && !finished) {
                        HandledRun = false;
                    } else if (!HandledRun && finished) {
                        CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
                        auto ghost = script.Ghost_RetrieveFromPlayer(playerScriptAPI);

                        if (ghost !is null) {
                            if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) time = ghost.Result.Time;
                            script.DataFileMgr.Ghost_Release(ghost.Id);
                        }
                    }
                }
            }
#endif
            if (HandledRun || time == LastRun) {
                return CurrentMedal;
            } else if (time != -1) {
                // run finished
                if(time <= worldRecordTime) medal = 4;
                else if(time <= authorTime) medal = 3;
                else if(time <= goldTime) medal = 2;
                else if(time <= silverTime) medal = 1;
                else if(time <= bronzeTime) medal = 0;
                else medal = -1;

                HandledRun = true;
                CurrentMedal = medal;
                LastRun = time;

                if (IS_DEV_MODE) {
                    Log::Trace("Run finished with time " + FormatTimer(time));
                    Log::Trace("World Record time: " + FormatTimer(worldRecordTime));
                    Log::Trace("Author time: " + FormatTimer(authorTime));
                    Log::Trace("Gold time: " + FormatTimer(goldTime));
                    Log::Trace("Silver time: " + FormatTimer(silverTime));
                    Log::Trace("Bronze time: " + FormatTimer(bronzeTime));
                    Log::Trace("Medal: " + medal);
                }

                if (CurrentTimeOnMap > time || CurrentTimeOnMap == -1) {
                    // PB
                    CurrentTimeOnMap = time;
                    CreateSave();
                }
            }
        }
        return medal;
    }

    void CreateSave(bool endRun = false) {
        CurrentRunData["MapData"] = CurrentMapJsonData;
        CurrentRunData["TimeSpentOnMap"] = RMC::TimeSpentMap;
        CurrentRunData["PrimaryCounterValue"] = GoalMedalCount;
        CurrentRunData["SecondaryCounterValue"] = selectedGameMode == GameMode::Challenge ? Challenge.BelowMedalCount : Survival.Skips;
        CurrentRunData["GotGoalMedalOnMap"] = RMC::GotGoalMedalOnCurrentMap;
        CurrentRunData["PBOnMap"] = RMC::CurrentTimeOnMap;

        if (RMC::selectedGameMode == RMC::GameMode::Survival) {
            CurrentRunData["CurrentRunTime"] = RMC::Survival.SurvivedTime;
        } else {
            CurrentRunData["GotBelowMedalOnMap"] = RMC::GotBelowMedalOnCurrentMap;
            CurrentRunData["CurrentRunTime"] = RMC::Challenge.ModeStartTimestamp;
        }

        if (!endRun) {
            CurrentRunData["TimerRemaining"] = RMC::EndTime - RMC::StartTime;  // don't use the copies here, they are only updated for game end.
        } else {
            CurrentRunData["TimerRemaining"] = RMC::EndTimeCopyForSaveData - RMC::StartTimeCopyForSaveData;
        }


        DataManager::SaveCurrentRunData();
    }

    void SwitchMap()
    {
        IsPaused = true;
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()){
            sleep(100);
        }
        EndTime = EndTime + (Time::Now - StartTime);
        IsPaused = false;
        GotGoalMedalOnCurrentMap = false;
        GotBelowMedalOnCurrentMap = false;
        TimeSpawnedMap = Time::Now;
        ClickedOnSkip = false;
        CurrentTimeOnMap = -1;
        HandledRun = false;
        CurrentMedal = -1;
        LastRun = -1;

        MX::PreloadRandomMap();
    }
}