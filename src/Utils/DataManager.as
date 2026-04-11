namespace DataManager {
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

    void CheckData() {
        if (Versioning::IsPluginUpdated()) {
            Log::Info("Plugin was updated, old version was " + Json::Write(DataJson["version"]));
            DataJson["version"] = PLUGIN_VERSION;
        }
    }

    void EnsureSaveFileFolderPresent() {
        if (!IO::FolderExists(SAVE_DATA_LOCATION)) {
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

    void InitData(bool save = true) {
        DataJson = Json::Object();
        DataJson["version"] = PLUGIN_VERSION;
        DataJson["recentlyPlayed"] = Json::Array();
        DataJson["randomMapChallenge"] = Json::Object();
        DataJson["randomMapChallenge"]["recentRaces"] = Json::Array();

        if (save) SaveData();
    }

    void SaveData() {
        Log::Trace("Saving JSON file");
        Json::ToFile(DATA_JSON_LOCATION, DataJson);
    }

    void RemoveCurrentSaveFile() {
        string lastLetter = tostring(RMC::currentRun.Mode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        string fileName = SAVE_DATA_LOCATION + gameMode + ".json";

        if (IO::FileExists(fileName)) {
            IO::Delete(fileName);
        }
    }

    void SaveCurrentRunData() {
        string lastLetter = tostring(RMC::currentRun.Mode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;
        Json::ToFile(SAVE_DATA_LOCATION + gameMode + ".json", RMC::currentRun.ToJson());
    }

    void ConvertSaves() {
        array<string> saves = IO::IndexFolder(SAVE_DATA_LOCATION, true);

        for (uint f = 0; f < saves.Length; f++) {
            string path = saves[f];
            string fileName = Path::GetFileNameWithoutExtension(path);
            Json::Value@ save = Json::FromFile(path);

            if (save.GetType() != Json::Type::Object) {
                IO::Delete(path);
                continue;
            }

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
                    save["TotalTime"] = (PluginSettings::RMC_MaxTimer * 60 * 1000) - int(save["TimeLeft"]);
                }
                save.Remove("CurrentRunTime");

                Json::ToFile(path, save);
            }
        }
    }

    bool EnsureSaveDataIsLoadable(const string &in gameMode, Json::Value data) {
        if (data.GetType() != Json::Type::Object) {
            return false;
        }

        for (uint i = 0; i < requiredKeys.Length; i++) {
            if (!data.HasKey(requiredKeys[i])) {
                Log::Error("Save file for " + gameMode + " is corrupted, missing key '" + requiredKeys[i] + "'");
                return false;
            } else if (data[requiredKeys[i]].GetType() != requiredTypesOfKeys[i]) {
                Log::Error("Save file for " + gameMode + " is corrupted, key '" + requiredKeys[i] + "' is of wrong type");
                Log::Error("Expected " + tostring(requiredTypesOfKeys[i]) + ", got " + tostring(data[requiredKeys[i]].GetType()) + ")");
                return false;
            }
        }
        return true;
    }

    Json::Value@ GetRunSave() {
        string lastLetter = tostring(RMC::currentRun.Mode).SubStr(0,1);
        string gameMode = "RM" + lastLetter;

        if (IO::FileExists(SAVE_DATA_LOCATION + gameMode + ".json")) {
            Json::Value@ data = Json::FromFile(SAVE_DATA_LOCATION + gameMode + ".json");

            if (!EnsureSaveDataIsLoadable(gameMode, data)) {
                Log::Error("Deleting the current " + gameMode + " save file, as it is corrupted!");
                Log::Error("Please create an issue on github if this repeatedly happens");
                RemoveCurrentSaveFile();
                return null;
            }

            if (data["TimeLeft"] == 0) {
                RemoveCurrentSaveFile();
                return null;
            }

            return data;
        }

        return null;
    }

    void SaveMapToRecentlyPlayed(MX::MapInfo@ map) {
        Json::Value arr = Json::Array();
        arr.Add(map.ToJson());

        for (uint i = 0; i < DataJson["recentlyPlayed"].Length; i++) {
            Json::Value@ playedMap = DataJson["recentlyPlayed"][i];

            // If the most recent map is the same one, skip it
            // Happens when resuming a run for example
            if (i == 0 && map == MX::MapInfo(playedMap)) {
                continue;
            }

            arr.Add(playedMap);

            // Only save the 100 most recent maps
            if (arr.Length >= 100) {
                break;
            }
        }

        DataJson["recentlyPlayed"] = arr;
        DataManager::SaveData();
    }
}