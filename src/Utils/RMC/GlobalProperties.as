namespace RMC
{
    bool ShowTimer = false;
    bool IsStarting = false;
    bool IsRunning = false;
    bool IsPaused = false;
    bool ClickedOnSkip = false;
    bool GotGoalMedalOnCurrentMap = false;
    bool GotBelowMedalOnCurrentMap = false;
    int GoalMedalCount = 0;
    int StartTime = -1;
    int EndTime = -1;
    int TimeSpentMap = -1;
    int TimeSpawnedMap = -1;
    RMCConfig@ config;

    array<string> Medals = {
        "Bronze",
        "Silver",
        "Gold",
        "Author"
    };

    const array<string> allowedMapLengths = {
        "15 secs",
        "30 secs",
        "45 secs",
        "1 min",
        "1 m 15 s",
        "1 m 30 s",
        "1 m 45 s",
        "2 min",
        "2 m 30 s",
        "3 min"
    };

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
        bool IsInited = false;
        ShowTimer = true;
        IsStarting = true;
        ClickedOnSkip = false;
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()){
            sleep(100);
        }
        while (true){
            yield();
            CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
            if (GamePlayground !is null){
                if (!IsInited) {
                    TimeSpawnedMap = -1;
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
                    TimeSpawnedMap = Time::Now;
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
                if (GamePlayground.GameTerminals[0].UISequence_Current == SGamePlaygroundUIConfig::EUISequence::Finish && player !is null) {
                    CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
                    auto ghost = PlaygroundScript.Ghost_RetrieveFromPlayer(playerScriptAPI);
                    if (ghost !is null) {
                        if (ghost.Result.Time > 0 && ghost.Result.Time < 4294967295) time = ghost.Result.Time;
                        PlaygroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                    } else time = -1;
                } else time = -1;
            } else time = -1;
#endif
            if (time != -1){
                // run finished
                if(time <= authorTime) medal = 3;
                else if(time <= goldTime) medal = 2;
                else if(time <= silverTime) medal = 1;
                else if(time <= bronzeTime) medal = 0;
                else medal = -1;

                if (IS_DEV_MODE) {
                    Log::Trace("Run finished with time " + FormatTimer(time));
                    Log::Trace("Author time: " + FormatTimer(authorTime));
                    Log::Trace("Gold time: " + FormatTimer(goldTime));
                    Log::Trace("Silver time: " + FormatTimer(silverTime));
                    Log::Trace("Bronze time: " + FormatTimer(bronzeTime));
                    Log::Trace("Medal: " + medal);
                }

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
        EndTime = EndTime + (Time::Now - StartTime);
        IsPaused = false;
        GotGoalMedalOnCurrentMap = false;
        GotBelowMedalOnCurrentMap = false;
        TimeSpawnedMap = Time::Now;
        ClickedOnSkip = false;
        MX::PreloadRandomMap();
    }
}