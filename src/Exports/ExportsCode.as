namespace MXRandom
{
    bool IsRMCRunning() { return RMC::IsRunning; }
    bool IsRMCPaused() { return RMC::IsPaused; }
    int RMCDefinedGoalMedal() { return RMC::Medals.Find(PluginSettings::RMC_GoalMedal); }
    string RMCDefinedGoalMedalName() { return PluginSettings::RMC_GoalMedal; }
    bool RMCGotGoalMedalOnCurrentMap() { return RMC::GotGoalMedalOnCurrentMap; }
    bool RMCGotBelowMedalOnCurrentMap() { return RMC::GotBelowMedalOnCurrentMap; }
    int RMCGoalMedalCount() { return RMC::GoalMedalCount; }
    RMC::GameMode RMCActualGameMode() { return RMC::selectedGameMode; }

    void LoadRandomMap() { startnew(MX::LoadRandomMap); }

    string GetRandomMapUrlAsync() {
        string URL = MX::CreateQueryURL();
        MX::MapInfo@ map = MX::MapInfo(API::GetAsync(URL)["results"][0]);
        return "https://"+MX_URL+"/maps/download/"+map.TrackID;
    }
}