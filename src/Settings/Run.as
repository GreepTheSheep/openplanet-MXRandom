namespace PluginSettings {
    const RMC::Category _DEFAULT_CATEGORY       = RMC::Category::Standard;
    const RMC::GameMode _DEFAULT_GAMEMODE       = RMC::GameMode::Challenge;
    const Medals _DEFAULT_MEDAL                 = Medals::Author;
    const int _DEFAULT_FREE_SKIPS               = 1;
    const int _DEFAULT_TIMER                    = 60;
    const int _DEFAULT_MAX_TIMER                = 15;
    const int _DEFAULT_TIME_BACK                = 3;
    const int _DEFAULT_GOAL                     = 5;
    const bool _DEFAULT_SEARCH_FILTERS          = false;
    const bool _DEFAULT_SKIP_GHOSTS             = true;
    const bool _DEFAULT_USE_NO_RESPAWN          = false;
    const bool _DEFAULT_SKIP_DUPLICATE_MAPS     = true;
    const bool _DEFAULT_SKIP_UNBEATEN_MEDALS    = false;
    const bool _DEFAULT_SKIP_UNBEATEN_MAPS      = true;
    const bool _DEFAULT_CALCULATE_MEDALS        = true;
    const bool _DEFAULT_FILTER_LOW_EFFORT       = true;
    const bool _DEFAULT_FILTER_UNTAGGED         = true;

    [Setting hidden]
    RMC::Category SelectedCategory = _DEFAULT_CATEGORY;

    [Setting hidden]
    RMC::GameMode SelectedGameMode = RMC::GameMode::Challenge;

    [Setting hidden]
    Medals RMC_Medal = _DEFAULT_MEDAL;

    [Setting hidden]
    int RMO_Goal = _DEFAULT_GOAL;

    [Setting hidden]
    int _RMC_MaxTimer = _DEFAULT_TIMER;

    [Setting hidden]
    int _RMC_FreeSkips = _DEFAULT_FREE_SKIPS;

    [Setting hidden]
    int _RMT_MaxTimer = _DEFAULT_TIMER;

    [Setting hidden]
    int _RMT_FreeSkips = _DEFAULT_FREE_SKIPS;

    [Setting hidden]
    int _RMS_MaxTimer = _DEFAULT_MAX_TIMER;

    [Setting hidden]
    int _RMS_TimeBack = _DEFAULT_TIME_BACK;

    [Setting hidden]
    bool _CustomSearchFilters = _DEFAULT_SEARCH_FILTERS;

    [Setting hidden]
    bool _InvalidateGhosts = _DEFAULT_SKIP_GHOSTS;

    [Setting hidden]
    bool _UseNoRespawnTime = _DEFAULT_USE_NO_RESPAWN;

    [Setting hidden]
    bool _SkipDuplicateMaps = _DEFAULT_SKIP_DUPLICATE_MAPS;

    [Setting hidden]
    bool _SkipUnbeatenMedals = _DEFAULT_SKIP_UNBEATEN_MEDALS;

    [Setting hidden]
    bool _SkipUnbeatenMaps = _DEFAULT_SKIP_UNBEATEN_MAPS;

    [Setting hidden]
    bool _CalculateMedals = _DEFAULT_CALCULATE_MEDALS;

    [Setting hidden]
    bool _FilterLowEffort = _DEFAULT_FILTER_LOW_EFFORT;

    [Setting hidden]
    bool _FilterUntagged = _DEFAULT_FILTER_UNTAGGED;

    void ResetRMCSettings() {
        SelectedCategory     = _DEFAULT_CATEGORY;
        SelectedGameMode     = _DEFAULT_GAMEMODE;
        RMC_Medal            = _DEFAULT_MEDAL;
        RMO_Goal             = _DEFAULT_GOAL;
        _RMC_MaxTimer        = _DEFAULT_TIMER;
        _RMC_FreeSkips       = _DEFAULT_FREE_SKIPS;
        _RMT_MaxTimer        = _DEFAULT_TIMER;
        _RMT_FreeSkips       = _DEFAULT_FREE_SKIPS;
        _RMS_MaxTimer        = _DEFAULT_MAX_TIMER;
        _RMS_TimeBack        = _DEFAULT_TIME_BACK;
        _CustomSearchFilters = _DEFAULT_SEARCH_FILTERS;
        _InvalidateGhosts    = _DEFAULT_SKIP_GHOSTS;
        _UseNoRespawnTime    = _DEFAULT_USE_NO_RESPAWN;
        _SkipDuplicateMaps   = _DEFAULT_SKIP_DUPLICATE_MAPS;
        _SkipUnbeatenMedals  = _DEFAULT_SKIP_UNBEATEN_MEDALS;
        _SkipUnbeatenMaps    = _DEFAULT_SKIP_UNBEATEN_MAPS;
        _CalculateMedals     = _DEFAULT_CALCULATE_MEDALS;
        _FilterLowEffort     = _DEFAULT_FILTER_LOW_EFFORT;
        _FilterUntagged      = _DEFAULT_FILTER_UNTAGGED;
    }

    Medals get_GoalMedal() {
        return RMC_Medal;
    }

    void set_GoalMedal(Medals m) {
        RMC_Medal = m;
    }

    int get_RMC_MaxTimer() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_TIMER;
        }

        return _RMC_MaxTimer;
    }

    void set_RMC_MaxTimer(int i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _RMC_MaxTimer = Math::Clamp(i, 1, 6000);
        }
    }

    int get_RMC_FreeSkips() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_FREE_SKIPS;
        }

        return _RMC_FreeSkips;
    }

    void set_RMC_FreeSkips(int i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _RMC_FreeSkips = Math::Clamp(i, 0, 1000);
        }
    }

    int get_RMT_MaxTimer() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_TIMER;
        }

        return _RMT_MaxTimer;
    }

    void set_RMT_MaxTimer(int i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _RMT_MaxTimer = Math::Clamp(i, 1, 180);
        }
    }

    int get_RMT_FreeSkips() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_FREE_SKIPS;
        }

        return _RMT_FreeSkips;
    }

    void set_RMT_FreeSkips(int i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _RMT_FreeSkips = Math::Clamp(i, 0, 1000);
        }
    }

    int get_RMS_MaxTimer() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_MAX_TIMER;
        }

        return _RMS_MaxTimer;
    }

    void set_RMS_MaxTimer(int i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _RMS_MaxTimer = Math::Clamp(i, 1, 60);
            RMS_TimeBack = Math::Min(i, _RMS_TimeBack);
        }
    }

    int get_RMS_TimeBack() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_TIME_BACK;
        }

        return _RMS_TimeBack;
    }

    void set_RMS_TimeBack(int i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _RMS_TimeBack = Math::Clamp(i, 1, _RMS_MaxTimer);
        }
    }

    bool get_CustomSearchFilters() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_SEARCH_FILTERS;
        }

        return _CustomSearchFilters;
    }

    void set_CustomSearchFilters(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _CustomSearchFilters = i;
        }
    }

    bool get_InvalidateGhosts() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_SKIP_GHOSTS;
        }

        return _InvalidateGhosts;
    }

    void set_InvalidateGhosts(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _InvalidateGhosts = i;
        }
    }

    bool get_UseNoRespawnTime() {
#if DEPENDENCY_MLFEEDRACEDATA
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_USE_NO_RESPAWN;
        }

        return _UseNoRespawnTime;
