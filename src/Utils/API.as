namespace API {
    Net::HttpRequest@ Get(const string &in url, bool openplanetAuth = false) {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;

#if TMNEXT
        if (openplanetAuth) {
            string token = RMCLeaderAPI::GetOpenplanetToken();
            ret.Headers.Set("Authorization", "Token " + token);
        }
#endif

        Log::Trace("[API::Get] Request URL: " + url);
        ret.Start();
        return ret;
    }

    Json::Value GetAsync(const string &in url, bool openplanetAuth = false) {
        auto req = Get(url, openplanetAuth);
        while (!req.Finished()) {
            yield();
        }
        string res = req.String();
        Log::Trace("[API::GetAsync] Response code: " + req.ResponseCode() + " - Response: " + res);
        return req.Json();
    }

    Net::HttpRequest@ Post(const string &in url, const string &in body, bool openplanetAuth = false) {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Post;
        ret.Url = url;

#if TMNEXT
        if (openplanetAuth) {
            string token = RMCLeaderAPI::GetOpenplanetToken();
            ret.Headers.Set("Authorization", "Token " + token);
        }
#endif

        ret.Body = body;
        ret.Headers.Set("Content-Type", "application/json");
        Log::Trace("[API::Post] Request URL: " + url);
        ret.Start();
        return ret;
    }

    Json::Value PostAsync(const string &in url, const string &in body, bool openplanetAuth = false) {
        auto req = Post(url, body, openplanetAuth);
        while (!req.Finished()) {
            yield();
        }
        string res = req.String();
        Log::Trace("[API::PostAsync] Response code: " + req.ResponseCode() + " - Response: " + res);
        return req.Json();
    }
}