class RunSettings {
    RMC::Category Category = RMC::Category::Standard;
    Medals GoalMedal = Medals::Author;
    int MaxTimer;
    int FreeSkips;
    int RMO_Goal;
    int RMS_TimeBack;
    bool CustomSearchFilters;
    bool InvalidateGhosts;
    bool UseNoRespawnTime;
    bool SkipDuplicateMaps;
    bool SkipUnbeatenMedals;
    bool SkipUnbeatenMaps;
    bool CalculateMedals;
    bool FilterLowEffort;
    bool FilterUntagged;

    RunSettings() { }

    RunSettings(RMC::GameMode mode) {
        Category            = PluginSettings::SelectedCategory;
        GoalMedal           = PluginSettings::GoalMedal;
        CustomSearchFilters = PluginSettings::CustomSearchFilters;
        InvalidateGhosts    = PluginSettings::InvalidateGhosts;
        UseNoRespawnTime    = PluginSettings::UseNoRespawnTime;
        SkipDuplicateMaps   = PluginSettings::SkipDuplicateMaps;
        SkipUnbeatenMedals  = PluginSettings::SkipUnbeatenMedals;
        SkipUnbeatenMaps    = PluginSettings::SkipUnbeatenMaps;
        CalculateMedals     = PluginSettings::CalculateMedals;
        FilterLowEffort     = PluginSettings::FilterLowEffort;
        FilterUntagged      = PluginSettings::FilterUntagged;

        switch (mode) {
            case RMC::GameMode::Challenge:
                MaxTimer = PluginSettings::RMC_MaxTimer;
                FreeSkips = PluginSettings::RMC_FreeSkips;

                break;
            case RMC::GameMode::Survival:
                MaxTimer = PluginSettings::RMS_MaxTimer;
                RMS_TimeBack = PluginSettings::RMS_TimeBack;

                break;
            case RMC::GameMode::Together:
                MaxTimer = PluginSettings::RMT_MaxTimer;
                FreeSkips = PluginSettings::RMT_FreeSkips;

                break;
            case RMC::GameMode::Objective:
                RMO_Goal = PluginSettings::RMO_Goal;

                break;
            default:
                break;
        }
    }

    RunSettings(Json::Value@ json) {
        Category            = RMC::Category(int(json["Category"]));
        GoalMedal           = Medals(int(json["GoalMedal"]));
        CustomSearchFilters = json["CustomSearchFilters"];
        InvalidateGhosts    = json["InvalidateGhosts"];
        UseNoRespawnTime    = json["UseNoRespawnTime"];
        SkipDuplicateMaps   = json["SkipDuplicateMaps"];
        SkipUnbeatenMedals  = json["SkipUnbeatenMedals"];
        SkipUnbeatenMaps    = json["SkipUnbeatenMaps"];
        CalculateMedals     = json["CalculateMedals"];
        FilterLowEffort     = json["FilterLowEffort"];
        FilterUntagged      = json["FilterUntagged"];
        MaxTimer            = json["MaxTimer"];
        FreeSkips           = json["FreeSkips"];
        RMS_TimeBack        = json["RMS_TimeBack"];
        RMO_Goal            = json["RMO_Goal"];
    }

    Json::Value ToJson() {
        Json::Value json = Json::Object();

        json["Category"]            = Category;
        json["GoalMedal"]           = GoalMedal;
        json["CustomSearchFilters"] = CustomSearchFilters;
        json["InvalidateGhosts"]    = InvalidateGhosts;
        json["UseNoRespawnTime"]    = UseNoRespawnTime;
        json["SkipDuplicateMaps"]   = SkipDuplicateMaps;
        json["SkipUnbeatenMedals"]  = SkipUnbeatenMedals;
        json["SkipUnbeatenMaps"]    = SkipUnbeatenMaps;
        json["CalculateMedals"]     = CalculateMedals;
        json["FilterLowEffort"]     = FilterLowEffort;
        json["FilterUntagged"]      = FilterUntagged;
        json["MaxTimer"]            = MaxTimer;
        json["FreeSkips"]           = FreeSkips;
        json["RMS_TimeBack"]        = RMS_TimeBack;
        json["RMO_Goal"]            = RMO_Goal;

        return json;
    }
}
