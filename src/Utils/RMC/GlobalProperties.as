namespace RMC {
    bool ShowTimer = false;
    bool IsStarting = false;
    bool IsRunning = false;
    bool IsPaused = false;
    bool IsSwitchingMap = false;
    bool GotGoalMedal = false;
    bool GotBelowMedal = false;
    bool UserEndedRun = false; // Check if the user has clicked on "Stop..." button
    int GoalMedalCount = 0;
    int TimeSpentMap = -1;
    Json::Value CurrentMapJsonData = Json::Object();
    bool ContinueSavedRun = false;
    bool IsInited = false;
    bool HasCompletedCheckbox = false;
    Json::Value CurrentRunData = Json::Object();
    RMCConfig@ config;
    int FreeSkipsUsed = 0;
    int PBOnMap = -1; // for autosaves on PBs

    RMC@ Challenge = RMC();
    RMS@ Survival = RMS();
    RMObjective@ Objective = RMObjective();
    RMT@ Together = RMT();

    enum GameMode {
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
        time = Math::Max(0, time);
        string timer = Time::Format(time, true, false, false, true);

        if (timer.IndexOf(":") == 1 || timer.IndexOf(".") == 1) {
            // Add leading zero
            timer = "0" + timer;
        }

        return timer;
    }

    void Start() {
        IsInited = false;
        ShowTimer = true;
        IsStarting = true;
        IsSwitchingMap = false;
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

        while (!TM::IsMapLoaded()) {
            sleep(100);
        }

        if (!ContinueSavedRun) {
            TimeSpentMap = -1;
            GoalMedalCount = 0;
            FreeSkipsUsed = 0;
            PBOnMap = -1;
            GotBelowMedal = false;
            GotGoalMedal = false;
        } else {
            GoalMedalCount = CurrentRunData["PrimaryCounterValue"];
            GotGoalMedal = CurrentRunData["GotGoalMedal"];
            PBOnMap = CurrentRunData["PBOnMap"];
            TimeSpentMap = CurrentRunData["TimeSpentOnMap"];

            if (currentGameMode == GameMode::Challenge) {
                Challenge.BelowMedalCount = CurrentRunData["SecondaryCounterValue"];
                Survival.Skips = 0;
                GotBelowMedal = CurrentRunData["GotBelowMedal"];
                FreeSkipsUsed = CurrentRunData["FreeSkipsUsed"];
            } else {
                Challenge.BelowMedalCount = 0;
                Survival.Skips = CurrentRunData["SecondaryCounterValue"];
            }
        }

        UI::ShowNotification("\\$080Random Map " + tostring(RMC::currentGameMode) + " started!", "Good Luck!");
        IsInited = true;

        while (!TM::IsPlayerReady()) {
            yield();
        }

        if (RMC::currentGameMode == GameMode::Challenge || RMC::currentGameMode == GameMode::ChallengeChaos) {
            Challenge.StartTimer();
        } else if (RMC::currentGameMode == GameMode::Survival || RMC::currentGameMode == GameMode::SurvivalChaos) {
            Survival.StartTimer();
        } else if (RMC::currentGameMode == GameMode::Objective) {
            Objective.StartTimer();
        }

        // Clear the currently saved data so you cannot load into the same state multiple times
        DataManager::RemoveCurrentSaveFile();
        DataManager::CreateSaveFile();
        IsStarting = false;
        MX::PreloadRandomMap();
    }

    void CreateSave() {
        CurrentRunData["MapData"] = CurrentMapJsonData;
        CurrentRunData["TimeSpentOnMap"] = RMC::TimeSpentMap;
        CurrentRunData["PrimaryCounterValue"] = GoalMedalCount;
        CurrentRunData["GotGoalMedal"] = RMC::GotGoalMedal;
        CurrentRunData["PBOnMap"] = RMC::PBOnMap;
        CurrentRunData["GotBelowMedal"] = RMC::GotBelowMedal;

        if (currentGameMode == GameMode::Survival) {
            CurrentRunData["TotalTime"] = Survival.SurvivedTime;
            CurrentRunData["TimeLeft"] = Survival.TimeLeft;
            CurrentRunData["SecondaryCounterValue"] = Survival.Skips;
        } else if (currentGameMode == GameMode::Objective) {
            CurrentRunData["TotalTime"] = Objective.TotalTime;
            CurrentRunData["TimeLeft"] = Objective.TimeLeft;
            CurrentRunData["SecondaryCounterValue"] = Objective.BelowMedalCount;
        } else {
            CurrentRunData["TotalTime"] = Challenge.TotalTime;
            CurrentRunData["TimeLeft"] = Challenge.TimeLeft;
            CurrentRunData["SecondaryCounterValue"] = Challenge.BelowMedalCount;
        }

        DataManager::SaveCurrentRunData();
    }

    void SwitchMap() {
        IsPaused = true;
        IsSwitchingMap = true;
        yield(100);
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()) {
            sleep(100);
        }
        IsSwitchingMap = false;
        GotGoalMedal = false;
        GotBelowMedal = false;
        TimeSpentMap = 0;
        PBOnMap = -1;

        while (!TM::IsPlayerReady()) {
            yield();
        }
        IsPaused = false;

        MX::PreloadRandomMap();
    }
}