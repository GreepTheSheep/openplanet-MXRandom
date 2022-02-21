namespace MX
{
    void FetchMapTags()
    {
        m_mapTags.RemoveRange(0, m_mapTags.Length);
        APIRefreshing = true;

        Json::Value resNet = API::GetAsync("https://"+MX_URL+"/api/tags/gettags");

        try {
            for (uint i = 0; i < resNet.get_Length(); i++)
            {
                int tagID = resNet[i]["ID"];
                string tagName = resNet[i]["Name"];

                Log::Trace("Loading tag #"+tagID+" - "+tagName);

                m_mapTags.InsertLast(MapTag(resNet[i]));
            }

            print(m_mapTags.get_Length() + " tags loaded");
            APIDown = false;
            APIRefreshing = false;
        } catch {
            Log::Warn("Error while loading tags");
            Log::Error(MX_NAME + " API is not responding, it might be down.", true);
            APIDown = true;
            APIRefreshing = false;
        }
    }
}