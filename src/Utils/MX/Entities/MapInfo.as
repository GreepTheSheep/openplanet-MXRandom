namespace MX
{
    class MapInfo
    {
        int MapId;
        string MapUid;
        string OnlineMapId;
        int UserId;
        string Username;
        string MapType;
        string ExeBuild;
        string UploadedAt;
        string UpdatedAt;
        Json::Value PlayedAt;
        string Name;
        string GbxMapName;
        string TitlePack;
        int AuthorTime;
        int AwardCount;
        int Length;
        bool ServerSizeExceeded;
        array<MapTag@> Tags;

        MapInfo(const Json::Value &in json)
        {
            try {
                MapId = json["MapId"];
                MapUid = json["MapUid"];
                if (json["OnlineMapId"].GetType() != Json::Type::Null) OnlineMapId = json["OnlineMapId"];
                Name = json["Name"];
                MapType = json["MapType"];
                ExeBuild = json["Exebuild"];
                UploadedAt = json["UploadedAt"];
                if (json["PlayedAt"].GetType() != Json::Type::Null) PlayedAt = json["PlayedAt"];
                if (json["GbxMapName"].GetType() != Json::Type::Null) GbxMapName = json["GbxMapName"];
                if (json["TitlePack"].GetType() != Json::Type::Null) TitlePack = json["TitlePack"];
                AwardCount = json["AwardCount"];
                ServerSizeExceeded = json["ServerSizeExceeded"];

                if (json["UpdatedAt"].GetType() != Json::Type::Null) {
                    UpdatedAt = json["UpdatedAt"];
                } else {
                    UpdatedAt = json["UploadedAt"];
                }

                if (json["Uploader"].GetType() != Json::Type::Null) {
                    UserId = json["Uploader"]["UserId"];
                    Username = json["Uploader"]["Name"];
                }

                if (json["Medals"].GetType() != Json::Type::Null) {
                    AuthorTime = json["Medals"]["Author"];
                }

                if (json["Length"].GetType() != Json::Type::Null) {
                    Length = json["Length"];
                } else {
                    Length = AuthorTime;
                }

                // Tags is an array of tag objects
                if (json["Tags"].GetType() != Json::Type::Null) {
                    const Json::Value@ tagObjects = json["Tags"];

                    for (uint i = 0; i < tagObjects.Length; i++) {
                        for (uint j = 0; j < m_mapTags.Length; j++) {
                            if (m_mapTags[j].ID == tagObjects[i]["TagId"]) {
                                Tags.InsertLast(m_mapTags[j]);
                                break;
                            }
                        }
                    }
                }
            } catch {
                Name = json["Name"];
                Log::Warn("Error parsing infos for the map: "+ Name + "\nReason: " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["MapId"] = MapId;
                json["MapUid"] = MapUid;
                json["OnlineMapId"] = OnlineMapId;
                json["Name"] = Name;
                json["MapType"] = MapType;
                json["Exebuild"] = ExeBuild;
                json["UploadedAt"] = UploadedAt;
                json["UpdatedAt"] = UpdatedAt;
                json["PlayedAt"] = PlayedAt;
                json["GbxMapName"] = GbxMapName;
                json["TitlePack"] = TitlePack;
                json["AwardCount"] = AwardCount;
                json["ServerSizeExceeded"] = ServerSizeExceeded;
                json["Length"] = Length;

                Json::Value uploaderObject = Json::Object();
                uploaderObject["UserId"] = UserId;
                uploaderObject["Name"] = Username;

                json["Uploader"] = uploaderObject;

                Json::Value medalsObject = Json::Object();
                medalsObject["Author"] = AuthorTime;

                json["Medals"] = medalsObject;

                Json::Value tagArray = Json::Array();
                for (uint i = 0; i < Tags.Length; i++) {
                    tagArray.Add(Tags[i].ToJson());
                }

                json["Tags"] = tagArray;
            } catch {
                Log::Error("Error converting map info to JSON for map "+Name, true);
            }
            return json;
        }
    }
}