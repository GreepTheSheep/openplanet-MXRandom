class RMCConfigs {
    RMCConfig@ cfgNext;
    RMCConfig@ cfgMP4;

    RMCConfigs(const Json::Value &in json) {
        if (json.HasKey("next")) @cfgNext = RMCConfig(json['next']);
        if (json.HasKey("mp4")) @cfgMP4 = RMCConfig(json['mp4']);
    }
}

class RMCConfig {
    array<RMCConfigMapTags@> prepatchMapTags;

    RMCConfig(const Json::Value &in json) {
        if (json.HasKey("prepatch-maps-tags")) {
            for (uint i = 0; i < json["prepatch-maps-tags"].Length; i++)
                prepatchMapTags.InsertLast(RMCConfigMapTags(json["prepatch-maps-tags"][i]));
        }
    }
}

class RMCConfigMapTags {
    int ID;
    string ExeBuild;
    string reason;

    RMCConfigMapTags(const Json::Value &in json) {
        ID = json["ID"];
        ExeBuild = json["ExeBuild"];
        reason = json["reason"];
    }
}