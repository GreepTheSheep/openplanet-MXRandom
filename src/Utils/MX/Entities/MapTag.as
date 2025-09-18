namespace MX {
    class MapTag {
        int ID;
        string Name;
        string Color;

        MapTag(const Json::Value &in json) {
            try {
                ID = json["ID"];
                Name = json["Name"];
                Color = json["Color"];
            } catch {
                Name = json["Name"];
                Log::Warn("[MX::MapTag] Error parsing tag: " + Name);
            }
        }

        Json::Value ToJson() {
            Json::Value json = Json::Object();
            try {
                json["TagId"] = ID;
                json["Name"] = Name;
                json["Color"] = Color;
            } catch {
                Log::Warn("[MX::MapTag] Error converting tag info to json for tag " + Name);
            }

            return json;
        }
    }
}