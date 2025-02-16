namespace MX
{
    MX::MapInfo@ preloadedMap;
    bool isLoadingPreload = false;

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
            params.Set("author", Net::UrlEncode(PluginSettings::MapAuthor));
            string urlParams = DictToApiParams(params);

            Json::Value _res = API::GetAsync(check_url + urlParams);
            if (_res["Results"].Length == 0) {
                // author does not own any usable map.
                Log::Error(Icons::ExclamationTriangle+" No maps found for author '"+PluginSettings::MapAuthor+"', retrying without author set...");
                PluginSettings::MapAuthor = "";
                return _res;
            } else if (_res["Results"].Length == 1) {
                // author only has one usable map, so we can just return it as the API will troll when using random on it
                return _res["Results"][0];
            }
        }
        if (PluginSettings::MapName != "") {
            params.Set("name", Net::UrlEncode(PluginSettings::MapName));
            string urlParams = DictToApiParams(params);

            Json::Value _res = API::GetAsync(check_url + urlParams);
            if (_res["Results"].Length == 0) {
                // there are no map names matching the filter
                Log::Error(Icons::ExclamationTriangle+" No maps found for name '"+PluginSettings::MapName+"', retrying without name set...");
                PluginSettings::MapName = "";
                return _res;
            } else if (_res["Results"].Length == 1) {
                // there is only one map matching the filter, so we can just return it
                return _res["Results"][0];
            }
        }
        if (PluginSettings::MapAuthor != "" && PluginSettings::MapName != "") {
            params.Set("name", Net::UrlEncode(PluginSettings::MapName));
            params.Set("author", Net::UrlEncode(PluginSettings::MapAuthor));
            string urlParams = DictToApiParams(params);

            Json::Value _res = API::GetAsync(check_url + urlParams);
            if (_res["Results"].Length == 0) {
                // there are no map names matching the filter
                Log::Error(Icons::ExclamationTriangle+" No maps found for author '"+PluginSettings::MapAuthor+"' and name '"+PluginSettings::MapName+"', retrying without name set...");
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
        int64 mapUploadedDate = DateFromStrTime(map.UploadedAt);
        int64 mapUpdatedDate = DateFromStrTime(map.UpdatedAt);
        int64 toDate = DateFromStrTime(PluginSettings::ToYear + "-" + Text::Format("%.02d", PluginSettings::ToMonth) + "-" + Text::Format("%.02d", PluginSettings::ToDay) + "T00:00:00.00");
        int64 fromDate = DateFromStrTime(PluginSettings::FromYear + "-" + Text::Format("%.02d", PluginSettings::FromMonth) + "-" + Text::Format("%.02d", PluginSettings::FromDay) + "T00:00:00.00");
        return (mapUpdatedDate < toDate && mapUpdatedDate > fromDate);
    }


    void PreloadRandomMap()
    {
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
                    PreloadRandomMap();
                    return;
                } else {  // no maps found, retrying without parameters
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
        Log::Trace("PreloadRandomMapRes: "+Json::Write(res));

        Json::Value playedAt = Json::Object();
        Time::Info date = Time::Parse();
        playedAt["Year"] = date.Year;
        playedAt["Month"] = date.Month;
        playedAt["Day"] = date.Day;
        playedAt["Hour"] = date.Hour;
        playedAt["Minute"] = date.Minute;
        playedAt["Second"] = date.Second;
        res["PlayedAt"] = playedAt;

        MX::MapInfo@ map = MX::MapInfo(res);

        if (map is null){
            Log::Warn("Map is null, retrying...");
            PreloadRandomMap();
            return;
        }

        if (RMC::IsRunning || RMC::IsStarting) {
            if (!PluginSettings::CustomRules) {
                if (map.AuthorTime > RMC::allowedMaxLength) {
                    Log::Warn("Map is too long, retrying...");
                    PreloadRandomMap();
                    return;
                }
            }

#if TMNEXT
            if (RMC::selectedGameMode == RMC::GameMode::Together && map.ServerSizeExceeded) {
                Log::Warn("Map is too big to play in servers, retrying...");
                PreloadRandomMap();
                return;
            }

            // Check if map is uploaded to Nadeo Services (if goal == WorldRecord)
            if (PluginSettings::RMC_GoalMedal == RMC::Medals[4]) {
                if (map.OnlineMapId == "" && !MXNadeoServicesGlobal::CheckIfMapExistsAsync(map.MapUid)) {
                    Log::Warn("Map is not uploaded to Nadeo Services, retrying...");
                    PreloadRandomMap();
                    return;
                } else {
                    // if uploaded, get wr
                    uint mapWorldRecord = MXNadeoServicesGlobal::GetMapWorldRecord(map.MapUid);
                    if (int(mapWorldRecord) == -1) {
                        Log::Warn("Couldn't get map World Record, retrying another map...");
                        PreloadRandomMap();
                        return;
                    } else TM::SetWorldRecordToCache(map.MapUid, mapWorldRecord);
                }
            }
#endif
        }

        if (PluginSettings::CustomRules) {
            if (PluginSettings::UseDateInterval) {
                bool isValidDate = isMapInsideDateParams(map);
                if(!isValidDate) {
                    Log::Warn("Looking for new map inside date params...");
                    PreloadRandomMap();
                    return;
                }
            }

            if (PluginSettings::MapLength != "Anything") {
                int minAuthor = GetMinimumLength();
                int maxAuthor = GetMaxLength();

                if ((minAuthor != -1 && map.AuthorTime < minAuthor) || (maxAuthor != -1 && map.AuthorTime > maxAuthor)) {
                    Log::Warn("Map is not the correct length, retrying...");
                    PreloadRandomMap();
                    return;
                }
            }
        }
        isLoadingPreload = false;
        @preloadedMap = map;
    }

    void LoadRandomMap()
    {
        try
        {
            if (TM::CurrentTitlePack() == "") {
                Log::Warn("Please load a title pack first.", true);
                return;
            }
            RandomMapIsLoading = true;
            MX::MapInfo@ map;
            if (RMC::ContinueSavedRun && !RMC::IsInited) {
                Json::Value res = RMC::CurrentMapJsonData;
                Json::Value playedAt = Json::Object();
                Time::Info date = Time::Parse();
                playedAt["Year"] = date.Year;
                playedAt["Month"] = date.Month;
                playedAt["Day"] = date.Day;
                playedAt["Hour"] = date.Hour;
                playedAt["Minute"] = date.Minute;
                playedAt["Second"] = date.Second;
                res["PlayedAt"] = playedAt;

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
            RandomMapIsLoading = false;
            if (PluginSettings::closeOverlayOnMapLoaded) UI::HideOverlay();

#if TMNEXT
            TM::ClosePauseMenu();
#endif

            CTrackMania@ app = cast<CTrackMania>(GetApp());
            app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
            while(!app.ManiaTitleControlScriptAPI.IsReady) {
                yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
            }

#if DEPENDENCY_CHAOSMODE
            if (ChaosMode::IsInRMCMode()) {
                Log::Trace("Loading map in Chaos Mode");
                app.ManiaTitleControlScriptAPI.PlayMap(PluginSettings::RMC_MX_Url+"/mapgbx/"+map.MapId, "TrackMania/ChaosModeRMC", "");
            } else
#endif
            app.ManiaTitleControlScriptAPI.PlayMap(PluginSettings::RMC_MX_Url+"/mapgbx/"+map.MapId, DEFAULT_MODE, "");
            RMC::CurrentMapJsonData = map.ToJson();
        }
        catch
        {
            Log::Warn("Error while loading map ");
            Log::Error(MX_NAME + " API is not responding, it might be down.", true);
            APIDown = true;
            RandomMapIsLoading = false;
        }
    }

    string CreateQueryURL()
    {
        string url = PluginSettings::RMC_MX_Url + "/api/maps";

        dictionary params;
        params.Set("fields", MAP_FIELDS);
        params.Set("random", "1");
        params.Set("count", "1");

        if ((RMC::IsRunning || RMC::IsStarting) && !PluginSettings::CustomRules)
        {
            params.Set("etag", RMC::config.etags);
            params.Set("authortimemax", tostring(RMC::allowedMaxLength));
        }
        else
        {		
            if (PluginSettings::MapLength != "Anything") {
                int minAuthor = GetMinimumLength();
                int maxAuthor = GetMaxLength();

                if (minAuthor != -1) params.Set("authortimemin", tostring(minAuthor));
                if (maxAuthor != -1) params.Set("authortimemax", tostring(maxAuthor));
            }
            if (PluginSettings::UseDateInterval) {
                Date@ afterDate = Date(PluginSettings::FromYear, PluginSettings::FromMonth, PluginSettings::FromDay);
                Date@ beforeDate = Date(PluginSettings::ToYear, PluginSettings::ToMonth, PluginSettings::ToDay);

                if (afterDate.isBefore(beforeDate)) {
                    params.Set("uploadedafter", afterDate.ToString());
                    params.Set("uploadedbefore", beforeDate.ToString());
                } else {
                    Log::Warn("Invalid date interval selected, ignoring...");
                }
            }
            if (!PluginSettings::MapTagsArr.IsEmpty()){
                params.Set("tag", PluginSettings::MapTags);
            }
            if (!PluginSettings::ExcludeMapTagsArr.IsEmpty()){
                params.Set("etag", PluginSettings::ExcludeMapTags);
            }
            if (PluginSettings::TagInclusiveSearch){
                params.Set("taginclusive", "1");
            }
            if (PluginSettings::Difficulty != "Anything"){
                params.Set("difficulty", tostring(PluginSettings::SearchingDifficultys.Find(PluginSettings::Difficulty)-1));
            }
            if (PluginSettings::MapAuthor != "") {
                if (PluginSettings::MapAuthor.Contains(",")) PluginSettings::MapAuthor = PluginSettings::MapAuthor.Split(",")[0];
                params.Set("author", Net::UrlEncode(PluginSettings::MapAuthor));
            }
            if (PluginSettings::MapName != "") {
                params.Set("name", Net::UrlEncode(PluginSettings::MapName));
            }
            if (PluginSettings::MapPackID != 0) {
                params.Set("mappackid", tostring(PluginSettings::MapPackID));
            }
        }

#if TMNEXT
            // prevent loading CharacterPilot maps
            params.Set("vehicle", "1,2,3,4");

            if ((RMC::IsRunning || RMC::IsStarting) && PluginSettings::RMC_GoalMedal == RMC::Medals[4]) {
                // We only want maps with a WR
                params.Set("inhasrecord", "1");
            }
#elif MP4
            // Fetch in the correct titlepack
            if (TM::CurrentTitlePack() == "TMAll" && false) {
                params.Set("titlepack", TM::CurrentTitlePack()+"&titlepack=TMCanyon&titlepack=TMValley&titlepack=TMStadium&titlepack=TMLagoon"); // TODO doesn't work
            } else {
                params.Set("titlepack", TM::CurrentTitlePack());
            }
#endif

        // prevent loading non-Race maps (Royal, flagrush etc...)
        params.Set("maptype", SUPPORTED_MAP_TYPE);

        string urlParams = DictToApiParams(params);
        return url + urlParams;
    }

    int GetMinimumLength() {
        if (PluginSettings::MapLengthOperator == "Anything" || PluginSettings::MapLengthOperator == "Shorter than" || PluginSettings::MapLengthOperator == "Exacts or shorter to") {
            // no minimum required
            return -1;
        }

        int requiredLength = PluginSettings::SearchingMapLengthsMilliseconds[PluginSettings::SearchingMapLengths.Find(PluginSettings::MapLength)];

        if (PluginSettings::MapLengthOperator == "Exactly") {
            // Exactly is probably a bit too strict so we'll allow an about 5 seconds difference
            return requiredLength - 5000;
        } else if (PluginSettings::MapLengthOperator == "Longer than") {
            return requiredLength + 1;
        } else {
            return requiredLength;
        }
    }

    int GetMaxLength() {
        if (PluginSettings::MapLengthOperator == "Anything" || PluginSettings::MapLengthOperator == "Longer than" || PluginSettings::MapLengthOperator == "Exacts or longer to") {
            // no max required
            return -1;
        }

        int requiredLength = PluginSettings::SearchingMapLengthsMilliseconds[PluginSettings::SearchingMapLengths.Find(PluginSettings::MapLength)];

        if (PluginSettings::MapLengthOperator == "Exactly") {
            // Exactly is probably a bit too strict so we'll allow an about 5 seconds difference
            return requiredLength + 5000;
        } else if (PluginSettings::MapLengthOperator == "Shorter than") {
            return requiredLength - 1;
        } else {
            return requiredLength;
        }
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
