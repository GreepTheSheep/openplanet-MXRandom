namespace Migration
{
    Json::Value RecentlyPlayedJson = Json::FromFile(IO::FromDataFolder("TMXRandom_PlayedMaps.json"));
    Net::HttpRequest@ n_request;
    array<MX::MapInfo@> RecentlyPlayed;
    bool requestError = false;

    array<int> GetLastestPlayedMapsMXId()
    {
        array<int> MXIds;
        if (RecentlyPlayedJson.GetType() != Json::Type::Array) return MXIds;

        for (uint i = 0; i < RecentlyPlayedJson.Length; i++)
        {
            Json::Value MapJson = RecentlyPlayedJson[i];
            int MapId = MapJson["MXID"];
            MXIds.InsertLast(MapId);
        }
        return MXIds;
    }

    void StartRequestMapsInfo(array<int> MXIds)
    {
        array<MX::MapInfo@> Maps;
        string url = "https://"+MX_URL+"/api/maps/get_map_info/multi/";
        string mapIdsStr = "";

        for (uint i = 0; i < MXIds.Length; i++)
        {
            mapIdsStr += tostring(MXIds[i]);
            if (i < MXIds.Length - 1) mapIdsStr += ",";
        }
        Log::Trace("Migration::SendRequest : " + url + mapIdsStr);
        @n_request = API::Get(url + mapIdsStr);
    }

    void CheckMXRequest()
    {
        // If there's a request, check if it has finished
        if (n_request !is null && n_request.Finished()) {
            // Parse the response
            string res = n_request.String();
            Log::Trace("Migration::CheckRequest : " + res);
            auto json = Json::Parse(res);

            if (json.get_Length() == 0) {
                print("Migration::CheckRequest : Error parsing response");
                requestError = true;
                return;
            }

            // Handle the response
            for (uint i = 0; i < json.get_Length(); i++)
            {
                Json::Value MapJson = json[i];
                MX::MapInfo@ Map = MX::MapInfo(MapJson);
                RecentlyPlayed.InsertLast(Map);
            }
            @n_request = null;
        }
    }

    void SaveToDataFile()
    {
        IO::Move(IO::FromDataFolder("TMXRandom_Data.json"), DATA_JSON_LOCATION);
        DataJsonOldVersion["recentlyPlayed"] = Json::Array();
        for (uint i = 0; i < RecentlyPlayed.Length; i++)
        {
            Json::Value MapJson = RecentlyPlayed[i].ToJson();
            DataJsonOldVersion["recentlyPlayed"].Add(MapJson);
        }
        Json::ToFile(DATA_JSON_LOCATION, DataJsonOldVersion);
        IO::Delete(IO::FromDataFolder("TMXRandom_PlayedMaps.json"));
    }
}