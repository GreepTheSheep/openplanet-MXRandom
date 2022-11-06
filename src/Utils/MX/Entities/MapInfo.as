namespace MX
{
    class MapInfo
    {
        int TrackID;
        string TrackUID;
        int UserID;
        string Username;
        string AuthorLogin;
        string MapType;
        string ExeBuild;
        string UploadedAt;
        string UpdatedAt;
        Json::Value PlayedAt;
        string Name;
        string GbxMapName;
        string Comments;
        string TitlePack;
        bool Unlisted;
        string Mood;
        int DisplayCost;
        string LengthName;
        int Laps;
        string DifficultyName;
        string VehicleName;
        int AuthorTime;
        int TrackValue;
        int AwardCount;
        uint ImageCount;
        bool IsMP4;
        array<MapTag@> Tags;

        MapInfo(const Json::Value &in json)
        {
            try {
                TrackID = json["TrackID"];
                TrackUID = json["TrackUID"];
                UserID = json["UserID"];
                Username = json["Username"];
                AuthorLogin = json["AuthorLogin"];
                MapType = json["MapType"];
                ExeBuild = json["ExeBuild"];
                UploadedAt = json["UploadedAt"];
                UpdatedAt = json["UpdatedAt"];
                if (json["PlayedAt"].GetType() != Json::Type::Null) PlayedAt = json["PlayedAt"];
                Name = json["Name"];
                GbxMapName = json["GbxMapName"];
                Comments = json["Comments"];
                if (json["TitlePack"].GetType() != Json::Type::Null) TitlePack = json["TitlePack"];
                Unlisted = json["Unlisted"];
                Mood = json["Mood"];
                DisplayCost = json["DisplayCost"];
                if (json["LengthName"].GetType() != Json::Type::Null) LengthName = json["LengthName"];
                Laps = json["Laps"];
                if (json["DifficultyName"].GetType() != Json::Type::Null) DifficultyName = json["DifficultyName"];
                if (json["VehicleName"].GetType() != Json::Type::Null) VehicleName = json["VehicleName"];
                if (json["AuthorTime"].GetType() != Json::Type::Null) AuthorTime = json["AuthorTime"];
                TrackValue = json["TrackValue"];
                AwardCount = json["AwardCount"];
                ImageCount = json["ImageCount"];
                IsMP4 = json["IsMP4"];

                // Tags is a string of ids separated by commas
                // gets the ids and fetches the tags from m_mapTags
                if (json["Tags"].GetType() != Json::Type::Null)
                {
                    string tagIds = json["Tags"];
                    string[] tagIdsSplit = tagIds.Split(",");
                    for (uint i = 0; i < tagIdsSplit.get_Length(); i++)
                    {
                        int tagId = Text::ParseInt(tagIdsSplit[i]);
                        for (uint j = 0; j < m_mapTags.get_Length(); j++)
                        {
                            if (m_mapTags[j].ID == tagId)
                            {
                                Tags.InsertLast(m_mapTags[j]);
                                break;
                            }
                        }
                    }
                }
            } catch {
                Name = json["Name"];
                Log::Warn("Error parsing infos for the map: "+ Name, true);
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["TrackID"] = TrackID;
                json["TrackUID"] = TrackUID;
                json["UserID"] = UserID;
                json["Username"] = Username;
                json["AuthorLogin"] = AuthorLogin;
                json["MapType"] = MapType;
                json["ExeBuild"] = ExeBuild;
                json["UploadedAt"] = UploadedAt;
                json["UpdatedAt"] = UpdatedAt;
                json["PlayedAt"] = PlayedAt;
                json["Name"] = Name;
                json["GbxMapName"] = GbxMapName;
                json["Comments"] = Comments;
                json["TitlePack"] = TitlePack;
                json["Unlisted"] = Unlisted;
                json["Mood"] = Mood;
                json["DisplayCost"] = DisplayCost;
                json["LengthName"] = LengthName;
                json["Laps"] = Laps;
                json["DifficultyName"] = DifficultyName;
                json["VehicleName"] = VehicleName;
                json["AuthorTime"] = AuthorTime;
                json["TrackValue"] = TrackValue;
                json["AwardCount"] = AwardCount;
                json["ImageCount"] = ImageCount;
                json["IsMP4"] = IsMP4;

                string tagsStr = "";
                for (uint i = 0; i < Tags.get_Length(); i++)
                {
                    tagsStr += tostring(Tags[i].ID);
                    if (i < Tags.get_Length() - 1) tagsStr += ",";
                }
                json["Tags"] = tagsStr;
            } catch {
                Log::Error("Error converting map info to JSON for map "+Name, true);
            }
            return json;
        }
    }
}