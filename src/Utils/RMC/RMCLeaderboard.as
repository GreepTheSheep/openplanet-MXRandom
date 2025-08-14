// Random Map Challenge and Survival Leaderboard only for TMNEXT, made by FlinkTM with Greep
// Leaderboard URL: https://flinkblog.de/RMC/

#if TMNEXT
namespace RMCLeaderAPI {
    bool connected = false;
    bool connectionError = false;
    bool connectionInProgress = false;
    int connectionAttempts = 0;
    int postingResultsAttempts = 0;
    string AccountToken = "";
    string AccountId = "";

    void Login() {
        if (connectionAttempts >= 5) {
            Log::Error("Too many failed connection attempts on the leaderboard API. Sending records are disabled for this time.", true);
            connectionError = true;
            connected = false;
            return;
        }

        connectionAttempts++;
        connectionInProgress = true;
        Log::Log("Starting Auth...");

        Auth::PluginAuthTask@ tokenTask = Auth::GetToken();

        while (!tokenTask.Finished()) yield();

        AccountToken = tokenTask.Token();

        if (Meta::IsDeveloperMode()) Log::Trace("Token: " + AccountToken);
        if (Meta::IsDeveloperMode()) Log::Log("Sending Token...");

        CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork>(GetApp().Network);
        AccountId = Network.PlayerInfo.WebServicesUserId;

        Json::Value@ serverJson = Json::Object();
        serverJson["token"] = AccountToken;
        serverJson["player_id"] = AccountId;
        serverJson["plugin_version"] = PLUGIN_VERSION;

        Json::Value@ serverRes = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/auth.php", Json::Write(serverJson));

        if (serverRes.HasKey("success")) {
            bool isSuccess = serverRes["success"];
            if (!isSuccess) {
                string errMsg = serverRes["message"];
                Log::Warn("Login failed: "+errMsg+" - Retrying...");
                sleep(5000);
                RMCLeaderAPI::Login();
            } else {
                string srvDisplayName = serverRes["player_name"];
                Log::Log("Connected! Display name: " + srvDisplayName, Meta::IsDeveloperMode());
                connectionError = false;
                connectionInProgress = false;
                connected = true;
            }
        } else {
            // failed, retry
            Log::Warn("Login failed: API returned unexpected values. Retrying...");
            sleep(5000);
            RMCLeaderAPI::Login();
            return;
        }
    }

    void postRMC(const int &in goal, const int &in belowGoal, Medals objective = Medals::Author) {
        if (!PluginSettings::RMC_PushLeaderboardResults || goal == 0) return; // Do nothing if setting disabled, or goals number is 0

        if (!connected) {
            // Retry login
            connectionError = false;
            connectionAttempts = 0;
            Login();
        }

#if SIG_SCHOOL
        if (!Meta::IsSchoolModeWhitelisted()) {
            Log::Error("School mode is enabled, the results will not be uploaded to the leaderboard", true);
            return;
        }
#endif

        if (PluginSettings::CustomRules) {
            Log::Warn("Custom rules is enabled, the results will not be uploaded to the leaderboard", true);
            return;
        }

        if (postingResultsAttempts >= 10) {
            Log::Error("Too many failed attempts on posting results on the leaderboard.", true);
            postingResultsAttempts = 0;
            return;
        }

        postingResultsAttempts++;
        string objectiveFormatted = tostring(objective).ToLower();

        Json::Value@ serverJson = Json::Object();
        serverJson["accountId"] = AccountId;
        serverJson["objective"] = objectiveFormatted;
        serverJson["goal"] = goal;
        serverJson["below_goal"] = belowGoal;

        Json::Value@ serverRes = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rmc.php", Json::Write(serverJson));

        if (serverRes.GetType() != Json::Type::Object) {
            // failed, retry
            Log::Warn("Posting RMC results failed: API didn't return an object. Retrying...");
            sleep(5000);
            RMCLeaderAPI::postRMC(goal, belowGoal, objective);
            return;
        }

        if (serverRes.HasKey("success")) {
            bool isSuccess = serverRes["success"];
            if (!isSuccess) {
                string errMsg = serverRes["message"];
                Log::Warn("Posting RMC results failed: "+errMsg+"\n Retrying...");
                sleep(5000);
                RMCLeaderAPI::postRMC(goal, belowGoal, objective);
            } else {
                string message = serverRes["message"];
                Log::Log(message, true);
            }
        } else {
            // failed, retry
            Log::Warn("Posting RMC results failed: API returned unexpected values. Retrying...");
            sleep(5000);
            RMCLeaderAPI::postRMC(goal, belowGoal, objective);
            return;
        }
    }

    void postRMS(const int &in goal, const int &in skips, const int &in survivedTime, Medals objective = Medals::Author) {
        if (!PluginSettings::RMC_PushLeaderboardResults || goal == 0) return; // Do nothing if setting disabled, or goals number is 0

        if (!connected) {
            // Retry login
            connectionError = false;
            connectionAttempts = 0;
            Login();
        }

#if SIG_SCHOOL
        if (!Meta::IsSchoolModeWhitelisted()) {
            Log::Error("School mode is enabled, the results will not be uploaded to the leaderboard", true);
            return;
        }
#endif

        if (PluginSettings::CustomRules) {
            Log::Warn("Custom rules is enabled, the results will not be uploaded to the leaderboard", true);
            return;
        }

        if (postingResultsAttempts >= 10) {
            Log::Error("Too many failed attempts on posting results on the leaderboard.", true);
            postingResultsAttempts = 0;
            return;
        }

        postingResultsAttempts++;
        int survivedTimeSeconds = survivedTime / 1000;
        string objectiveFormatted = tostring(objective).ToLower();

        Json::Value@ serverJson = Json::Object();
        serverJson["accountId"] = AccountId;
        serverJson["objective"] = objectiveFormatted;
        serverJson["goal"] = goal;
        serverJson["skips"] = skips;
        serverJson["time_survived"] = survivedTimeSeconds;

        Json::Value@ serverRes = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rms.php", Json::Write(serverJson));

        if (serverRes.GetType() != Json::Type::Object) {
            // failed, retry
            Log::Warn("Posting RMS results failed: API didn't return an object. Retrying...");
            sleep(5000);
            RMCLeaderAPI::postRMS(goal, skips, survivedTime, objective);
            return;
        }

        if (serverRes.HasKey("success")) {
            bool isSuccess = serverRes["success"];
            if (!isSuccess) {
                string errMsg = serverRes["message"];
                Log::Warn("Posting RMS results failed: "+errMsg+"\n Retrying...");
                sleep(5000);
                RMCLeaderAPI::postRMS(goal, skips, survivedTime, objective);
            } else {
                string message = serverRes["message"];
                Log::Log(message, true);
            }
        } else {
            // failed, retry
            Log::Warn("Posting RMS results failed: API returned unexpected values. Retrying...");
            sleep(5000);
            RMCLeaderAPI::postRMS(goal, skips, survivedTime, objective);
            return;
        }
    }
}
#endif