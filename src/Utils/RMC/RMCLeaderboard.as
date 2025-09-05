// Random Map Challenge and Survival Leaderboard only for TMNEXT, made by FlinkTM with Greep
// Leaderboard URL: https://flinkblog.de/RMC/

#if TMNEXT
namespace RMCLeaderAPI {
    string AccountToken = "";
    string AccountId = "";
    ConnectionStatus Status = ConnectionStatus::Not_Connected;

    enum ConnectionStatus {
        Not_Connected,
        Connecting,
        Connected,
        Error
    }

    bool get_IsConnected() {
        return Status == ConnectionStatus::Connected;
    }

    bool get_IsConnecting() {
        return Status == ConnectionStatus::Connecting;
    }

    bool get_IsError() {
        return Status == ConnectionStatus::Error;
    }

    void Login() {
        if (IsConnected) return;

        CTrackMania@ app = cast<CTrackMania@>(GetApp());

        Status = ConnectionStatus::Connecting;
        int connectionAttempts = 0;

        while (!IsConnected && connectionAttempts < 5)  {
            connectionAttempts++;

            Log::Log("Starting Auth...");

            if (AccountToken == "") {
                Auth::PluginAuthTask@ tokenTask = Auth::GetToken();

                while (!tokenTask.Finished()) yield();

                if (!tokenTask.IsSuccess() || tokenTask.Token() == "") {
                    Log::Warn("Account token fetching failed: " + tokenTask.Error() + " - Retrying...");
                    sleep(5000);
                    continue;
                }

                AccountToken = tokenTask.Token();
            }

            if (app.LocalPlayerInfo is null || app.LocalPlayerInfo.WebServicesUserId == "") {
                Log::Warn("Failed to get account ID from local player - Retrying...");
                sleep(5000);
                continue;
            }

            AccountId = app.LocalPlayerInfo.WebServicesUserId;

#if SIG_DEVELOPER
            Log::Trace("Token: " + AccountToken);
            Log::Log("Sending Token...");
#endif

            Json::Value@ json = Json::Object();
            json["token"] = AccountToken;
            json["player_id"] = AccountId;
            json["plugin_version"] = PLUGIN_VERSION;

            Json::Value@ res = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/auth.php", Json::Write(json));

            if (res.HasKey("success")) {
                bool isSuccess = res["success"];

                if (isSuccess) {
                    string srvDisplayName = res["player_name"];
                    Log::Log("Connected! Display name: " + srvDisplayName, Meta::IsDeveloperMode());
                    Status = ConnectionStatus::Connected;
                    return;
                } else {
                    string errMsg = res["message"];
                    Log::Warn("Login failed: " + errMsg + " - Retrying...");
                    sleep(5000);
                }
            } else {
                // failed, retry
                Log::Warn("Login failed: API returned unexpected values. Retrying...");
                sleep(5000);
            }
        }

        if (!IsConnected) {
            Log::Error("Too many failed connection attempts on the leaderboard API. Sending records are disabled for this time.", true);
            Status = ConnectionStatus::Error;
        }
    }

    void postRMC(const int &in goal, const int &in belowGoal, Medals objective = Medals::Author) {
        if (!PluginSettings::RMC_PushLeaderboardResults || goal == 0) return; // Do nothing if setting disabled, or goals number is 0

        if (!IsConnected) {
            // Retry login
            Login();
        }

        if (IsError) {
            Log::Error("Failed to post RMC results: Couldn't connect to the leaderboard API.", true);
            return;
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

        Json::Value@ json = Json::Object();
        json["accountId"] = AccountId;
        json["objective"] = tostring(objective).ToLower();
        json["goal"] = goal;
        json["below_goal"] = belowGoal;

        int attempts = 0;

        while (attempts < 10) {
            attempts++;

            Json::Value@ res = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rmc.php", Json::Write(json));

            if (res.GetType() != Json::Type::Object) {
                // failed, retry
                Log::Warn("Posting RMC results failed: API didn't return an object. Retrying...");
                sleep(5000);
                continue;
            }

            if (res.HasKey("success")) {
                bool isSuccess = res["success"];
                string message = res["message"];

                if (isSuccess) {
                    Log::Log(message, true);
                    return;
                } else {
                    Log::Warn("Posting RMC results failed: " + message + " - Retrying...");
                    sleep(5000);
                    continue;
                }
            } else {
                // failed, retry
                Log::Warn("Posting RMC results failed: API returned unexpected values. Retrying...");
                sleep(5000);
                continue;
            }
        }

        Log::Error("Too many failed attempts on posting results on the leaderboard.", true);
    }

    void postRMS(const int &in goal, const int &in skips, const int &in survivedTime, Medals objective = Medals::Author) {
        if (!PluginSettings::RMC_PushLeaderboardResults || goal == 0) return; // Do nothing if setting disabled, or goals number is 0

        if (!IsConnected) {
            // Retry login
            Login();
        }

        if (IsError) {
            Log::Error("Failed to post RMS results: Couldn't connect to the leaderboard API.", true);
            return;
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

        Json::Value@ json = Json::Object();
        json["accountId"] = AccountId;
        json["objective"] = tostring(objective).ToLower();
        json["goal"] = goal;
        json["skips"] = skips;
        json["time_survived"] = survivedTime / 1000;

        int attempts = 0;

        while (attempts < 10) {
            attempts++;

            Json::Value@ res = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rms.php", Json::Write(json));

            if (res.GetType() != Json::Type::Object) {
                // failed, retry
                Log::Warn("Posting RMS results failed: API didn't return an object. Retrying...");
                sleep(5000);
                continue;
            }

            if (res.HasKey("success")) {
                bool isSuccess = res["success"];
                string message = res["message"];

                if (isSuccess) {
                    Log::Log(message, true);
                    return;
                } else {
                    Log::Warn("Posting RMS results failed: " + message + " - Retrying...");
                    sleep(5000);
                    continue;
                }
            } else {
                // failed, retry
                Log::Warn("Posting RMS results failed: API returned unexpected values. Retrying...");
                sleep(5000);
                continue;
            }
        }

        Log::Error("Too many failed attempts on posting results on the leaderboard.", true);
    }
}
#endif