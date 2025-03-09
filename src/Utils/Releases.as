namespace GH
{
    array<Release@> Releases;
    Net::HttpRequest@ ReleasesReq;
    bool releasesRequestError = false;

    class Release
    {
        string api_url;
        string page_url;
        string tag_name;
        string name;
        bool draft;
        bool prerelease;
        string created_at;
        string published_at;
        string body;

        Release(const Json::Value &in json)
        {
            api_url = json["url"];
            page_url = json["html_url"];
            tag_name = json["tag_name"];
            name = json["name"];
            draft = json["draft"];
            prerelease = json["prerelease"];
            created_at = json["created_at"];
            published_at = json["published_at"];
            body = json["body"];
        }
    }

    void StartReleasesReq()
    {
        string url = "https://api.github.com/repos/"+GITHUB_REPO_FULLNAME+"/releases";
        @ReleasesReq = API::Get(url);
    }

    void CheckReleasesReq()
    {
        // If there's a request, check if it has finished
        if (ReleasesReq !is null && ReleasesReq.Finished()) {
            // Parse the response
            string res = ReleasesReq.String();
            auto json = ReleasesReq.Json();
            @ReleasesReq = null;

            Log::Trace("Releases::CheckRequest : " + res);

            if (json.GetType() != Json::Type::Array || json.Length == 0) {
                print("Releases::CheckRequest : Error parsing response");
                releasesRequestError = true;
                return;
            }

            // Handle the response
            for (uint i = 0; i < json.Length; i++)
            {
                Json::Value RelJson = json[i];
                Release@ ReleaseData = Release(RelJson);
                Releases.InsertLast(ReleaseData);
            }
        }
    }
}