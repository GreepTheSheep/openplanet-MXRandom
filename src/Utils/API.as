namespace API
{
    Net::HttpRequest@ Get(const string &in url)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
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
        return Json::Parse(req.String());
    }

    Net::HttpRequest@ Post(const string &in url, const string &in body)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Post;
        ret.Url = url;
        ret.Body = body;
        ret.Headers.Set("Content-Type", "application/json");
        Log::Trace("Post: " + url);
        Log::Trace("Body: " + body);
        ret.Start();
        return ret;
    }

    Json::Value GetAsync(const string &in url, const string &in body)
    {
        auto req = Post(url, body);
        while (!req.Finished()) {
            yield();
        }
        return Json::Parse(req.String());
    }
}