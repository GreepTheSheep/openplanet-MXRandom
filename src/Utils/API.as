namespace API
{
    Net::HttpRequest@ Get(const string &in url)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
#if TMNEXT
        if (url.StartsWith(PluginSettings::RMC_Leaderboard_Url) && RMCLeaderAPI::connected && RMCLeaderAPI::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Token " + RMCLeaderAPI::AccountToken);
        }
#endif
        Log::Trace("Get: " + url);
        ret.Start();
        return ret;
    }

    Json::Value GetAsync(const string &in url)
    {
        auto req = Get(url);
        while (!req.Finished()) {
            yield();
        }
        string res = req.String();
        if (IS_DEV_MODE) Log::Trace("Code: " + req.ResponseCode() + " - Get Res: " + res);
        return req.Json();
    }

    Net::HttpRequest@ Post(const string &in url, const string &in body)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Post;
        ret.Url = url;
#if TMNEXT
        if (url.StartsWith(PluginSettings::RMC_Leaderboard_Url) && RMCLeaderAPI::connected && RMCLeaderAPI::AccountToken.Length > 0) {
            ret.Headers.Set("Authorization", "Token " + RMCLeaderAPI::AccountToken);
        }
#endif
        ret.Body = body;
        ret.Headers.Set("Content-Type", "application/json");
        Log::Trace("Post: " + url);
        ret.Start();
        return ret;
    }

    Json::Value PostAsync(const string &in url, const string &in body)
    {
        auto req = Post(url, body);
        while (!req.Finished()) {
            yield();
        }
        string res = req.String();
        if (IS_DEV_MODE) Log::Trace("Code: " + req.ResponseCode() + " - Post Res: " + res);
        return req.Json();
    }
}