#else
        return false;
#endif
    }

    void set_UseNoRespawnTime(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _UseNoRespawnTime = i;
        }
    }

    bool get_SkipDuplicateMaps() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_SKIP_DUPLICATE_MAPS;
        }

        return _SkipDuplicateMaps;
    }

    void set_SkipDuplicateMaps(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _SkipDuplicateMaps = i;
        }
    }

    bool get_SkipUnbeatenMedals() {
        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_SKIP_UNBEATEN_MEDALS;
        }

        return _SkipUnbeatenMedals;
    }

    void set_SkipUnbeatenMedals(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _SkipUnbeatenMedals = i;
        }
    }

    bool get_SkipUnbeatenMaps() {
        switch (SelectedCategory) {
            case RMC::Category::Classic:
            case RMC::Category::Nadeo:
#if TMNEXT
            case RMC::Category::TOTD:
#endif
                return false;
            case RMC::Category::Custom:
                return _SkipUnbeatenMaps;
            default:
                return _DEFAULT_SKIP_UNBEATEN_MAPS;
        }
    }

    void set_SkipUnbeatenMaps(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _SkipUnbeatenMaps = i;
        }
    }

    bool get_CalculateMedals() {
        if (SelectedCategory == RMC::Category::Classic) {
            return false;
        }

        if (SelectedCategory != RMC::Category::Custom) {
            return _DEFAULT_CALCULATE_MEDALS;
        }

        return _CalculateMedals;
    }

    void set_CalculateMedals(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _CalculateMedals = i;
        }
    }

    bool get_FilterLowEffort() {
        switch (SelectedCategory) {
            case RMC::Category::Classic:
            case RMC::Category::Nadeo:
#if TMNEXT
            case RMC::Category::TOTD:
#endif
                return false;
            case RMC::Category::Custom:
                return _FilterLowEffort;
            default:
                return _DEFAULT_FILTER_LOW_EFFORT;
        }
    }

    void set_FilterLowEffort(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _FilterLowEffort = i;
        }
    }

    bool get_FilterUntagged() {
        switch (SelectedCategory) {
            case RMC::Category::Classic:
            case RMC::Category::Nadeo:
#if TMNEXT
            case RMC::Category::TOTD:
#endif
                return false;
            case RMC::Category::Custom:
                return _FilterUntagged;
            default:
                return _DEFAULT_FILTER_UNTAGGED;
        }
    }

    void set_FilterUntagged(bool i) {
        if (SelectedCategory == RMC::Category::Custom) {
            _FilterUntagged = i;
        }
    }
}
