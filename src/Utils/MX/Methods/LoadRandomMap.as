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
            Log::Error("An error occurred while getting a random map from ManiaExchange.");
            return null;
        }

        Log::Trace("[GetRandomMap] API response: " + Json::Write(res));

        if (res.GetType() != Json::Type::Object || !res.HasKey("Results")) {
            Log::Error("Something went wrong while getting a random map from ManiaExchange");
            return null;
        } else if (res["Results"].Length == 0) {
            if (PluginSettings::CustomRules) {
                Log::Error("Failed to find a random map with custom parameters");    
            } else {
                Log::Error("Failed to find a random map without custom parameters. This should never happen!");
            }
            return null;
        }

        MX::MapInfo@ map = MX::MapInfo(res["Results"][0]);

        if (map is null) {
            Log::Warn("Map is null, retrying...");
            return null;
        }

        if (RMC::IsRunning || RMC::IsStarting) {
            if (!PluginSettings::CustomRules) {
                if (map.AuthorTime > RMC::config.length) {
                    Log::Warn("Map is too long, retrying...");
                    return null;
                }
            }

#if TMNEXT
            if (RMC::currentGameMode == RMC::GameMode::Together && map.ServerSizeExceeded) {
                Log::Warn("Map is too big to play in servers, retrying...");
                return null;
            }

            // Check if map is uploaded to Nadeo Services (if goal == WorldRecord)
            if (PluginSettings::RMC_Medal == Medals::WR) {
                if (PluginSettings::CustomRules && (PluginSettings::MapType == MapTypes::Platform || PluginSettings::MapType == MapTypes::Royal)) {
                    // Platform and Royal don't support leaderboards
                    Log::Warn("Game mode " + tostring(PluginSettings::MapType) + " doesn't support leaderboards. Using AT as fallback for WR.");
                    TM::SetWorldRecordToCache(map.MapUid, map.AuthorTime);
                } else {
                    if (map.OnlineMapId == "" && !MXNadeoServicesGlobal::CheckIfMapExistsAsync(map.MapUid)) {
                        Log::Warn("Map is not uploaded to Nadeo Services, retrying...");
                        return null;
                    }

                    // if uploaded, get wr
                    int mapWorldRecord = MXNadeoServicesGlobal::GetMapWorldRecord(map.MapUid);

                    if (mapWorldRecord == -1) {
                        Log::Warn("Couldn't get map World Record, retrying another map...");
                        return null;
                    }

                    TM::SetWorldRecordToCache(map.MapUid, mapWorldRecord);
                }
            }
#endif
        }

        if ((!PluginSettings::CustomRules || PluginSettings::FilterLowEffort) && IsMapLowEffort(map)) {
            Log::Warn("Map is most likely low effort, skipping...");
            return null;
        }

        if ((!PluginSettings::CustomRules || PluginSettings::FilterUntagged) && IsMapUntagged(map)) {
            Log::Warn("Map is most likely missing a default filtered tag, skipping...");
            return null;
        }

        if (PluginSettings::CustomRules) {
            if (PluginSettings::UseDateInterval) {
                int64 toDate = Time::ParseFormatString('%F', PluginSettings::ToDate);
                int64 fromDate = Time::ParseFormatString('%F', PluginSettings::FromDate);

                // only check if date range is valid
                if (fromDate < toDate && !isMapInsideDateParams(map)) {
                    Log::Warn("Looking for new map inside date params...");
                    return null;
                }
            }

            if (PluginSettings::UseCustomLength) {
                if (PluginSettings::MinLength != 0 && map.AuthorTime < PluginSettings::MinLength) {
                    Log::Warn("Map is shorter than the requested length, retrying...");
                    return null;
                }

                if (PluginSettings::MaxLength != 0 && map.AuthorTime > PluginSettings::MaxLength) {
                    Log::Warn("Map is longer than the requested length, retrying...");
                    return null;
                }
            } else if (map.AuthorTime > RMC::config.length) {
                Log::Warn("Map is too long, retrying...");
                return null;
            }

            if (PluginSettings::ExcludedTerms != "") {
                string termsRegex = string::Join(PluginSettings::ExcludedTermsArr, "|");

                if (PluginSettings::TermsExactMatch) {
                    // Use word boundaries to only find exact matches
                    termsRegex = "\\b(" + termsRegex + ")\\b";
                }

                if (Regex::Contains(map.Name, termsRegex, Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map contains an excluded term, retrying...");
                    return null;
                }
            }

            if (PluginSettings::ExcludedAuthors != "") {
                foreach (string author : PluginSettings::ExcludedAuthorsArr) {
                    if (map.Username.ToLower() == author) {
                        Log::Warn("Map is uploaded by an excluded author, retrying...");
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
                        Log::Warn("Failed to find a map with custom parameters. Searching without them...", true);
                        PluginSettings::CustomRules = false;
                        attempts = 0;
                    } else {
                        Log::Error("Failed to get a random map after 15 attempts.", true);
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

            if (RMC::IsRunning || RMC::IsStarting) {
                if (PluginSettings::RMC_Medal == Medals::WR) {
                    if (PluginSettings::MapType != MapTypes::Platform && PluginSettings::MapType != MapTypes::Royal) {
                        params.Set("inhasrecord", "1");
                    }
                }
            }
        } else {
            params.Set("maptype", SUPPORTED_MAP_TYPE);

            if (RMC::IsRunning || RM::IsStarting) {
                params.Set("etag", RMC::config.etags);
                params.Set("authortimemax", tostring(RMC::config.length));

                if (PluginSettings::RMC_Medal == Medals::WR) {
                    // We only want maps with a WR
                    params.Set("inhasrecord", "1");
                }
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
