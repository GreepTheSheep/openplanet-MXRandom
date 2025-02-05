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

    void LoadRandomMap() { startnew(MX::LoadRandomMap); }

    string GetRandomMapUrlAsync() {
        string URL = MX::CreateQueryURL();
        Json::Value res = API::GetAsync(URL)["Results"][0];
        Json::Value playedAt = Json::Object();
        Time::Info date = Time::Parse();
        playedAt["Year"] = date.Year;
        playedAt["Month"] = date.Month;
        playedAt["Day"] = date.Day;
        playedAt["Hour"] = date.Hour;
        playedAt["Minute"] = date.Minute;
        playedAt["Second"] = date.Second;
        res["PlayedAt"] = playedAt;
        MX::MapInfo@ map = MX::MapInfo(res);
        return PluginSettings::RMC_MX_Url+"/mapgbx/"+map.MapId;
    }
}