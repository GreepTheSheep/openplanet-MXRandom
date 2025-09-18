namespace API {
    Net::HttpRequest@ Get(const string &in url) {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
#if TMNEXT
        if (url.StartsWith(PluginSettings::RMC_Leaderboard_Url) && RMCLeaderAPI::IsConnected && RMCLeaderAPI::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Token " + RMCLeaderAPI::AccountToken);
        }
#endif
        Log::Trace("[API::Get] Request URL: " + url);
        ret.Start();
        return ret;
    }

    Json::Value GetAsync(const string &in url) {
        auto req = Get(url);
        while (!req.Finished()) {
            yield();
        }
        string res = req.String();
        Log::Trace("[API::GetAsync] Response code: " + req.ResponseCode() + " - Response: " + res);
        return req.Json();
    }

    Net::HttpRequest@ Post(const string &in url, const string &in body) {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Post;
        ret.Url = url;
#if TMNEXT
        if (url.StartsWith(PluginSettings::RMC_Leaderboard_Url) && RMCLeaderAPI::IsConnected && RMCLeaderAPI::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Token " + RMCLeaderAPI::AccountToken);
        }
#endif
        ret.Body = body;
        ret.Headers.Set("Content-Type", "application/json");
        Log::Trace("[API::Post] Request URL: " + url);
        ret.Start();
        return ret;
    }

    Json::Value PostAsync(const string &in url, const string &in body) {
        auto req = Post(url, body);
        while (!req.Finished()) {
            yield();
        }
        string res = req.String();
        Log::Trace("[API::PostAsync] Response code: " + req.ResponseCode() + " - Response: " + res);
        return req.Json();
    }
}