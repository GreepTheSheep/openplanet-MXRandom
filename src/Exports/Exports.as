namespace MXRandom
{
    import bool IsRMCRunning() from "MXRandom";
    import bool IsRMCPaused() from "MXRandom";
    import int RMCGoalMedal() from "MXRandom";
    import string RMCGoalMedalName() from "MXRandom";
    import bool RMCGotGoalMedal() from "MXRandom";
    import bool RMCGotBelowMedal() from "MXRandom";
    import int RMCGoalMedalCount() from "MXRandom";
    import int RMCGameMode() from "MXRandom";
    import bool get_WithCustomParameters() from "MXRandom";

    import void LoadRandomMap(bool customParameters = false) from "MXRandom";
    import string GetRandomMapUrlAsync(bool customParameters = false) from "MXRandom";
    import Json::Value@ GetRandomMapInfoAsync(bool customParameters = false) from "MXRandom";
}