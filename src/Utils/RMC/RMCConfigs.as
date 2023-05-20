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
    string etags;
    string lengthop;
    string length;

    RMCConfig(const Json::Value &in json) {
        if (json.HasKey("prepatch-maps-tags")) {
            for (uint i = 0; i < json["prepatch-maps-tags"].Length; i++)
                prepatchMapTags.InsertLast(RMCConfigMapTag(json["prepatch-maps-tags"][i]));
        }
        if (json.HasKey("search-etags") && json["search-etags"].GetType() == Json::Type::String) etags = json["search-etags"];
#if TMNEXT
        else etags = "23,37,40";
#else
        else etags = "20";
#endif

        if (json.HasKey("search-lengthop") && json["search-lengthop"].GetType() == Json::Type::String) lengthop = json["search-lengthop"];
        else lengthop = "1";
        if (json.HasKey("search-length") && json["search-length"].GetType() == Json::Type::String) length = json["search-length"];
        else length = "9";
    }

    bool isMapHasPrepatchMapTags(const MX::MapInfo &in map) {
        for (uint i = 0; i < prepatchMapTags.Length; i++)
            for (uint j = 0; j < map.Tags.Length; j++)
                if (map.Tags[j].ID == prepatchMapTags[i].ID) {
                    // Check ExeBuild
                    ExeBuild exebuildConfig(prepatchMapTags[i].ExeBuild);
                    ExeBuild exebuildMap(map.ExeBuild);

                    Date@ exeBuildConfig = Date(exebuildConfig.year, exebuildConfig.month, exebuildConfig.day);
                    Date@ exeBuildMap = Date(exebuildMap.year, exebuildMap.month, exebuildMap.day);

                    if (exeBuildMap.isBefore(exeBuildConfig)) {
                        return true;
                    }
                }
        return false;
    }

    RMCConfigMapTag@ getMapPrepatchMapTag(const MX::MapInfo &in map) {
        for (uint i = 0; i < prepatchMapTags.Length; i++)
            for (uint j = 0; j < map.Tags.Length; j++)
                if (map.Tags[j].ID == prepatchMapTags[i].ID)
                    return prepatchMapTags[i];
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

// ExeBuild parser
class ExeBuild {
    int year;
    int month;
    int day;
    string date;
    int hour;
    int min;
    ExeBuild(const string &in exeBuild) {
        date = exeBuild.SubStr(0, exeBuild.IndexOf("_"));
        hour = Text::ParseInt(exeBuild.SubStr(exeBuild.IndexOf('_')+1, 2));
        min = Text::ParseInt(exeBuild.SubStr(exeBuild.IndexOf('_')+4, 2));
        year = Text::ParseInt(date.SubStr(0,4));
        month = Text::ParseInt(date.SubStr(5,2));
        day = Text::ParseInt(date.SubStr(8,2));
    }
}
