namespace MX
{
    MX::MapInfo@ preloadedMap;
    bool isLoadingPreload = false;

    Json::Value CheckCustomRulesParametersNoResults() {
        // for some reason if we use random it *always* returns a webpage instead of an actual dict response if no items are found. It also sometimes does not find any items even though there are some.
        // So we have to use a non-random API call which then gives us a dict from which we can check if any item would exist with the specified parameters.
        string check_url = PluginSettings::RMC_MX_Url + "/mapsearch2/search?api=on&limit=1";
#if TMNEXT
        // ignore CharacterPilot maps
        check_url += "&vehicles=1";
#elif MP4
        // only consider the correct titlepack
        if (TM::CurrentTitlePack() == "TMAll") {
            check_url += "&tpack=" + TM::CurrentTitlePack()+"&tpack=TMCanyon&tpack=TMValley&tpack=TMStadium&tpack=TMLagoon";
        } else {
            check_url += "&tpack=" + TM::CurrentTitlePack();
        }
#endif
        // ignore any non-Race maps (Royal, flagrush etc...)
        check_url += "&mtype="+SUPPORTED_MAP_TYPE;
        if (PluginSettings::MapAuthor != "") {
            Json::Value _res = API::GetAsync(check_url + "&author=" + Net::UrlEncode(PluginSettings::MapAuthor));
            if (_res["totalItemCount"] == 0) {
                // author does not own any usable map.
                Log::Error(Icons::ExclamationTriangle+" No maps found for author '"+PluginSettings::MapAuthor+"', retrying without author set...");
                PluginSettings::MapAuthor = "";
                return _res;
            } else if (_res["totalItemCount"] == 1) {
                // author only has one usable map, so we can just return it as the API will troll when using random on it
                return _res["results"][0];
            }
        }
        if (PluginSettings::MapName != "") {
            Json::Value _res = API::GetAsync(check_url + "&trackname=" + Net::UrlEncode(PluginSettings::MapName));
            if (_res["totalItemCount"] == 0) {
                // there are no map names matching the filter
                Log::Error(Icons::ExclamationTriangle+" No maps found for name '"+PluginSettings::MapName+"', retrying without name set...");
                PluginSettings::MapName = "";
                return _res;
            } else if (_res["totalItemCount"] == 1) {
                // there is only one map matching the filter, so we can just return it
                return _res["results"][0];
            }
        }
        if (PluginSettings::MapAuthor != "" && PluginSettings::MapName != "") {
            Json::Value _res = API::GetAsync(check_url + "&author=" + Net::UrlEncode(PluginSettings::MapAuthor) + "&trackname=" + Net::UrlEncode(PluginSettings::MapName));
            if (_res["totalItemCount"] == 0) {
                // there are no map names matching the filter
                Log::Error(Icons::ExclamationTriangle+" No maps found for author '"+PluginSettings::MapAuthor+"' and name '"+PluginSettings::MapName+"', retrying without name set...");
                PluginSettings::MapName = "";
                return _res;
            } else if (_res["totalItemCount"] == 1) {
                // there is only one map matching the filter, so we can just return it
                return _res["results"][0];
            }
        }

        Json::Value retval = Json::Object();
        retval["hasMaps"] = true;
        return retval;
    }

