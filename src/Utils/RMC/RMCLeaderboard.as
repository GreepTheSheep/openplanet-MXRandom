// Random Map Challenge and Survival Leaderboard only for TMNEXT, made by FlinkTM with Greep
// Leaderboard URL: https://flinkblog.de/RMC/

#if TMNEXT
namespace RMCLeaderAPI {
    bool connected = false;
    bool connectionError = false;
    bool connectionInProgress = false;
    int connectionAttempts = 0;
    string AccountToken = "";
    string AccountId = "";

    void Login() {
        if (connectionAttempts >= 5) {
            Log::Error("Too many failed attempts, leaderboard will not be enabled for this time.");
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
            Log::Warn("Login failed. Retrying...");
            sleep(5000);
            RMCLeaderAPI::Login();
        }
    }

    void postRMC(const int &in goal, const int &in belowGoal, const string &in objective = "author") {
        if (!PluginSettings::RMC_PushLeaderboardResults || !connected || PluginSettings::CustomRules) return; // Do nothing if not connected, or setting disabled, or Custom Rules enabled

        string objectiveFormatted = "author";
        if (objective == "World Record") objectiveFormatted = "wr";
        else objectiveFormatted = objective.ToLower();

        Json::Value@ serverJson = Json::Object();
        serverJson["accountId"] = AccountToken;
        serverJson["objective"] = objectiveFormatted;
        serverJson["goal"] = goal;
        serverJson["below_goal"] = belowGoal;

        Json::Value@ serverRes = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rmc.php", Json::Write(serverJson));

        if (serverRes.HasKey("success")) {
            bool isSuccess = serverRes["success"];
            if (!isSuccess) {
                string errMsg = serverRes["message"];
                Log::Warn("Posting RMC results failed: "+errMsg+"\n Retrying...");
                sleep(5000);
                RMCLeaderAPI::postRMC(goal, belowGoal, objective);
            } else {
                string message = serverRes["message"];
                Log::Log(message, Meta::IsDeveloperMode());
            }
        } else {
            // failed, retry
            Log::Warn("Posting RMC results failed. Retrying...");
            sleep(5000);
            RMCLeaderAPI::postRMC(goal, belowGoal, objective);
        }
    }

    void postRMS(const int &in goal, const int &in skips, const int &in survivedTime, const string &in objective = "author") {
        if (!PluginSettings::RMC_PushLeaderboardResults || !connected || PluginSettings::CustomRules) return; // Do nothing if not connected, or setting disabled, or Custom Rules enabled

        int survivedTimeSeconds = survivedTime / 1000;
        string objectiveFormatted = "author";

        if (objective == "World Record") objectiveFormatted = "wr";
        else objectiveFormatted = objective.ToLower();

        Json::Value@ serverJson = Json::Object();
        serverJson["accountId"] = AccountToken;
        serverJson["objective"] = objectiveFormatted;
        serverJson["goal"] = goal;
        serverJson["skips"] = skips;
        serverJson["time_survived"] = survivedTimeSeconds;

        Json::Value@ serverRes = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rms.php", Json::Write(serverJson));

        if (serverRes.HasKey("success")) {
            bool isSuccess = serverRes["success"];
            if (!isSuccess) {
                string errMsg = serverRes["message"];
                Log::Warn("Posting RMS results failed: "+errMsg+"\n Retrying...");
                sleep(5000);
                RMCLeaderAPI::postRMS(goal, skips, survivedTime, objective);
            } else {
                string message = serverRes["message"];
                Log::Log(message, Meta::IsDeveloperMode());
            }
        } else {
            // failed, retry
            Log::Warn("Posting RMS results failed. Retrying...");
            sleep(5000);
            RMCLeaderAPI::postRMS(goal, skips, survivedTime, objective);
        }
    }
}
#endif