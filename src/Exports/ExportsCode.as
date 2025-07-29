namespace MXRandom
{
    bool IsRMCRunning() { return RMC::IsRunning; }
    bool IsRMCPaused() { return RMC::IsPaused; }
    int RMCGoalMedal() { return RMC::Medals.Find(PluginSettings::RMC_GoalMedal); }
    string RMCGoalMedalName() { return PluginSettings::RMC_GoalMedal; }
    bool RMCGotGoalMedal() { return RMC::GotGoalMedal; }
    bool RMCGotBelowMedal() { return RMC::GotBelowMedal; }
    int RMCGoalMedalCount() { return RMC::GoalMedalCount; }
    int RMCGameMode() { return RMC::selectedGameMode; }
    bool get_WithCustomParameters() { return PluginSettings::CustomRules; }

    void LoadRandomMap(bool customParameters = false) { 
        if (customParameters) {
            startnew(LoadCustomMap);
        } else {
            startnew(LoadMap);
        }
    }

    string GetRandomMapUrlAsync(bool customParameters = false) {
        MX::MapInfo@ map = GetMap(customParameters);

        if (map is null) {
            return "";
        }

        return PluginSettings::RMC_MX_Url + "/mapgbx/" + map.MapId;
    }

    Json::Value@ GetRandomMapInfoAsync(bool customParameters = false) {
        MX::MapInfo@ map = GetMap(customParameters);

        if (map is null) {
            return null;
        }

        return map.ToJson();
    }

    MX::MapInfo@ GetMap(bool customParameters = false) {
        string URL = MX::CreateQueryURL(customParameters);
        Json::Value res = API::GetAsync(URL);

        if (res.GetType() == Json::Type::Null || !res.HasKey("Results") || res["Results"].Length == 0) {
            Log::Error("Failed to find a random map from TMX.");
            return null;
        }

        return MX::MapInfo(res["Results"][0]);
    }

    void LoadMap() {
        MX::MapInfo@ map = GetMap();

        if (map is null) {
            Log::Error("Failed to load a random map: Couldn't find a map.");
            return;
        }

        startnew(TM::LoadMap, map);
    }

    void LoadCustomMap() {
        MX::MapInfo@ map = GetMap(true);

        if (map is null) {
            Log::Error("Failed to load a random map with custom parameters: Couldn't find a map.");
            return;
        }

        startnew(TM::LoadMap, map);
    }
}