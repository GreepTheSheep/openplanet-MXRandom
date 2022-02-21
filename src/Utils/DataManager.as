namespace DataManager
{
    void CheckData()
    {
        if (Versioning::IsPluginUpdated())
        {
            Log::Log("Plugin was updated, old version was "+ Json::Write(DataJson["version"]));
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
}