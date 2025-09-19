namespace RMC {
    bool ShowTimer = false;
    Json::Value CurrentRunData = Json::Object();
    RMCConfig@ config;

    RMC@ currentRun = RMC();

    enum GameMode {
        Challenge,
        Survival,
        Objective,
        Together
    }

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