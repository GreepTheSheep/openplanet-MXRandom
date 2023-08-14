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

    void EnsureSaveFileFolderPresent() {
        if(!IO::FolderExists(SAVE_DATA_LOCATION)) {
            IO::CreateFolder(SAVE_DATA_LOCATION);
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

    void CreateSaveFile(string gameMode) {
        string curr_time = Time::FormatString("%y%m%d-%H%M");
        Json::Value SaveFileData = Json::Object();
        SaveFileData["TimerRemaining"] = 0;
        SaveFileData["MapID"] = 0;
        SaveFileData["TimeSpentOnMap"] = 0;  // this is updated when you manually quit on a map
        SaveFileData["PrimaryCounterValue"] = 0;  // Amount of goal medals
        SaveFileData["SecondaryCounterValue"] = 0;  // Second medal type for RMC ("Gold Skips") or skip count for RMS
        SaveFileData["CurrentRunTime"] = 0; // for survival runs
        Json::ToFile(SAVE_DATA_LOCATION + gameMode + "_" + curr_time + ".json", SaveFileData);
        RMC::CurrentRunIdentifier = gameMode + "_" + curr_time;
        RMC::CurrentRunData = SaveFileData;
    }

    void RemoveCurrentSaveFile() {
        IO::Delete(SAVE_DATA_LOCATION + RMC::CurrentRunIdentifier + ".json");
        RMC::CurrentRunIdentifier = "";
        RMC::CurrentRunData = Json::Object();
    }

    void SaveCurrentRunData() {
        Json::ToFile(SAVE_DATA_LOCATION + RMC::CurrentRunIdentifier + ".json", RMC::CurrentRunData);
    }

    void LoadRunData(string runIdentifier) {
        RMC::CurrentRunIdentifier = runIdentifier;
        RMC::CurrentRunData = Json::FromFile(SAVE_DATA_LOCATION + runIdentifier + ".json");
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