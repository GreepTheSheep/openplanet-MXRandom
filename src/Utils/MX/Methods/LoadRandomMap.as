namespace MX {
    MX::MapInfo@ preloadedMap;
    bool isLoadingPreload = false;
    // "Unassigned" = MP1 Canyon and TMF Stadium maps. They are guaranteed to be compatible as editing the map would change the title ID.
    const array<string> tmAllCompatibleTitlepacks = { "TMAll", "TMCanyon", "TMStadium", "TMValley", "TMLagoon", "Unassigned" };
    Json::Value CheckCustomRulesParametersNoResults() {
        string check_url = PluginSettings::RMC_MX_Url + "/api/maps";

        dictionary params;
        params.Set("fields", MAP_FIELDS);
        params.Set("random", "1");
        params.Set("count", "1");
        params.Set("maptype", SUPPORTED_MAP_TYPE); // ignore any non-Race maps (Royal, flagrush etc...)

#if TMNEXT
        // ignore CharacterPilot maps
        params.Set("vehicle", "1,2,3,4");
#elif MP4
        // only consider the correct titlepack
        if (TM::CurrentTitlePack() == "TMAll" && false) {
            params.Set("titlepack", TM::CurrentTitlePack() + ",TMCanyon,TMValley,TMStadium,TMLagoon"); // TODO doesn't work yet
        } else {
            params.Set("titlepack", TM::CurrentTitlePack());
        }
#endif

        if (PluginSettings::MapAuthor != "") {
            params.Set("author", PluginSettings::MapAuthor);
            string urlParams = DictToApiParams(params);

            Json::Value _res = API::GetAsync(check_url + urlParams);
            if (_res["Results"].Length == 0) {
                // author does not own any usable map.
                Log::Error(Icons::ExclamationTriangle + " No maps found for author '" + PluginSettings::MapAuthor + "', retrying without author set...");
                PluginSettings::MapAuthor = "";
                return _res;
            } else if (_res["Results"].Length == 1) {
                // author only has one usable map, so we can just return it as the API will troll when using random on it
                return _res["Results"][0];
            }
        }
        if (PluginSettings::MapName != "") {
            params.Set("name", PluginSettings::MapName);
            string urlParams = DictToApiParams(params);

            Json::Value _res = API::GetAsync(check_url + urlParams);
            if (_res["Results"].Length == 0) {
                // there are no map names matching the filter
                Log::Error(Icons::ExclamationTriangle + " No maps found for name '" + PluginSettings::MapName + "', retrying without name set...");
                PluginSettings::MapName = "";
                return _res;
            } else if (_res["Results"].Length == 1) {
                // there is only one map matching the filter, so we can just return it
                return _res["Results"][0];
            }
        }
        if (PluginSettings::MapAuthor != "" && PluginSettings::MapName != "") {
            params.Set("name", PluginSettings::MapName);
            params.Set("author", PluginSettings::MapAuthor);
            string urlParams = DictToApiParams(params);

            Json::Value _res = API::GetAsync(check_url + urlParams);
            if (_res["Results"].Length == 0) {
                // there are no map names matching the filter
                Log::Error(Icons::ExclamationTriangle + " No maps found for author '" + PluginSettings::MapAuthor + "' and name '" + PluginSettings::MapName + "', retrying without name set...");
                PluginSettings::MapName = "";
                return _res;
            } else if (_res["Results"].Length == 1) {
                // there is only one map matching the filter, so we can just return it
                return _res["Results"][0];
            }
        }

        Json::Value retval = Json::Object();
        retval["hasMaps"] = true;
        return retval;
    }

    bool isMapInsideDateParams(const MX::MapInfo@ &in map) {
        int64 mapUpdatedDate = Time::ParseFormatString('%FT%T', map.UpdatedAt);
        int64 fromDate = Time::ParseFormatString('%F', PluginSettings::FromDate);
        int64 toDate = Time::ParseFormatString('%F', PluginSettings::ToDate);

        return (mapUpdatedDate <= toDate && mapUpdatedDate >= fromDate);
    }


    void PreloadRandomMap() {
        isLoadingPreload = true;

        string URL = CreateQueryURL();
        Json::Value res;
        try {
            res = API::GetAsync(URL)["Results"][0];
        } catch {
            if (PluginSettings::CustomRules || (!RMC::IsStarting && !RMC::IsRunning)) {
                // we might get an error because the author doesn't have a map/no map with the given name exists
                // if we do not detect that there are no matching results, we will enter an infinite loop with errors
                // that will force the user to reload the plugin
                Json::Value check = CheckCustomRulesParametersNoResults();
                if (check.HasKey("MapId")) {
                    // we found a single map that matches the parameters, so we can just return it
                    res = check;
                } else if (check.HasKey("hasMaps")) {
                    // maps with parameters exist but we still got an error, just retry
                    // (from testing usually TMX doing weird stuff and not returning a map even though there is multiple, just retry and it will find one after a few tries)
                    Log::Error("ManiaExchange API returned an error, retrying...");
                    sleep(3000);
                    PreloadRandomMap();
                    return;
                } else {  // no maps found, retrying without parameters
                    sleep(1000);
                    PreloadRandomMap();
                    return;
                }
            } else {
                Log::Error("ManiaExchange API returned an error, retrying...");
                sleep(3000);
                PreloadRandomMap();
                return;
            }
        }
        Log::Trace("PreloadRandomMapRes: " + Json::Write(res));
        MX::MapInfo@ map = MX::MapInfo(res);

        if (map is null) {
            Log::Warn("Map is null, retrying...");
            sleep(1000);
            PreloadRandomMap();
            return;
        }

        if (RMC::IsRunning || RMC::IsStarting) {
            if (!PluginSettings::CustomRules) {
                if (map.AuthorTime > RMC::config.length) {
                    Log::Warn("Map is too long, retrying...");
                    sleep(1000);
                    PreloadRandomMap();
                    return;
                }
            }

#if TMNEXT
            if (RMC::currentGameMode == RMC::GameMode::Together && map.ServerSizeExceeded) {
                Log::Warn("Map is too big to play in servers, retrying...");
                sleep(1000);
                PreloadRandomMap();
                return;
            }

            // Check if map is uploaded to Nadeo Services (if goal == WorldRecord)
            if (PluginSettings::RMC_Medal == Medals::WR) {
                if (PluginSettings::MapType == MapTypes::Platform || PluginSettings::MapType == MapTypes::Royal) {
                    // Platform and Royal don't support leaderboards
                    Log::Warn("Game mode " + tostring(PluginSettings::MapType) + " doesn't support leaderboards. Using AT as fallback for WR.");
                    TM::SetWorldRecordToCache(map.MapUid, map.AuthorTime);
                } else {
                    if (map.OnlineMapId == "" && !MXNadeoServicesGlobal::CheckIfMapExistsAsync(map.MapUid)) {
                        Log::Warn("Map is not uploaded to Nadeo Services, retrying...");
                        sleep(1000);
                        PreloadRandomMap();
                        return;
                    }

                    // if uploaded, get wr
                    int mapWorldRecord = MXNadeoServicesGlobal::GetMapWorldRecord(map.MapUid);

                    if (mapWorldRecord == -1) {
                        Log::Warn("Couldn't get map World Record, retrying another map...");
                        sleep(1000);
                        PreloadRandomMap();
                        return;
                    }

                    TM::SetWorldRecordToCache(map.MapUid, mapWorldRecord);
                }
            }
#endif
        }

        if (PluginSettings::CustomRules) {
            if (PluginSettings::UseDateInterval) {
                int64 toDate = Time::ParseFormatString('%F', PluginSettings::ToDate);
                int64 fromDate = Time::ParseFormatString('%F', PluginSettings::FromDate);

                // only check if date range is valid
                if (fromDate < toDate && !isMapInsideDateParams(map)) {
                    Log::Warn("Looking for new map inside date params...");
                    sleep(1000);
                    PreloadRandomMap();
                    return;
                }
            }

            if (PluginSettings::UseCustomLength) {
                if (PluginSettings::MinLength != 0 && map.AuthorTime < PluginSettings::MinLength) {
                    Log::Warn("Map is shorter than the requested length, retrying...");
                    sleep(1000);
                    PreloadRandomMap();
                    return;
                }

                if (PluginSettings::MaxLength != 0 && map.AuthorTime > PluginSettings::MaxLength) {
                    Log::Warn("Map is longer than the requested length, retrying...");
                    sleep(1000);
                    PreloadRandomMap();
                    return;
                }
            } else if (map.AuthorTime > RMC::config.length) {
                Log::Warn("Map is too long, retrying...");
                sleep(1000);
                PreloadRandomMap();
                return;
            }

            if (PluginSettings::ExcludedTerms != "") {
                string termsRegex = string::Join(PluginSettings::ExcludedTermsArr, "|");

                if (PluginSettings::TermsExactMatch) {
                    // Use word boundaries to only find exact matches
                    termsRegex = "\\b(" + termsRegex + ")\\b";
                }

                if (Regex::Contains(map.Name, termsRegex, Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map contains an excluded term, retrying...");
                    sleep(1000);
                    PreloadRandomMap();
                    return;
                }
            }

            if (PluginSettings::ExcludedAuthors != "") {
                foreach (string author : PluginSettings::ExcludedAuthorsArr) {
                    if (map.Username.ToLower() == author) {
                        Log::Warn("Map is uploaded by an excluded author, retrying...");
                        sleep(1000);
                        PreloadRandomMap();
                        return;
                    }
                }
            }
        }
        isLoadingPreload = false;
        @preloadedMap = map;
    }

    void LoadRandomMap() {
        try {
            while (RandomMapIsLoading) {
                yield();
            }
#if MP4
            if (TM::CurrentTitlePack() == "") {
                Log::Warn("Please load a title pack first.", true);
                return;
            }
#endif
            RandomMapIsLoading = true;
            MX::MapInfo@ map;

            if (RMC::ContinueSavedRun && !RMC::IsInited) {
                Json::Value res = RMC::CurrentMapJsonData;
                res["PlayedAt"] = Time::Stamp; // Update to the last time it was played
                @map = MX::MapInfo(res);
                @preloadedMap = null;
            } else {
                if (preloadedMap is null && !isLoadingPreload) PreloadRandomMap();
                while (isLoadingPreload) yield();
                @map = preloadedMap;
                @preloadedMap = null;
            }

            Log::LoadingMapNotification(map);

            DataManager::SaveMapToRecentlyPlayed(map);

            await(startnew(TM::LoadMap, map));

            RandomMapIsLoading = false;
            RMC::CurrentMapJsonData = map.ToJson();
        } catch {
            Log::Warn("Error while loading map: " + getExceptionInfo());
            Log::Error(MX_NAME + " API is not responding, it might be down.", true);
            APIDown = true;
            RandomMapIsLoading = false;
        }
    }

    string CreateQueryURL(bool customParameters = true) {
        string url = PluginSettings::RMC_MX_Url + "/api/maps";

        dictionary params;
        params.Set("fields", MAP_FIELDS);
        params.Set("random", "1");
        params.Set("count", "1");

        if ((RMC::IsRunning || RMC::IsStarting) && (!customParameters || !PluginSettings::CustomRules)) {
            params.Set("etag", RMC::config.etags);
            params.Set("authortimemax", tostring(RMC::config.length));
        } else if (customParameters && PluginSettings::CustomRules) {
            if (PluginSettings::UseCustomLength) {
                if (PluginSettings::MinLength != 0) {
                    params.Set("authortimemin", tostring(PluginSettings::MinLength));
                }

                if (PluginSettings::MaxLength != 0) {
                    params.Set("authortimemax", tostring(PluginSettings::MaxLength));
                }
            } else {
                params.Set("authortimemax", tostring(RMC::config.length));
            }

            if (PluginSettings::UseDateInterval) {
                int64 toDate = Time::ParseFormatString('%F', PluginSettings::ToDate);
                int64 fromDate = Time::ParseFormatString('%F', PluginSettings::FromDate);

                if (fromDate < toDate) {
                    params.Set("uploadedafter", PluginSettings::FromDate);
                    params.Set("uploadedbefore", PluginSettings::ToDate);
                } else {
                    Log::Warn("Invalid date interval selected, ignoring...");
                }
            }

            if (!PluginSettings::MapTagsArr.IsEmpty()) {
                params.Set("tag", PluginSettings::MapTags);
            }

            if (!PluginSettings::ExcludeMapTagsArr.IsEmpty()) {
                params.Set("etag", PluginSettings::ExcludeMapTags);
            }

            if (PluginSettings::TagInclusiveSearch) {
                params.Set("taginclusive", "true");
            }

            if (!PluginSettings::DifficultiesArray.IsEmpty()) {
                params.Set("difficulty", PluginSettings::Difficulties);
            }

            if (PluginSettings::MapAuthor != "") {
                if (PluginSettings::MapAuthor.Contains(",")) PluginSettings::MapAuthor = PluginSettings::MapAuthor.Split(",")[0];
                params.Set("author", PluginSettings::MapAuthor);
            }

            if (PluginSettings::MapName != "") {
                params.Set("name", PluginSettings::MapName);
            }

            if (PluginSettings::MapPackID != 0) {
                params.Set("mappackid", tostring(PluginSettings::MapPackID));
            }
        }

#if TMNEXT
            // prevent loading CharacterPilot maps
            params.Set("vehicle", "1,2,3,4");

            if (
                (RMC::IsRunning || RMC::IsStarting)
                && PluginSettings::RMC_Medal == Medals::WR
                && PluginSettings::MapType != MapTypes::Platform
                && PluginSettings::MapType != MapTypes::Royal
            ) {
                // We only want maps with a WR
                params.Set("inhasrecord", "1");
            }
#elif MP4
            // Fetch in the correct titlepack
            if (TM::CurrentTitlePack() == "TMAll") {
                int envi = Math::Rand(0, tmAllCompatibleTitlepacks.Length);
                params.Set("titlepack", tmAllCompatibleTitlepacks[envi]);
            } else {
                params.Set("titlepack", TM::CurrentTitlePack());
            }
#endif

        switch (PluginSettings::MapType) {
            case MapTypes::Race:
                params.Set("maptype", SUPPORTED_MAP_TYPE);
                break;
            default:
                params.Set("maptype", "TM_" + tostring(PluginSettings::MapType));
                break;
        }

        string urlParams = DictToApiParams(params);
        return url + urlParams;
    }

    string DictToApiParams(dictionary params) {
        string urlParams = "";

        if (!params.IsEmpty()) {
            auto keys = params.GetKeys();
            for (uint i = 0; i < keys.Length; i++) {
                string key = keys[i];
                string value;
                params.Get(key, value);

                urlParams += (i == 0 ? "?" : "&");
                urlParams += key + "=" + Net::UrlEncode(value.Trim());
            }
        }

        return urlParams;
    }
}
