namespace MX
{
    const dictionary ModesFromTitlePack = {
#if MP4
        // Base title packs
        { "TMCanyon",        "SingleMap" },
        { "TMStadium",       "SingleMap" },
        { "TMValley",        "SingleMap" },
        { "TMLagoon",        "SingleMap" },

        // Envimix
        { "TMAll",           "SingleMap" },
        { "Envimix_Turbo",   "EnvimixSolo" },
        { "Nadeo_Envimix",   "EnvimixSolo" },

        // Environments recreations
        // TMOne's script doesn't work outside campaigns
        // { "TMOneAlpine",     "Unbitn/TMOne/TimeAttackOne" },
        // { "TMOneSpeed",      "Unbitn/TMOne/TimeAttackOne" },
        // { "TMOneBay",        "Unbitn/TMOne/TimeAttackOne" },
        { "TM2Rally",        "GlobalSolo" },
        { "TM2U_Island",     "SoloUni" },
        { "TM2_Coast",       "CoastSolo" },

        // Gamemodes recreations
        { "Platform",        "PlatformSolo" },
        { "ExtraWorld",      "ExtraWorldSolo" },
        { "ModePlus",        "GlobalSolo" },

        // Competition
        { "esl_comp",        "SingleMap" },

        // Other
        { "TMPlus_Canyon",   "SingleMap" },
        { "TMPlus_Lagoon",   "SingleMap" }
#endif
    };
}
