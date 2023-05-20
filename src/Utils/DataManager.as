namespace DataManager
{
    void CheckData()
    {
        if (Versioning::IsPluginUpdated())
        {
            Log::Log("Plugin was updated, old version was "+ Json::Write(DataJson["version"]));
            DataJson["version"] = PLUGIN_VERSION;
        }
    }

    void InitData(bool save = true)
    {
        DataJson = Json::Object();
        DataJson["version"] = PLUGIN_VERSION;
        DataJson["recentlyPlayed"] = Json::Array();
        DataJson["randomMapChallenge"] = Json::Object();
        DataJson["randomMapChallenge"]["recentRaces"] = Json::Array();

        if (save) SaveData();
    }

    void SaveData()
    {
        Log::Trace("Saving JSON file");
        Json::ToFile(DATA_JSON_LOCATION, DataJson);
    }

    void SaveMapToRecentlyPlayed(MX::MapInfo@ map) {
        // Save the recently played map json
        // Method: Creates a new Array to save first the new map, then the old ones.
        Json::Value arr = Json::Array();
        arr.Add(map.ToJson());
        if (DataJson["recentlyPlayed"].Length > 0) {
            for (uint i = 0; i < DataJson["recentlyPlayed"].Length; i++) {
                arr.Add(DataJson["recentlyPlayed"][i]);
            }
        }
        // Resize the array to the max amount of maps (50, to not overload the json)
        if (arr.Length > 50) {
            for (uint i = 50; i < arr.Length; i++) {
                arr.Remove(i);
            }
        }
        DataJson["recentlyPlayed"] = arr;
        DataManager::SaveData();
    }
}