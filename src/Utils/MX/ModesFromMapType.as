namespace MX
{
    const dictionary ModesFromMapType = {
#if MP4
        { "Race",                     "" },
        { "TrackMania\\Race",         "" },
        { "Platform",                 "" },
        { "Stunts",                   "" },
        { "GoalHuntArena",            "GoalHunt" },
        { "HuntersArena",             "Hunters" },
        { "PursuitArena",             "Pursuit" },
        { "TMOne\\PlatformOneArena",  "" },
        { "EW Stunts - Score Attack", "ExtraWorldSolo" },
        { "EW Race - Time Attack",    "ExtraWorldSolo"}
#elif TMNEXT
        { "TM_Race",                  "" },
        { "TM_Stunt",                 "TrackMania/TM_StuntSolo_Local" },
        { "TM_Platform",              "TrackMania/TM_Platform_Local" },
        { "TM_Royal",                 "TrackMania/TM_RoyalTimeAttack_Local" }
#endif
    };
}
