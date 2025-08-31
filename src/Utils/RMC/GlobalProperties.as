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

    bool ContinueSavedRun = false;
    bool IsInited = false;
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
        UserEndedRun = false;

        if (RMC::currentGameMode == GameMode::Challenge || RMC::currentGameMode == GameMode::Survival) {
            bool hasRun = DataManager::LoadRunData();
            if (!hasRun) {
                DataManager::CreateSaveFile();
            } else {
                auto saveDialog = ContinueSavedRunModalDialog();
                Renderables::Add(saveDialog);
                while (!saveDialog.HasCompletedCheckbox) {
                    sleep(100);
                }
            }
        }
        if (RMC::ContinueSavedRun) {
            MX::MapInfo@ map = MX::MapInfo(CurrentRunData["MapData"]);
            map.PlayedAt = Time::Stamp;
            Log::LoadingMapNotification(map);
            DataManager::SaveMapToRecentlyPlayed(map);
            await(startnew(TM::LoadMap, map));
        } else {
            MX::LoadRandomMap();
        }

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

        while (!TM::IsPlayerReady()) {
            yield();
        }

        if (RMC::currentGameMode == GameMode::Challenge || RMC::currentGameMode == GameMode::ChallengeChaos) {
            @Challenge.currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            Challenge.StartTimer();
        } else if (RMC::currentGameMode == GameMode::Survival || RMC::currentGameMode == GameMode::SurvivalChaos) {
            @Survival.currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            Survival.StartTimer();
        } else if (RMC::currentGameMode == GameMode::Objective) {
            @Objective.currentMap = MX::MapInfo(DataJson["recentlyPlayed"][0]);
            Objective.StartTimer();
        }

        UI::ShowNotification("\\$080Random Map " + tostring(RMC::currentGameMode) + " started!", "Good Luck!");
        IsInited = true;

        // Clear the currently saved data so you cannot load into the same state multiple times
        DataManager::RemoveCurrentSaveFile();
        DataManager::CreateSaveFile();
        IsStarting = false;
    }

    void CreateSave() {
        CurrentRunData["TimeSpentOnMap"] = RMC::TimeSpentMap;
        CurrentRunData["PrimaryCounterValue"] = GoalMedalCount;
        CurrentRunData["GotGoalMedal"] = RMC::GotGoalMedal;
        CurrentRunData["PBOnMap"] = RMC::PBOnMap;
        CurrentRunData["GotBelowMedal"] = RMC::GotBelowMedal;

        if (currentGameMode == GameMode::Survival) {
            CurrentRunData["MapData"] = Survival.currentMap.ToJson();
            CurrentRunData["TotalTime"] = Survival.SurvivedTime;
            CurrentRunData["TimeLeft"] = Survival.TimeLeft;
            CurrentRunData["SecondaryCounterValue"] = Survival.Skips;
        } else if (currentGameMode == GameMode::Objective) {
            CurrentRunData["MapData"] = Objective.currentMap.ToJson();
            CurrentRunData["TotalTime"] = Objective.TotalTime;
            CurrentRunData["TimeLeft"] = Objective.TimeLeft;
            CurrentRunData["SecondaryCounterValue"] = Objective.BelowMedalCount;
        } else {
            CurrentRunData["MapData"] = Challenge.currentMap.ToJson();
            CurrentRunData["TotalTime"] = Challenge.TotalTime;
            CurrentRunData["TimeLeft"] = Challenge.TimeLeft;
            CurrentRunData["SecondaryCounterValue"] = Challenge.BelowMedalCount;
        }

        DataManager::SaveCurrentRunData();
    }
}