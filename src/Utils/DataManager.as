namespace DataManager
{
    const array<string> requiredKeys = {
        "PBOnMap",
        "TimeLeft",
        "MapData",
        "TimeSpentOnMap",
        "PrimaryCounterValue",
        "SecondaryCounterValue",
        "TotalTime",
        "GotBelowMedal",
        "GotGoalMedal",
        "FreeSkipsUsed"
    };

    const array<Json::Type> requiredTypesOfKeys = {
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

    bool IsDataMX2() {
        if (DataJson.GetType() == Json::Type::Null || DataJson.Length == 0) return true;

        if (DataJson["recentlyPlayed"].Length > 0) {
            return DataJson["recentlyPlayed"][0].HasKey("MapId");
        } else {
            array<string> oldSaves = IO::IndexFolder(SAVE_DATA_LOCATION, true);

            if (oldSaves.IsEmpty()) return true;

            Json::Value@ save = Json::FromFile(oldSaves[0]);

            if (save.HasKey("MapData")) {
                Json::Value@ mapData = save["MapData"];
                return mapData.HasKey("MapId");
            }
        }

        return true;
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
        string lastLetter = tostring(RMC::currentGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        Json::Value SaveFileData = Json::Object();
        SaveFileData["PBOnMap"] = -1;
        SaveFileData["TimeLeft"] = 0;
        SaveFileData["MapData"] = Json::Object();
        SaveFileData["TimeSpentOnMap"] = 0;
        SaveFileData["PrimaryCounterValue"] = 0;  // Amount of goal medals
        SaveFileData["SecondaryCounterValue"] = 0;  // Second medal type for RMC ("Gold Skips") or skip count for RMS
        SaveFileData["TotalTime"] = 0;
        SaveFileData["GotBelowMedal"] = false;
        SaveFileData["GotGoalMedal"] = false;
        SaveFileData["FreeSkipsUsed"] = 0;
        Json::ToFile(SAVE_DATA_LOCATION + gameMode + ".json", SaveFileData);
        RMC::CurrentRunData = SaveFileData;
    }

    void RemoveCurrentSaveFile() {
        string lastLetter = tostring(RMC::currentGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        string fileName = SAVE_DATA_LOCATION + gameMode + ".json";
        if (IO::FileExists(fileName)) {
            IO::Delete(fileName);
        }
        RMC::CurrentRunData = Json::Object();
    }

    void SaveCurrentRunData() {
        string lastLetter = tostring(RMC::currentGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        Json::ToFile(SAVE_DATA_LOCATION + gameMode + ".json", RMC::CurrentRunData);
    }

    void ConvertSaves() {
        array<string> saves = IO::IndexFolder(SAVE_DATA_LOCATION, true);

        for (uint f = 0; f < saves.Length; f++) {
            string path = saves[f];
            string fileName = Path::GetFileNameWithoutExtension(path);
            Json::Value@ save = Json::FromFile(path);

            if (!save.HasKey("TotalTime")) {
                if (fileName == "RMO" && IO::FileExists(path)) {
                    // These are not used
                    IO::Delete(path);
                }

                save["TimeLeft"] = int(save["TimerRemaining"]);
                save.Remove("TimerRemaining");

                save["GotGoalMedal"] = bool(save["GotGoalMedalOnMap"]);
                save.Remove("GotGoalMedalOnMap");
                
                if (save.HasKey("GotBelowMedalOnMap")) {
                    save["GotBelowMedal"] = bool(save["GotBelowMedalOnMap"]);
                    save.Remove("GotBelowMedalOnMap");
                } else {
                    save["GotBelowMedal"] = false;
                }

                if (fileName == "RMS") {
                    save["TotalTime"] = int(save["CurrentRunTime"]);
                } else {
                    save["TotalTime"] = RMC::Challenge.TimeLimit - int(save["TimeLeft"]);
                }
                save.Remove("CurrentRunTime");

                Json::ToFile(path, save);
            }
        }
    }

    bool EnsureSaveDataIsLoadable(const string &in gameMode, Json::Value data) {
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
        string lastLetter = tostring(RMC::currentGameMode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        if (IO::FileExists(SAVE_DATA_LOCATION + gameMode + ".json")) {
            RMC::CurrentRunData = Json::FromFile(SAVE_DATA_LOCATION + gameMode + ".json");
            if (!EnsureSaveDataIsLoadable(gameMode, RMC::CurrentRunData)) {
                Log::Error("Deleting the current " + gameMode + " save file, as it is corrupted!");
                Log::Error("Please create an issue on github if this repeatedly happens");
                RemoveCurrentSaveFile();
                return false;
            }
            if (RMC::CurrentRunData["TimeLeft"] == 0) return false;
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