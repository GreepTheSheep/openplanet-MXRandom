namespace MX {
    class MapInfo {
        int MapId;
        string MapUid;
        string OnlineMapId;
        int UserId;
        string Username;
        string MapType;
        string ExeBuild;
        string UploadedAt;
        string UpdatedAt;
        int UploadedAtTimestamp;
        int UpdatedAtTimestamp;
        int PlayedAt;
        string Name;
        string GbxMapName;
        string TitlePack;
        int AuthorTime;
        int GoldTime;
        int SilverTime;
        int BronzeTime;
        int AwardCount;
        int Length;
        bool ServerSizeExceeded;
        array<MapTag@> Tags;

        MapInfo(const Json::Value &in json) {
            try {
                MapId = json["MapId"];
                MapUid = json["MapUid"];
                if (json["OnlineMapId"].GetType() != Json::Type::Null) OnlineMapId = json["OnlineMapId"];
                Name = json["Name"];
                MapType = json["MapType"];
                ExeBuild = json["Exebuild"];
                UploadedAt = json["UploadedAt"];
                if (json["GbxMapName"].GetType() != Json::Type::Null) GbxMapName = json["GbxMapName"];
                if (json["TitlePack"].GetType() != Json::Type::Null) TitlePack = json["TitlePack"];
                AwardCount = json["AwardCount"];
                ServerSizeExceeded = json["ServerSizeExceeded"];

                if (json.HasKey("PlayedAt") && json["PlayedAt"].GetType() != Json::Type::Null) PlayedAt = json["PlayedAt"];
                else PlayedAt = Time::Stamp;

                if (json["UpdatedAt"].GetType() != Json::Type::Null) {
                    UpdatedAt = json["UpdatedAt"];
                } else {
                    UpdatedAt = json["UploadedAt"];
                }

                try {
                    UploadedAtTimestamp = Time::ParseFormatString('%FT%T', this.UploadedAt);
                    UpdatedAtTimestamp = Time::ParseFormatString('%FT%T', this.UpdatedAt);
                } catch {
                    UploadedAtTimestamp = 0;
                    UpdatedAtTimestamp = 0;
                }

                if (json["Uploader"].GetType() != Json::Type::Null) {
                    UserId = json["Uploader"]["UserId"];
                    Username = json["Uploader"]["Name"];
                }

                if (json["Medals"].GetType() != Json::Type::Null) {
                    AuthorTime = json["Medals"]["Author"];

                    if (!json["Medals"].HasKey("Gold")) {
                        GoldTime = GetDefaultMedalTime(Medals::Gold);
                    } else {
                        GoldTime = json["Medals"]["Gold"];
                    }

                    if (!json["Medals"].HasKey("Silver")) {
                        SilverTime = GetDefaultMedalTime(Medals::Silver);
                    } else {
                        SilverTime = json["Medals"]["Silver"];
                    }

                    if (!json["Medals"].HasKey("Bronze")) {
                        BronzeTime = GetDefaultMedalTime(Medals::Bronze);
                    } else {
                        BronzeTime = json["Medals"]["Bronze"];
                    }
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

                    if (Tags.Length > 1) {
                        Tags.Sort(function(a, b) { return a.Name < b.Name; });
                    }
                }
            } catch {
                Name = json["Name"];
                Log::Warn("Error parsing infos for the map: " + Name + "\nReason: " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson() {
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
                medalsObject["Gold"] = GoldTime;
                medalsObject["Silver"] = SilverTime;
                medalsObject["Bronze"] = BronzeTime;

                json["Medals"] = medalsObject;

                Json::Value tagArray = Json::Array();
                for (uint i = 0; i < Tags.Length; i++) {
                    tagArray.Add(Tags[i].ToJson());
                }

                json["Tags"] = tagArray;
            } catch {
                Log::Error("Error converting map info to JSON for map " + Name, true);
            }
            return json;
        }

        bool get_IsUploadedToServers() {
#if TMNEXT
            if (this.OnlineMapId != "") {
                return true;
            } 
            
            return MXNadeoServicesGlobal::CheckIfMapExistsAsync(this.MapUid);
#else
            return false;
#endif
        }

        bool HasTag(int tagId) {
            for (uint i = 0; i < Tags.Length; i++) {
                if (Tags[i].ID == tagId) {
                    return true;
                }
            }

            return false;
        }

        bool HasTag(const string &in tagName) {
            for (uint i = 0; i < Tags.Length; i++) {
                if (Tags[i].Name == tagName) {
                    return true;
                }
            }

            return false;
        }

        MapTypes get_Type() {
            if (this.MapType.Contains("Stunt")) {
                return MapTypes::Stunt;
            } else if (this.MapType.Contains("Platform")) {
                return MapTypes::Platform;
            } else if (this.MapType.EndsWith("Royal")) {
                return MapTypes::Royal;
            }

            return MapTypes::Race;
        }

        uint GetMedalTime(Medals medal) {
            switch (medal) {
#if TMNEXT
                case Medals::WR:
                    return TM::GetWorldRecordFromCache(this.MapUid);
#endif
                case Medals::Author:
                    return this.AuthorTime;
                case Medals::Gold:
                    return this.GoldTime;
                case Medals::Silver:
                    return this.SilverTime;
                case Medals::Bronze:
                    return this.BronzeTime;
                default:
                    return uint(-1);
            }
        }

        uint GetDefaultMedalTime(Medals medal) {
            uint normalGold;
            uint normalSilver;
            uint normalBronze;

            switch (this.Type) {
                case MapTypes::Stunt:
                    // Credits to beu and Ezio for the formula
                    normalGold = uint(Math::Floor(AuthorTime * 0.085) * 10);
                    normalSilver = uint(Math::Floor(AuthorTime * 0.06) * 10);
                    normalBronze = uint(Math::Floor(AuthorTime * 0.037) * 10);
                    break;
                case MapTypes::Platform:
                    normalGold = AuthorTime + 3;
                    normalSilver = AuthorTime + 10;
                    normalBronze = AuthorTime + 30;
                    break;
                case MapTypes::Race:
                case MapTypes::Royal:
                default:
                    normalGold = uint((AuthorTime * 1.06) / 1000 + 1) * 1000;
                    normalSilver = uint((AuthorTime * 1.2) / 1000 + 1) * 1000;
                    normalBronze = uint((AuthorTime * 1.5) / 1000 + 1) * 1000;
                    break;
            }

            switch (medal) {
#if TMNEXT
                case Medals::WR:
                    return TM::GetWorldRecordFromCache(this.MapUid);
#endif
                case Medals::Author:
                    return AuthorTime;
                case Medals::Gold:
                    return normalGold;
                case Medals::Silver:
                    return normalSilver;
                case Medals::Bronze:
                    return normalBronze;
                default:
                    return uint(-1);
            }
        }

        bool get_HasEditedMedals() {
            for (uint i = 0; i <= Medals::Gold; i++) {
                if (IsMedalEdited(Medals(i))) {
                    return true;
                }
            }

            return false;
        }

        bool IsMedalEdited(Medals medal) {
            if (medal >= Medals::Author) {
                return false;
            }

            bool inverse = this.Type == MapTypes::Stunt;
            int medalTime = GetMedalTime(medal);
            int defaultTime = GetDefaultMedalTime(medal);

            if (!inverse && medalTime < defaultTime) {
                return true;
            }

            if (inverse && medalTime > defaultTime) {
                return true;
            }

            return false;
        }

        bool opEquals(MapInfo@ other) {
            return this.MapId == other.MapId;
        }

        string toString() {
            return this.Name + " by " + this.Username;
        }
    }
}