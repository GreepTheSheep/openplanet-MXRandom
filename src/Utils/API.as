namespace API
{
    Net::HttpRequest@ Get(const string &in url)
    {
        auto ret = Net::HttpRequest();
        ret.Method = Net::HttpMethod::Get;
        ret.Url = url;
        if (url.StartsWith(OnlineServices::API_URL) && OnlineServices::authentificationToken.Length != 0) ret.Headers.Set("Authorization", OnlineServices::authentificationToken);
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
}