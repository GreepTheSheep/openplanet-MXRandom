namespace Migration {
    // Migrates data to version 2 of the plugin

    Json::Value RecentlyPlayedJson = Json::FromFile(IO::FromDataFolder("TMXRandom_PlayedMaps.json"));
    Net::HttpRequest@ n_request;
    array<MX::MapInfo@> RecentlyPlayed;
    bool requestError = false;

    array<int> GetLastestPlayedMapsMXId() {
        array<int> MXIds;
        if (RecentlyPlayedJson.GetType() != Json::Type::Array) return MXIds;

        for (uint i = 0; i < RecentlyPlayedJson.Length; i++) {
            Json::Value MapJson = RecentlyPlayedJson[i];
            int MapId = MapJson["MXID"];
            MXIds.InsertLast(MapId);
        }
        return MXIds;
    }

    void StartRequestMapsInfo(array<int> MXIds) {
        array<MX::MapInfo@> Maps;
        string url = PluginSettings::RMC_MX_Url + "/api/maps?fields=" + MAP_FIELDS + "&count=50&id=";
        string mapIdsStr = "";

        for (uint i = 0; i < MXIds.Length; i++) {
            mapIdsStr += tostring(MXIds[i]);
            if (i < MXIds.Length - 1) mapIdsStr += ",";
        }

        @n_request = API::Get(url + mapIdsStr);
    }

    void CheckMXRequest() {
        // If there's a request, check if it has finished
        if (n_request !is null && n_request.Finished()) {
            // Parse the response
            string res = n_request.String();
            auto json = n_request.Json();

            Log::Trace("[Migration::CheckRequest] Response: " + res);

            if (json.GetType() != Json::Type::Object) {
                Log::Error("[Migration::CheckRequest] Json is not an object", true);
                requestError = true;
                return;
            }

            if (json.Length == 0 || !json.HasKey("Results") || json["Results"].Length == 0) {
                Log::Error("[Migration::CheckRequest] Error parsing response", true);
                requestError = true;
                return;
            }

            Json::Value@ maps = json["Results"];

            // Handle the response
            for (uint i = 0; i < maps.Length; i++) {
                MX::MapInfo@ Map = MX::MapInfo(maps[i]);
                RecentlyPlayed.InsertLast(Map);
            }
            @n_request = null;
        }
    }

    void SaveToDataFile() {
        DataManager::InitData(false);

        for (uint i = 0; i < RecentlyPlayed.Length; i++) {
            Json::Value MapJson = RecentlyPlayed[i].ToJson();
            DataJson["recentlyPlayed"].Add(MapJson);
        }

        DataManager::SaveData();

        string oldFile = IO::FromDataFolder("TMXRandom_PlayedMaps.json");

        if (IO::FileExists(oldFile)) {
            IO::Delete(oldFile);
        }
    }

    // Migrates data and settings to MX 2.0

    [Setting hidden]
    bool MigratedToMX2 = false;

    Net::HttpRequest@ v2_request;
    bool v2_requestError;
    array<string> oldSaves = IO::IndexFolder(SAVE_DATA_LOCATION, true);
    array<MX::MapInfo@> v2_maps;

    void MigrateMX1Settings() {
        if (PluginSettings::RMC_MX_Url == "https://map-monitor.xk.io") {
            PluginSettings::RMC_MX_Url = MX_URL;
        }

        if (PluginSettings::MapAuthor.Contains(",")) {
            // MX 2.0 doesn't allow filtering by multiple authors yet
            PluginSettings::MapAuthor = PluginSettings::MapAuthor.Split(",")[0];
        }
    }

    array<int> GetMX1MapsId() {
        array<int> MXIds;

        for (uint f = 0; f < oldSaves.Length; f++) {
            Json::Value@ save = Json::FromFile(oldSaves[f]);

            if (save.HasKey("MapData")) {
                Json::Value@ mapData = save["MapData"];

                if (mapData.HasKey("TrackID") && MXIds.Find(mapData["TrackID"]) == -1) {
                    MXIds.InsertLast(mapData["TrackID"]);
                }
            }
        }

        if (DataJson.GetType() == Json::Type::Null) return MXIds;

        for (uint i = 0; i < DataJson["recentlyPlayed"].Length; i++) {
            Json::Value@ map = DataJson["recentlyPlayed"][i];

            if (map.HasKey("TrackID") && MXIds.Find(map["TrackID"]) == -1) {
                MXIds.InsertLast(map["TrackID"]);
            }
        }

        return MXIds;
    }

    void StartMX2RequestMapsInfo(array<int> MXIds) {
        array<MX::MapInfo@> Maps;
        string url = PluginSettings::RMC_MX_Url + "/api/maps?fields=" + MAP_FIELDS + "&count=" + MXIds.Length + "&id=";
        string mapIdsStr = "";

        for (uint i = 0; i < MXIds.Length; i++) {
            mapIdsStr += tostring(MXIds[i]);
            if (i < MXIds.Length - 1) mapIdsStr += ",";
        }

        @v2_request = API::Get(url + mapIdsStr);
    }

    void CheckMX2MigrationRequest() {
        if (v2_request !is null && v2_request.Finished()) {
            string res = v2_request.String();
            auto json = v2_request.Json();

            Log::Trace("[Migration::CheckV2MXRequest] Response: " + res);

            if (json.GetType() != Json::Type::Object) {
                Log::Error("[Migration::CheckV2MXRequest] Json is not an object", true);
                v2_requestError = true;
                return;
            }

            if (json.Length == 0 || !json.HasKey("Results") || json["Results"].Length == 0) {
                Log::Error("[Migration::CheckV2MXRequest] Error parsing response", true);
                v2_requestError = true;
                return;
            }

            Json::Value@ maps = json["Results"];

            for (uint i = 0; i < maps.Length; i++) {
                MX::MapInfo@ Map = MX::MapInfo(maps[i]);
                v2_maps.InsertLast(Map);
            }

            @v2_request = null;
        }
    }

    void UpdateData() {
        for (uint f = 0; f < oldSaves.Length; f++) {
            Json::Value@ save = Json::FromFile(oldSaves[f]);

            if (save.HasKey("MapData")) {
                Json::Value@ mapData = save["MapData"];

                if (mapData.HasKey("TrackID")) {
                    for (uint i = 0; i < v2_maps.Length; i++) {
                        MX::MapInfo@ currMap = v2_maps[i];

                        if (mapData["TrackID"] == currMap.MapId) {
                            if (mapData["PlayedAt"].GetType() == Json::Type::Object) {
                                currMap.PlayedAt = Date::TimestampFromObject(mapData["PlayedAt"]);
                            } else {
                                // Rare case where PlayedAt isn't an object
                                currMap.PlayedAt = Time::Stamp;
                            }
                            save["MapData"] = currMap.ToJson();

                            Json::ToFile(oldSaves[f], save);
                            break;
                        }
                    }
                }
            }
        }

        Json::Value oldPlayed = DataJson["recentlyPlayed"];
        DataManager::InitData(false);

        for (uint p = 0; p < oldPlayed.Length; p++) {
            Json::Value@ oldMap = oldPlayed[p];

            if (oldMap.HasKey("TrackID")) {
                for (uint i = 0; i < v2_maps.Length; i++) {
                    MX::MapInfo@ map = v2_maps[i];

                    if (map.MapId == oldMap["TrackID"]) {
                        if (oldMap["PlayedAt"].GetType() == Json::Type::Object) {
                            map.PlayedAt = Date::TimestampFromObject(oldMap["PlayedAt"]);
                        } else {
                            // Rare case where PlayedAt isn't an object
                            map.PlayedAt = Time::Stamp;
                        }
                        DataJson["recentlyPlayed"].Add(map.ToJson());
                        break;
                    }
                }
            }
        }

        DataManager::SaveData();
    }

    void BackupData() {
        if (!IO::FolderExists(MX_V1_BACKUP_LOCATION)) {
            IO::CreateFolder(MX_V1_BACKUP_LOCATION);
        }

        IO::Copy(DATA_JSON_LOCATION, Path::Join(MX_V1_BACKUP_LOCATION, "MXRandom_Data.json"));

        string backupSavePath = Path::Join(MX_V1_BACKUP_LOCATION, "Saves/");

        if (!IO::FolderExists(backupSavePath)) {
            IO::CreateFolder(backupSavePath);
        }

        for (uint f = 0; f < oldSaves.Length; f++) {
            string fileName = Path::GetFileName(oldSaves[f]);
            IO::Copy(oldSaves[f], backupSavePath + fileName);
        }

        Log::Info("Succesfully backed up old data at " + MX_V1_BACKUP_LOCATION);
    }

    void RemoveMX1SaveFiles() {
        for (uint f = 0; f < oldSaves.Length; f++) {
            if (IO::FileExists(oldSaves[f])) {
                IO::Delete(oldSaves[f]);
            }
        }
    }
}
