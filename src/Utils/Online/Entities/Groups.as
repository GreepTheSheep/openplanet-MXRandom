namespace OnlineServices
{
    class Group
    {
        int Id;
        string Name;
        int isAdminGroup;

        Group(const Json::Value &in json)
        {
            try {
                Id = json["Id"];
                Name = json["name"];
                isAdminGroup = json["isAdminGroup"];
            } catch {
                Name = json["name"];
                Log::Warn("Error parsing infos for the group "+ Name, true);
            }
        }

        Json::Value ToJson()
        {
            Json::Value json = Json::Object();
            try {
                json["Id"] = Id;
                json["name"] = Name;
                json["isAdminGroup"] = isAdminGroup;
            } catch {
                Log::Warn("Error converting infos for the group "+ Name, true);
            }
            return json;
        }
    }
}