    void PreloadRandomMap()
    {
        isLoadingPreload = true;
        string URL = CreateQueryURL();
        Json::Value res;
        try {
            res = API::GetAsync(URL)["results"][0];
        } catch {
            if (PluginSettings::CustomRules || (!RMC::IsStarting && !RMC::IsRunning)) {
                // we might get an error because the author doesn't have a map/no map with the given name exists
                // if we do not detect that there are no matching results, we will enter an infinite loop with errors
                // that will force the user to reload the plugin
                Json::Value check = CheckCustomRulesParametersNoResults();
                if (check.HasKey("TrackID")) {
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

        if (
            (((RMC::IsRunning || RMC::IsStarting) && PluginSettings::CustomRules && PluginSettings::MapAuthorNameNeedsExactMatch) 
            || (!RMC::IsRunning && !RMC::IsStarting && PluginSettings::MapAuthorNameNeedsExactMatch)) && PluginSettings::MapAuthor != ""
        ) {
            string author = map.Username.ToLower();
            print(PluginSettings::MapAuthorNamesArr.Find(author));
            if (PluginSettings::MapAuthorNamesArr.Find(author) == -1) {
                Log::Warn("Map author does not match, retrying...");
                PreloadRandomMap();
                return;
            }
        }

        if (!PluginSettings::UseLengthChecksInRequests) {
            if ((RMC::IsRunning || RMC::IsStarting) && !PluginSettings::CustomRules) {
                if (RMC::allowedMapLengths.Find(map.LengthName) == -1) {
                    Log::Warn("Map is too long, retrying...");
                    PreloadRandomMap();
                    return;
                }
            } else if (PluginSettings::MapLength != "Anything") {
                int requiredLength = PluginSettings::SearchingMapLengthsMilliseconds[PluginSettings::SearchingMapLengths.Find(PluginSettings::MapLength)];
                switch (PluginSettings::SearchingMapLengthOperators.Find(PluginSettings::MapLengthOperator)) {
                    case 0:  // exact is prorbably a bit too strict so we'll allow an about 15 seconds difference
                        if (requiredLength == 100000000) {
                            if (map.AuthorTime <= 300000+15000) {
                                Log::Warn("Map is too short, retrying...");
                                PreloadRandomMap();
                                return;
                            } else {
                                break;
                            }
                        } else if ((map.AuthorTime < requiredLength-15000) || (map.AuthorTime > requiredLength+15000)) {
                            Log::Warn("Map is not the correct length, retrying...");
                            PreloadRandomMap();
                            return;
                        }
                        break;

                    case 1:
                        if (requiredLength == 100000000) {
                            if (map.AuthorTime > 300000) {
                                Log::Warn("Map is too long, retrying...");
                                PreloadRandomMap();
                                return;
                            } else {
                                break;
                            }
                        } else if (!(map.AuthorTime < requiredLength)) {
                            Log::Warn("Map is not the correct length, retrying...");
                            PreloadRandomMap();
                            return;
                        }
                        break;

                    case 2:
                        if (requiredLength == 100000000) {
                            if (map.AuthorTime < 300000+10000) {
                                Log::Warn("Map is too short, retrying...");
                                PreloadRandomMap();
                                return;
                            } else {
                                break;
                            }
                        } else if (!(map.AuthorTime > requiredLength)) {
                            Log::Warn("Map is not the correct length, retrying...");
                            PreloadRandomMap();
                            return;
                        }
                        break;

                    case 3:
                        if (requiredLength == 100000000) {
                            // everything is shorter than long, do nothing
                        } else if (!(map.AuthorTime <= requiredLength)) {
                            Log::Warn("Map is not the correct length, retrying...");
                            PreloadRandomMap();
                            return;
                        }
                        break;

                    case 4:
                        if (requiredLength == 100000000) {
                            if (map.AuthorTime <= 300000) {
                                Log::Warn("Map is too long, retrying...");
                                PreloadRandomMap();
                                return;
                            } else {
                                break;
                            }
                        } else if (!(map.AuthorTime >= requiredLength)) {
                            Log::Warn("Map is not the correct length, retrying...");
                            PreloadRandomMap();
                            return;
                        }
                        break;
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
#if TMNEXT
                string url = "https://trackmania.exchange/api/maps/get_map_info/id/" + tostring(RMC::CurrentMapID);
#else
                string url = MX_URL + "/api/maps/get_map_info/id/" + tostring(RMC::CurrentMapID);
#endif
                Json::Value res = API::GetAsync(url);
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
                app.ManiaTitleControlScriptAPI.PlayMap(PluginSettings::RMC_MX_Url+"/maps/download/"+map.TrackID, "TrackMania/ChaosModeRMC", "");
            } else
#endif
            app.ManiaTitleControlScriptAPI.PlayMap(PluginSettings::RMC_MX_Url+"/maps/download/"+map.TrackID, "", "");
            RMC::CurrentMapID = map.TrackID;
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
        string url = PluginSettings::RMC_MX_Url+"/mapsearch2/search?api=on&random=1";

        if ((RMC::IsRunning || RMC::IsStarting) && !PluginSettings::CustomRules)
        {
            url += "&etags="+RMC::config.etags;
            if (PluginSettings::UseLengthChecksInRequests) {
                url += "&lengthop="+RMC::config.lengthop;
                url += "&length="+RMC::config.length;
            }
        }
        else
        {
            if (PluginSettings::UseLengthChecksInRequests) {
                if (PluginSettings::MapLengthOperator != "Exacts"){
                    url += "&lengthop=" + PluginSettings::SearchingMapLengthOperators.Find(PluginSettings::MapLengthOperator);
                }
                if (PluginSettings::MapLength != "Anything"){
                    url += "&length=" + (PluginSettings::SearchingMapLengths.Find(PluginSettings::MapLength)-1);
                }
            }
            if (!PluginSettings::MapTagsArr.IsEmpty()){
                url += "&tags=" + PluginSettings::MapTags;
            }
            if (!PluginSettings::ExcludeMapTagsArr.IsEmpty()){
                url += "&etags=" + PluginSettings::ExcludeMapTags;
            }
            if (PluginSettings::TagInclusiveSearch){
                url += "&tagsinc=1";
            }
            if (PluginSettings::Difficulty != "Anything"){
                url += "&difficulty=" + (PluginSettings::SearchingDifficultys.Find(PluginSettings::Difficulty)-1);
            }
            if (PluginSettings::MapAuthor != "") {
                url += "&author=" + Net::UrlEncode(PluginSettings::MapAuthor);
            }
            if (PluginSettings::MapName != "") {
                url += "&trackname=" + Net::UrlEncode(PluginSettings::MapName);
            }
            if (PluginSettings::MapPackID != 0) {
                url += "&mid=" + PluginSettings::MapPackID;
            }
        }

#if TMNEXT
            // prevent loading CharacterPilot maps
            url += "&vehicles=1";
#elif MP4
            // Fetch in the correct titlepack
            if (TM::CurrentTitlePack() == "TMAll") {
                url += "&tpack=" + TM::CurrentTitlePack()+"&tpack=TMCanyon&tpack=TMValley&tpack=TMStadium&tpack=TMLagoon";
            } else {
                url += "&tpack=" + TM::CurrentTitlePack();
            }
#endif

        // prevent loading non-Race maps (Royal, flagrush etc...)
        url += "&mtype="+SUPPORTED_MAP_TYPE;

        return url;
    }
}