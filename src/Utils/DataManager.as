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

    void CreateSaveFile() {
        string lastLetter = tostring(RMC::selectedGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        Json::Value SaveFileData = Json::Object();
        SaveFileData["PBOnMap"] = -1;
        SaveFileData["TimerRemaining"] = 0;
        SaveFileData["MapData"] = Json::Object();
        SaveFileData["TimeSpentOnMap"] = 0;  // this is updated when you manually quit on a map
        SaveFileData["PrimaryCounterValue"] = 0;  // Amount of goal medals
        SaveFileData["SecondaryCounterValue"] = 0;  // Second medal type for RMC ("Gold Skips") or skip count for RMS
        SaveFileData["CurrentRunTime"] = 0;
        SaveFileData["GotBelowMedalOnMap"] = false; // for challenge runs
        SaveFileData["GotGoalMedalOnMap"] = false; // for challenge runs
        SaveFileData["FreeSkipsUsed"] = 0; // for RMC runs
        Json::ToFile(SAVE_DATA_LOCATION + gameMode + ".json", SaveFileData);
        RMC::CurrentRunData = SaveFileData;
    }

    void RemoveCurrentSaveFile() {
        string lastLetter = tostring(RMC::selectedGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        IO::Delete(SAVE_DATA_LOCATION + gameMode + ".json");
        RMC::CurrentRunData = Json::Object();
    }

    void SaveCurrentRunData() {
        string lastLetter = tostring(RMC::selectedGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        Json::ToFile(SAVE_DATA_LOCATION + gameMode + ".json", RMC::CurrentRunData);
    }

    bool EnsureSaveDataIsLoadable(const string &in gameMode, Json::Value data) {
        array<string> requiredKeys = {
            "PBOnMap",
            "TimerRemaining",
            "MapData",
            "TimeSpentOnMap",
            "PrimaryCounterValue",
            "SecondaryCounterValue",
            "CurrentRunTime",
            "GotBelowMedalOnMap",
            "GotGoalMedalOnMap",
            "FreeSkipsUsed"
        };
        array<Json::Type> requiredTypesOfKeys = {
            Json::Type::Number,
            Json::Type::Number,
            Json::Type::Object,
            Json::Type::Number,
            Json::Type::Number,
            Json::Type::Number,
            Json::Type::Number,
            Json::Type::Boolean,
            Json::Type::Boolean,
            Json::Type::Number
        };
        for (uint i = 0; i < requiredKeys.Length; i++) {
            if (!data.HasKey(requiredKeys[i])) {
                Log::Error("Save file for " + gameMode + " is corrupted, missing key '" + requiredKeys[i] + "'");
                return false;
            } else if (data[requiredKeys[i]].GetType() != requiredTypesOfKeys[i]) {
                Log::Error("Save file for " + gameMode + " is corrupted, key '" + requiredKeys[i] + "' is of wrong type\n(Expected " + tostring(
                    Json::Type(requiredTypesOfKeys[i])) + ", got " + tostring(
                        Json::Type(data[requiredKeys[i]].GetType())) + ")");
                return false;
            }
        }
        return true;
    }

    bool LoadRunData() {
        string lastLetter = tostring(RMC::selectedGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        if (IO::FileExists(SAVE_DATA_LOCATION + gameMode + ".json")) {
            RMC::CurrentRunData = Json::FromFile(SAVE_DATA_LOCATION + gameMode + ".json");
            if (!EnsureSaveDataIsLoadable(gameMode, RMC::CurrentRunData)) {
                Log::Error("Deleting the current" + gameMode + " save file, as it is corrupted!");
                Log::Error("Please create an issue on github if this repeatedly happens");
                RemoveCurrentSaveFile();
                return false;
            }
            if (RMC::CurrentRunData["TimerRemaining"] == 0) return false;
            return true;
        }
        return false;
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