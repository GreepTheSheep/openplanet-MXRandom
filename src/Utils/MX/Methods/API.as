namespace MX {
    array<MapInfo@> GetMappackMaps(int mappackId) {
        array<MapInfo@> maps;
        bool moreMaps = true;
        int lastId = 0;

        while (moreMaps) {
            string reqUrl = PluginSettings::RMC_MX_Url + "/api/maps?count=1000&fields=" + MAP_FIELDS + "&mappackid=" + mappackId;
            if (moreMaps && lastId != 0) reqUrl += "&after=" + lastId;

            try {
                Json::Value json = API::GetAsync(reqUrl);

                if (json.GetType() == Json::Type::Null || !json.HasKey("Results")) {
                    Log::Error("Something went wrong while fetching maps from mappack ID #" + mappackId, true);
                    Log::Debug(Json::Write(json));

                    return maps;
                }
                
                if (json["Results"].Length == 0) {
                    if (maps.IsEmpty()) {
                        Log::Error("Found 0 maps for mappack ID #" + mappackId + ". Mappack might not exist or is empty", true);
                    }

                    return maps;
                }

                Json::Value@ items = json["Results"];
                moreMaps = json["More"];

                for (uint i = 0; i < items.Length; i++) {
                    MapInfo@ info = MapInfo(items[i]);
                    maps.InsertLast(info);

                    if (moreMaps && i == items.Length - 1) {
                        lastId = info.MapId;
                    }
                }

                if (moreMaps) {
                    sleep(1000);
                }
            } catch {
                Log::Error("An error occurred while fetching the maps from mappack ID #" + mappackId + ": " + getExceptionInfo(), true);
                return array<MapInfo@>();
            }
        }

        Log::Info("Found " + maps.Length + " maps from mappack ID #" + mappackId);
        return maps;
    }

    void FetchMapTags() {
        m_mapTags.RemoveRange(0, m_mapTags.Length);
        APIRefreshing = true;

        try {
            Json::Value res = API::GetAsync(PluginSettings::RMC_MX_Url + "/api/meta/tags");
            
            for (uint i = 0; i < res.Length; i++) {
                MapTag@ tag = MapTag(res[i]);

                Log::Trace("[FetchMapTags] Loading tag #" + tag.ID + " - " + tag.Name);

                m_mapTags.InsertLast(tag);
            }

            m_mapTags.Sort(function(a, b) { return a.Name < b.Name; });

            Log::Trace(m_mapTags.Length + " tags loaded");
            APIDown = false;
            APIRefreshing = false;
        } catch {
            Log::Warn("[FetchMapTags] Error while loading tags: " + getExceptionInfo());
            Log::Error(MX_NAME + " API is not responding, it might be down.", true);
            APIDown = true;
            APIRefreshing = false;
        }
    }

    void GetImpossibleMaps() {
        array<MapInfo@> mappackMaps = GetMappackMaps(3164);

        if (mappackMaps.IsEmpty()) {
            Log::Error("Failed to get maps from the \"Broken/Cheated/Impossible ATs\" mappack.");
            return;
        }

        Log::Info("Found " + mappackMaps.Length + " impossible maps on TMX");
        impossibleMaps = mappackMaps;
    }
}
