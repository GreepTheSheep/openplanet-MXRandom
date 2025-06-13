namespace MXRandom
{
    bool IsRMCRunning() { return RMC::IsRunning; }
    bool IsRMCPaused() { return RMC::IsPaused; }
    int RMCDefinedGoalMedal() { return RMC::Medals.Find(PluginSettings::RMC_GoalMedal); }
    string RMCDefinedGoalMedalName() { return PluginSettings::RMC_GoalMedal; }
    bool RMCGotGoalMedalOnCurrentMap() { return RMC::GotGoalMedalOnCurrentMap; }
    bool RMCGotBelowMedalOnCurrentMap() { return RMC::GotBelowMedalOnCurrentMap; }
    int RMCGoalMedalCount() { return RMC::GoalMedalCount; }
    int RMCActualGameMode() { return RMC::selectedGameMode; }
    bool get_WithCustomParameters() { return PluginSettings::CustomRules; }

    void LoadRandomMap() { startnew(MX::LoadRandomMap); }

    string GetRandomMapUrlAsync() {
        string URL = MX::CreateQueryURL();
        Json::Value res = API::GetAsync(URL)["Results"][0];
        MX::MapInfo@ map = MX::MapInfo(res);
        return PluginSettings::RMC_MX_Url+"/mapgbx/"+map.MapId;
    }
}