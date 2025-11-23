class RMCConfig {
    array<RMCConfigMapTag@> prepatchMapTags;
    dictionary tags = {
#if TMNEXT
        { "altcar",     "50,54,55,59" }
#endif
    };
    dictionary etags = {
#if TMNEXT
        { "standard",   "6,10,23,37,40,46,49" },
        { "custom",     "6,10,23,37,40,46,49" },
        { "classic",    "23,37,40" },
        { "altcar",     "6,10,11,23,37,40,46,49,52" }
#else
        { "standard",   "6,10,20,39" },
        { "custom",     "6,10,20,39" },
        { "classic",    "20,39" }
#endif
    };
    int length = 180000;
    array<string> blacklistedAuthors;

    RMCConfig() { }

    RMCConfig(const Json::Value &in json) {
        if (json.GetType() == Json::Type::Null || !json.HasKey("next") || !json.HasKey("mp4")) {
            Log::Warn("Failed to fetch RMC config, Openplanet might be down. Defaulting to offline config.", true);
            return;
        }

#if TMNEXT
        const Json::Value@ data = json["next"];
#else
        const Json::Value@ data = json["mp4"];
#endif

        if (data.HasKey("prepatch-maps-tags")) {
            for (uint i = 0; i < data["prepatch-maps-tags"].Length; i++) {
                prepatchMapTags.InsertLast(RMCConfigMapTag(data["prepatch-maps-tags"][i]));
            }
        }

        if (data.HasKey("blacklistedAuthors")) {
            for (uint i = 0; i < data["blacklistedAuthors"].Length; i++) {
                blacklistedAuthors.InsertLast(string(data["blacklistedAuthors"][i]).ToLower());
            }
        }

        if (data.HasKey("category-tags") && data["category-tags"].GetType() == Json::Type::Object) {
            tags = JsonToDict(data["category-tags"]);
        }

        if (data.HasKey("category-etags") && data["category-etags"].GetType() == Json::Type::Object) {
            etags = JsonToDict(data["category-etags"]);
        }

        if (data.HasKey("search-maxlength") && data["search-maxlength"].GetType() == Json::Type::Number) {
            length = data["search-maxlength"];
        }

        Log::Trace("Fetched and loaded RMC configs!", IS_DEV_MODE);
    }

    bool IsAuthorBlacklisted(MX::MapInfo@ map) {
        return blacklistedAuthors.Find(map.Username.ToLower()) > -1;
    }

    bool HasPrepatchTags(MX::MapInfo@ map) {
        for (uint i = 0; i < prepatchMapTags.Length; i++) {
            if (map.HasTag(prepatchMapTags[i].ID)) {
                auto patchDate = Date(prepatchMapTags[i].ExeBuild, "%F_%H_%M");
                auto mapCreation = Date(map.ExeBuild, "%F_%H_%M");

                if (mapCreation.isBefore(patchDate)) {
                    // if map was released before the patch, it's broken
                    return true;
                }
            }
        }

        return false;
    }

    RMCConfigMapTag@ GetPrepatchTag(MX::MapInfo@ map) {
        for (uint i = 0; i < prepatchMapTags.Length; i++) {
            if (map.HasTag(prepatchMapTags[i].ID)) {
                return prepatchMapTags[i];
            }
        }

        return null;
    }

    string GetCategoryTags(RMC::Category runCategory) {
        string name = tostring(runCategory).ToLower();
        string categoryTags = "";

        tags.Get(name, categoryTags);

        return categoryTags;
    }

    string GetCategoryExcludedTags(RMC::Category runCategory) {
        string name = tostring(runCategory).ToLower();
        string categoryTags = "";

        etags.Get(name, categoryTags);

        return categoryTags;
    }
}

class RMCConfigMapTag {
    int ID;
    string ExeBuild;
    string title;
    string reason;

    RMCConfigMapTag(const Json::Value &in json) {
        ID = json["ID"];
        ExeBuild = json["ExeBuild"];
        title = json["title"];
        reason = json["reason"];
    }
}

