namespace MX {
    void FetchMapTags() {
        m_mapTags.RemoveRange(0, m_mapTags.Length);
        APIRefreshing = true;

        Json::Value resNet = API::GetAsync(PluginSettings::RMC_MX_Url + "/api/meta/tags");

        try {
            for (uint i = 0; i < resNet.Length; i++) {
                int tagID = resNet[i]["ID"];
                string tagName = resNet[i]["Name"];

                Log::Trace("Loading tag #" + tagID + " - " + tagName);

                m_mapTags.InsertLast(MapTag(resNet[i]));
            }

            m_mapTags.Sort(function(a,b) { return a.Name < b.Name; });

            Log::Trace(m_mapTags.Length + " tags loaded");
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