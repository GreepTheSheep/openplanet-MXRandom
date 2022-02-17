namespace RMC
{
    bool IsRunning = false;

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
        int hours = time / 3600;
        int minutes = (time / 60) % 60;
        int seconds = time % 60;

        return (hours != 0 ? Text::Format("%02d", hours) + ":" : "" ) + (minutes != 0 ? Text::Format("%02d", minutes) + ":" : "") + Text::Format("%02d", seconds) + "." + Text::Format("%02d", hundreths);
    }

    void Start()
    {
        bool IsInited = false;
        MX::LoadRandomMap();
        while (!TM::IsMapLoaded()){
            sleep(100);
        }
        while (true){
            yield();
            CGamePlayground@ GamePlayground = cast<CGamePlayground>(GetApp().CurrentPlayground);
            if (GamePlayground !is null){
                if (!IsInited) {
                    Challenge.GoalMedalCount = 0;
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
                        Challenge.Running = true;
                    } else if (RMC::selectedGameMode == GameMode::Survival){
                        Survival.Running = true;
                    }
                    break;
                }
            }
        }
    }
}