namespace MX {
    bool isLoadingPreload = false;

    // "Unassigned" = MP1 Canyon and TMF Stadium maps. They are guaranteed to be compatible as editing the map would change the title ID.
    const array<string> tmAllCompatibleTitlepacks = { "TMAll", "TMCanyon", "TMStadium", "TMValley", "TMLagoon", "Unassigned" };

    bool isMapInsideDateParams(const MX::MapInfo@ &in map) {
        int64 mapUpdatedDate = Time::ParseFormatString('%FT%T', map.UpdatedAt);
        int64 fromDate = Time::ParseFormatString('%F', PluginSettings::FromDate);
        int64 toDate = Time::ParseFormatString('%F', PluginSettings::ToDate);

        return (mapUpdatedDate <= toDate && mapUpdatedDate >= fromDate);
    }


    MX::MapInfo@ GetRandomMap() {
        string URL = CreateQueryURL();
        Json::Value res;

        try {
            res = API::GetAsync(URL);
        } catch {
            Log::Error("[GetRandomMap] An error occurred while getting a random map from ManiaExchange.");
            return null;
        }

        Log::Trace("[GetRandomMap] API response: " + Json::Write(res));

        if (res.GetType() != Json::Type::Object || !res.HasKey("Results")) {
            Log::Error("[GetRandomMap] Something went wrong while getting a random map from ManiaExchange");
            return null;
        } else if (res["Results"].Length == 0) {
            if (PluginSettings::CustomRules) {
                Log::Error("[GetRandomMap] Failed to find a random map with custom parameters");    
            } else {
                Log::Error("[GetRandomMap] Failed to find a random map without custom parameters. This should never happen!");
            }
            return null;
        }

        MX::MapInfo@ map;

        try {
            @map = MX::MapInfo(res["Results"][0]);
        } catch {
            Log::Warn("[GetRandomMap] Failed to parse map info from MX, skipping...");
            return null;
        }

        if (map is null) {
            Log::Warn("[GetRandomMap] Map is null, skipping...");
            return null;
        }

        if (RMC::currentRun.IsRunning || RMC::currentRun.IsStarting) {
            if (!PluginSettings::CustomRules) {
                if (map.AuthorTime > RMC::config.length) {
                    Log::Warn("[GetRandomMap] Map AT (" + Time::Format(map.AuthorTime) + ") is longer than the max length for RMC (" + Time::Format(RMC::config.length) + "), skipping...");
                    return null;
                }
            }

            if (IsMapImpossible(map)) {
                Log::Warn("Map is part of the cheated/broken/impossible ATs mappack, skipping...");
                return null;
            }

            if ((!PluginSettings::CustomRules || PluginSettings::MapAuthorNamesArr.Find(map.Username.ToLower()) == -1) && RMC::config.IsAuthorBlacklisted(map)) {
                Log::Warn("[GetRandomMap] Map is from a blacklisted author, skipping...");
                return null;
            }

            if ((!PluginSettings::CustomRules || PluginSettings::FilterLowEffort) && IsMapLowEffort(map)) {
                Log::Warn("[GetRandomMap] Map is most likely low effort, skipping...");
                return null;
            }

            if ((!PluginSettings::CustomRules || PluginSettings::FilterUntagged) && IsMapUntagged(map)) {
                Log::Warn("[GetRandomMap] Map is most likely missing a default filtered tag, skipping...");
                return null;
            }

#if TMNEXT
            if (RMC::currentRun.Mode == RMC::GameMode::Together) {
                if (map.ServerSizeExceeded) {
                    Log::Warn("[GetRandomMap] Map is too big to play in Random Map Together, skipping...");
                    return null;
                }

                if (!map.IsUploadedToServers) {
                    Log::Warn("[GetRandomMap] Map is not uploaded to Nadeo Services, skipping...");
                    return null;
                }
            }

            if (PluginSettings::RMC_Medal == Medals::WR) {
                if (PluginSettings::CustomRules && (PluginSettings::MapType == MapTypes::Platform || PluginSettings::MapType == MapTypes::Royal)) {
                    // Platform and Royal don't support leaderboards
                    Log::Warn("[GetRandomMap] Game mode " + tostring(PluginSettings::MapType) + " doesn't support leaderboards. Using AT as fallback for WR.");
                    TM::SetWorldRecordToCache(map.MapUid, map.AuthorTime);
                } else {
                    if (!map.IsUploadedToServers) {
                        Log::Warn("[GetRandomMap] Map is not uploaded to Nadeo Services, skipping...");
                        return null;
                    }

                    // if uploaded, get wr
                    int mapWorldRecord = MXNadeoServicesGlobal::GetMapWorldRecord(map.MapUid);

                    if (mapWorldRecord == -1) {
                        Log::Warn("[GetRandomMap] Couldn't get the World Record for map ID #" + map.MapId + ", skipping...");
                        return null;
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
                    Log::Warn("[GetRandomMap] Map is outside the date interval set, skipping...");
                    return null;
                }
            }

            if (PluginSettings::UseCustomLength) {
                if (PluginSettings::MinLength != 0 && map.AuthorTime < PluginSettings::MinLength) {
                    Log::Warn("[GetRandomMap] Map is shorter than the requested length, skipping...");
                    return null;
                }

                if (PluginSettings::MaxLength != 0 && map.AuthorTime > PluginSettings::MaxLength) {
                    Log::Warn("[GetRandomMap] Map is longer than the requested length, skipping...");
                    return null;
                }
            }

            if (PluginSettings::ExcludedTerms != "") {
                string termsRegex = string::Join(PluginSettings::ExcludedTermsArr, "|");

                if (PluginSettings::TermsExactMatch) {
                    // Use word boundaries to only find exact matches
                    termsRegex = "\\b(" + termsRegex + ")\\b";
                }

                if (Regex::Contains(map.Name, termsRegex, Regex::Flags::CaseInsensitive)) {
                    Log::Warn("[GetRandomMap] Map name contains an excluded term, skipping...");
                    return null;
                }
            }

            if (PluginSettings::ExcludedAuthors != "") {
                foreach (string author : PluginSettings::ExcludedAuthorsArr) {
                    if (map.Username.ToLower() == author) {
                        Log::Warn("[GetRandomMap] Map is uploaded by the excluded author \"" + author + "\", skipping...");
                        return null;
                    }
                }
            }
        }

        return map;
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

            int attempts = 0;

            while (true) {
                @map = GetRandomMap();

                if (map !is null) {
                    break;
                }

                attempts++;

                if (attempts >= 15) {
                    if (PluginSettings::CustomRules) {
                        Log::Warn("[LoadRandomMap] Failed to find a map with custom parameters. Searching without them...", true);
                        PluginSettings::CustomRules = false;
                        attempts = 0;
                    } else {
                        Log::Error("[LoadRandomMap] Failed to get a random map after 15 attempts.", true);
                        return;
                    }
                }

                sleep(2000);
            }

            Log::LoadingMapNotification(map);

            DataManager::SaveMapToRecentlyPlayed(map);

            await(startnew(TM::LoadMap, map));

            RandomMapIsLoading = false;
        } catch {
            Log::Warn("[LoadRandomMap] Error while loading map: " + getExceptionInfo());
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
#if TMNEXT
        params.Set("vehicle", "1,2,3,4"); // prevent loading CharacterPilot maps
#elif MP4
        if (TM::CurrentTitlePack() == "TMAll") {
            int envi = Math::Rand(0, tmAllCompatibleTitlepacks.Length);
            params.Set("titlepack", tmAllCompatibleTitlepacks[envi]);
        } else {
            params.Set("titlepack", TM::CurrentTitlePack());
        }
#endif

        if (PluginSettings::CustomRules && customParameters) {
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
            } else {
                // avoids broken uploads, maps not available yet in other APIs, and maps targeting runs
                string yesterday = Time::FormatStringUTC("%F", Time::Stamp - (24 * 60 * 60));
                params.Set("before", yesterday);
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

            if (PluginSettings::MapType == MapTypes::Race) {
                params.Set("maptype", SUPPORTED_MAP_TYPE);
            } else {
                params.Set("maptype", "TM_" + tostring(PluginSettings::MapType));
            }

            if (RMC::currentRun.IsRunning || RMC::currentRun.IsStarting) {
#if TMNEXT
                if (PluginSettings::RMC_Medal == Medals::WR) {
                    if (PluginSettings::MapType != MapTypes::Platform && PluginSettings::MapType != MapTypes::Royal) {
                        params.Set("inhasrecord", "1");
                    }
                }
#endif
            }
        } else {
            params.Set("maptype", SUPPORTED_MAP_TYPE);

            if (RMC::currentRun.IsRunning || RMC::currentRun.IsStarting) {
                params.Set("etag", RMC::config.etags);
                params.Set("authortimemax", tostring(RMC::config.length));

                // avoids broken uploads, maps not available yet in other APIs, and maps targeting runs
                string yesterday = Time::FormatStringUTC("%F", Time::Stamp - (24 * 60 * 60));
                params.Set("before", yesterday);

#if TMNEXT
                if (PluginSettings::RMC_Medal == Medals::WR) {
                    // We only want maps with a WR
                    params.Set("inhasrecord", "1");
                }
#endif
            }
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
