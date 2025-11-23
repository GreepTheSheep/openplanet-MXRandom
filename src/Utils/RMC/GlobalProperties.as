namespace RMC {
    bool ShowTimer = false;
    Json::Value CurrentRunData = Json::Object();
    RMCConfig@ config = RMCConfig();

    RMC@ currentRun = RMC();

    enum GameMode {
        Challenge,
        Survival,
        Objective,
        Together
    }

    enum Category {
        Standard,
        Classic,
        Nadeo,
#if TMNEXT
        TOTD,
        Altcar,
#endif
        Custom
    }

    const array<string> CategoryDescriptions = {
        "The standard game mode, with all current rules and settings.",
#if TMNEXT
        "Play RMC with the old rules. Altered Nadeo and low effort maps will be included.",
        "Play exclusively maps made by Nadeo. Includes all seasonal campaigns, Training, altcar discovery campaigns, and more!",
        "Play all Tracks of the Day since the game was released!",
        "Want to know how RMC would look like back in 2003? In the Altcar category, you will only play maps featuring the snow, desert, and rally cars!",
#else
        "Play RMC with the old rules. Low effort maps will be included.",
        "Play exclusively maps made by Nadeo!",
#endif
        "Customize your experience by tweaking settings and filters."
    };

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
}