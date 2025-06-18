namespace MXRandom
{
    import bool IsRMCRunning() from "MXRandom";
    import bool IsRMCPaused() from "MXRandom";
    import int RMCDefinedGoalMedal() from "MXRandom";
    import string RMCDefinedGoalMedalName() from "MXRandom";
    import bool RMCGotGoalMedalOnCurrentMap() from "MXRandom";
    import bool RMCGotBelowMedalOnCurrentMap() from "MXRandom";
    import int RMCGoalMedalCount() from "MXRandom";
    import int RMCActualGameMode() from "MXRandom";
    import bool get_WithCustomParameters() from "MXRandom";

    import void LoadRandomMap(bool customParameters = false) from "MXRandom";
    import string GetRandomMapUrlAsync(bool customParameters = false) from "MXRandom";
    import Json::Value@ GetRandomMapInfoAsync(bool customParameters = false) from "MXRandom";
}