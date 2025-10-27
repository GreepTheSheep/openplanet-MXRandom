// Random Map Challenge and Survival Leaderboard only for TMNEXT, made by FlinkTM with Greep
// Leaderboard URL: https://flinkblog.de/RMC/

#if TMNEXT
namespace RMCLeaderAPI {
    string AccountToken = "";
    string AccountId = "";
    uint lastTokenUpdate = Time::Now;
    const uint MAX_TOKEN_DURATION = 1 * 60 * 1000;

    string GetOpenplanetToken() {
        if (AccountToken == "" || Time::Now > lastTokenUpdate + MAX_TOKEN_DURATION) {
            lastTokenUpdate = Time::Now;
            Auth::PluginAuthTask@ task = Auth::GetToken();
            while (!task.Finished()) yield();

            if (!task.IsSuccess() || task.Token() == "") {
                Log::Warn("Account token fetching failed: " + task.Error());
                AccountToken = "";
            } else {
                AccountToken = task.Token();
            }
        }

        return AccountToken;
    }

    void FetchAccountId() {
        CTrackMania@ app = cast<CTrackMania@>(GetApp());

        while (app.LocalPlayerInfo is null || app.LocalPlayerInfo.WebServicesUserId == "") {
            Log::Warn("Failed to get account ID from local player - Retrying...");
            sleep(5000);
        }

        AccountId = app.LocalPlayerInfo.WebServicesUserId;
    }

    void postRMC(const int &in goal, const int &in belowGoal, Medals objective = Medals::Author) {
        if (!PluginSettings::RMC_PushLeaderboardResults || goal == 0) return; // Do nothing if setting disabled, or goals number is 0

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
        json["category"] = "standard"; // other categories not available yet

        Log::Trace("[PostRMC] Submitting RMC run to leaderboard.");
        Log::Trace("[PostRMC] Payload: " + Json::Write(json, true));

        int attempts = 0;

        while (attempts < 10) {
            attempts++;

            Json::Value@ res = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rmc.php", Json::Write(json), true);

            if (res.GetType() != Json::Type::Object) {
                // failed, retry
                Log::Warn("Posting RMC results failed: API didn't return an object. Retrying...");
                sleep(5000);
                continue;
            }

            if (res.HasKey("success")) {
                bool isSuccess = res["success"];

                string message = "";
                
                if (res.HasKey("message")) {
                    message = res["message"];
                } else if (res.HasKey("error")) {
                    message = res["error"];
                }

                if (isSuccess) {
                    Log::Info(message, true);
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
        json["category"] = "standard"; // other categories not available yet

        Log::Trace("[PostRMS] Submitting RMS run to leaderboard.");
        Log::Trace("[PostRMS] Payload: " + Json::Write(json, true));

        int attempts = 0;

        while (attempts < 10) {
            attempts++;

            Json::Value@ res = API::PostAsync(PluginSettings::RMC_Leaderboard_Url + "/api/rms.php", Json::Write(json), true);

            if (res.GetType() != Json::Type::Object) {
                // failed, retry
                Log::Warn("Posting RMS results failed: API didn't return an object. Retrying...");
                sleep(5000);
                continue;
            }

            if (res.HasKey("success")) {
                bool isSuccess = res["success"];
                string message = "";
                
                if (res.HasKey("message")) {
                    message = res["message"];
                } else if (res.HasKey("error")) {
                    message = res["error"];
                }

                if (isSuccess) {
                    Log::Info(message, true);
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