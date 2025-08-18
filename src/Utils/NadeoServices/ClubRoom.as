namespace NadeoServices {
    class ClubRoom {
        int id;
        int clubId;
        string clubName;
        bool nadeo;
        int roomId;
        int campaignId;
        string playerServerLogin;
        int activityId;
        string mediaUrl;
        string name;
        ClubRoomInfo@ room;
        int popularityLevel;
        uint creationTimestamp;
        bool password;

        ClubRoom(const Json::Value &in json) {
            try {
                id = json["id"];
                clubId = json["clubId"];
                clubName = json["clubName"];
                nadeo = json["nadeo"];
                roomId = json["roomId"];
                if (json["campaignId"].GetType() != Json::Type::Null) campaignId = json["campaignId"];
                if (json["playerServerLogin"].GetType() != Json::Type::Null) playerServerLogin = json["playerServerLogin"];
                activityId = json["activityId"];
                mediaUrl = json["mediaUrl"];
                name = json["name"];
                @room = ClubRoomInfo(json["room"]);
                popularityLevel = json["popularityLevel"];
                creationTimestamp = json["creationTimestamp"];
                password = json["password"];
            } catch {
                Log::Warn("Failed to parse Club Room " + id + " - " + getExceptionInfo());
            }
        }
    }

    class ClubRoomInfo {
        int id;
        string name;
        string region;
        string serverAccountId;
        int maxPlayers;
        int playerCount;
        array<string> maps;
        string script;
        bool scalable;

        // Script settings
        string timeLimit;
        string joinLink;
        string currentMapUid;
        bool starting;
        bool isOff;

        ClubRoomInfo(const Json::Value &in json) {
            try {
                id = json["id"];
                name = json["name"];
                region = json["region"];
                serverAccountId = json["serverAccountId"];
                maxPlayers = json["maxPlayers"];
                playerCount = json["playerCount"];
                script = json["script"];
                scalable = json["scalable"];

                if (json["scriptSettings"].HasKey("S_TimeLimit")) timeLimit = json["scriptSettings"]["S_TimeLimit"]["value"];

                if (json["serverInfo"].GetType() != Json::Type::Null) {
                    joinLink = json["serverInfo"]["joinLink"];
                    currentMapUid = json["serverInfo"]["currentMapUid"];
                    starting = json["serverInfo"]["starting"];
                    isOff = false;
                } else {
                    isOff = true;
                }

                for (uint i = 0; i < json["maps"].Length; i++) {
                    maps.InsertLast(json["maps"][i]);
                }
            } catch {
                Log::Warn("Failed to parse Club Room Info " + id + " - " + getExceptionInfo());
            }
        }
    }
}