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
}