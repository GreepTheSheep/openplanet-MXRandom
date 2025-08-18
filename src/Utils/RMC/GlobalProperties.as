namespace RMC
{
    bool ShowTimer = false;
    bool IsStarting = false;
    bool IsRunning = false;
    bool IsPaused = false;
    bool isSwitchingMap = false;
    bool ClickedOnSkip = false;
    bool GotGoalMedal = false;
    bool GotBelowMedal = false;
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

    RMC@ Challenge = RMC();
    RMS@ Survival = RMS();
    RMObjective@ Objective = RMObjective();
    RMT@ Together = RMT();

    enum GameMode
    {
        Challenge,
        Survival,
        Objective,
        Together,
        ChallengeChaos,
        SurvivalChaos
    }
    GameMode currentGameMode;

    void FetchConfig() {
        Log::Trace("Fetching RMC configs from openplanet.dev...");
        string url = "https://openplanet.dev/plugin/mxrandom/config/rmc-config";
        Json::Value json = API::GetAsync(url);

        @config = RMCConfig(json);
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

        if (RMC::currentGameMode == GameMode::Challenge || RMC::currentGameMode == GameMode::Survival) {
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
                        Objective.Skips = 0;
                        FreeSkipsUsed = 0;
                        CurrentTimeOnMap = -1;
                        GotBelowMedal = false;
                        GotGoalMedal = false;
                    } else {
                        GoalMedalCount = CurrentRunData["PrimaryCounterValue"];
                        if (currentGameMode == GameMode::Challenge) {
                            Challenge.BelowMedalCount = CurrentRunData["SecondaryCounterValue"];
                            Survival.Skips = 0;
                            GotBelowMedal = CurrentRunData["GotBelowMedalOnMap"];
                            FreeSkipsUsed = CurrentRunData["FreeSkipsUsed"];
                        } else {
                            Challenge.BelowMedalCount = 0;
                            Survival.Skips = CurrentRunData["SecondaryCounterValue"];
                            Survival.SurvivedTime = CurrentRunData["CurrentRunTime"];
                            Challenge.ModeStartTimestamp = -1;
                        }
                        GotGoalMedal = CurrentRunData["GotGoalMedalOnMap"];
                        CurrentTimeOnMap = CurrentRunData["PBOnMap"];
                    }
                    UI::ShowNotification("\\$080Random Map "+ tostring(RMC::currentGameMode) + " started!", "Good Luck!");
                    IsInited = true;
                }

                while (!TM::IsPlayerReady()) {
                    yield();
                }
                if (RMC::currentGameMode == GameMode::Challenge || RMC::currentGameMode == GameMode::ChallengeChaos){
                    Challenge.StartTimer();
                } else if (RMC::currentGameMode == GameMode::Survival || RMC::currentGameMode == GameMode::SurvivalChaos){
                    Survival.StartTimer();
                } else if (RMC::currentGameMode == GameMode::Objective){
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

    void CreateSave(bool endRun = false) {
        CurrentRunData["MapData"] = CurrentMapJsonData;
        CurrentRunData["TimeSpentOnMap"] = RMC::TimeSpentMap;
        CurrentRunData["PrimaryCounterValue"] = GoalMedalCount;
        CurrentRunData["SecondaryCounterValue"] = currentGameMode == GameMode::Challenge ? Challenge.BelowMedalCount : Survival.Skips;
        CurrentRunData["GotGoalMedalOnMap"] = RMC::GotGoalMedal;
        CurrentRunData["PBOnMap"] = RMC::CurrentTimeOnMap;
        CurrentRunData["GotBelowMedalOnMap"] = RMC::GotBelowMedal;

        if (RMC::currentGameMode == RMC::GameMode::Survival) {
            CurrentRunData["CurrentRunTime"] = RMC::Survival.SurvivedTime;
        } else {
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
        isSwitchingMap = true;
        yield(100);
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()) {
            sleep(100);
        }
        EndTime = EndTime + (Time::Now - StartTime);
        IsPaused = false;
        isSwitchingMap = false;
        GotGoalMedal = false;
        GotBelowMedal = false;
        TimeSpawnedMap = Time::Now;
        ClickedOnSkip = false;
        CurrentTimeOnMap = -1;

        while (!TM::IsPlayerReady()) {
            yield();
        }
        IsPaused = false;

        MX::PreloadRandomMap();
    }
}