class RMCConfigs {
    RMCConfig@ cfgNext;
    RMCConfig@ cfgMP4;

    RMCConfigs(const Json::Value &in json) {
        if (json.HasKey("next")) @cfgNext = RMCConfig(json['next']);
        if (json.HasKey("mp4")) @cfgMP4 = RMCConfig(json['mp4']);
    }
}

class RMCConfig {
    array<RMCConfigMapTag@> prepatchMapTags;
#if TMNEXT
    string etags = "23,37,40";
#else
    string etags = "20";
#endif
    int length = 180000;

    RMCConfig(const Json::Value &in json) {
        if (json.HasKey("prepatch-maps-tags")) {
            for (uint i = 0; i < json["prepatch-maps-tags"].Length; i++) {
                prepatchMapTags.InsertLast(RMCConfigMapTag(json["prepatch-maps-tags"][i]));
            }
        }

        if (json.HasKey("search-etags") && json["search-etags"].GetType() == Json::Type::String) {
            etags = json["search-etags"];
        }

        if (json.HasKey("search-maxlength") && json["search-maxlength"].GetType() == Json::Type::Number) {
            length = json["search-maxlength"];
        }
    }

    bool HasPrepatchTags(const MX::MapInfo &in map) {
        for (uint j = 0; j < map.Tags.Length; j++) {
            for (uint i = 0; i < prepatchMapTags.Length; i++) {
                if (map.Tags[j].ID == prepatchMapTags[i].ID) {
                    auto patchDate = Date(prepatchMapTags[i].ExeBuild, "%F_%H_%M");
                    auto mapCreation = Date(map.ExeBuild, "%F_%H_%M");

                    if (mapCreation.isBefore(patchDate)) {
                        // if map was released before the patch, it's broken
                        return true;
                    }
                }
            }
        }

        return false;
    }

    RMCConfigMapTag@ GetPrepatchTag(const MX::MapInfo &in map) {
        for (uint j = 0; j < map.Tags.Length; j++) {
            for (uint i = 0; i < prepatchMapTags.Length; i++) {
                if (map.Tags[j].ID == prepatchMapTags[i].ID) {
                    return prepatchMapTags[i];
                }
            }
        }

        return null;
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

