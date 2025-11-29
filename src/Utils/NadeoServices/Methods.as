namespace MXNadeoServicesGlobal {
    bool APIDown = false;
    bool APIRefresh = false;
    bool isCheckingRoom = false;
    bool joiningRoom = false;
    NadeoServices::ClubRoom@ foundRoom;
    array<string> uploadedMaps;

#if DEPENDENCY_NADEOSERVICES
    void LoadNadeoLiveServices() {
        try {
            APIRefresh = true;

            CheckAuthentication();

            APIRefresh = false;
            APIDown = false;
        } catch {
            Log::Error("Failed to load NadeoLiveServices");
            APIDown = true;
        }
    }

    void CheckAuthentication() {
        NadeoServices::AddAudience("NadeoLiveServices");
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }
        Log::Trace("NadeoLiveServices authenticated");
    }

    void CheckNadeoRoomAsync() {
        isCheckingRoom = true;
        Log::Trace("[CheckNadeoRoom] Checking room ID " + PluginSettings::RMC_Together_RoomId + " from club ID " + PluginSettings::RMC_Together_ClubId);

        string reqUrl = NadeoServices::BaseURLLive() + "/api/token/club/" + PluginSettings::RMC_Together_ClubId + "/room/" + PluginSettings::RMC_Together_RoomId;
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", reqUrl);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        Log::Trace("[CheckNadeoRoom] Response: " + req.String());
        auto res = req.Json();
        isCheckingRoom = false;

        if (res.GetType() == Json::Type::Array) {
            string errorMessage = res[0];

            if (errorMessage.Contains("notFound")) {
                Log::Error("Failed to find club / room with the provided IDs", true);
            } else {
                Log::Error("Unknown error while checking club room: " + errorMessage, true);
            }

            return;
        }

        if (res.GetType() == Json::Type::Object) {
            @foundRoom = NadeoServices::ClubRoom(res);
            Log::Trace("[CheckNadeoRoom] Found room \"" + foundRoom.room.name + "\" (ID " + foundRoom.roomId + ") in club \"" + foundRoom.clubName + "\" (ID " + foundRoom.clubId + ")");
        }
    }

    bool CheckIfMapExistsAsync(const string &in mapUid) {
        if (uploadedMaps.Find(mapUid) != -1) {
            return true;
        }

        string url = NadeoServices::BaseURLLive() + "/api/token/map/" + mapUid;

        Log::Trace("[CheckIfMapExists] URL: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        auto res = req.Json();

        if (req.ResponseCode() >= 400 || res.GetType() != Json::Type::Object || !res.HasKey("uid")) {
            if (res.GetType() == Json::Type::Array && res[0].GetType() == Json::Type::String) {
                string errorMsg = res[0];

                if (errorMsg == "NotFoundHttpException" || errorMsg.Contains("notFound")) {
                    return false;
                }
            }

            Log::Error("[CheckIfMapExists] Error checking if map exists: " + req.String());
            return false;
        }

        try {
            string resMapUid = res["uid"];

            if (resMapUid == mapUid) {
                Log::Trace("[CheckIfMapExists] Map \"" + mapUid + "\" exists in Nadeo servers.");
                uploadedMaps.InsertLast(mapUid);
            } else {
                Log::Trace("[CheckIfMapExists] Map \"" + mapUid + "\" doesn't exist in Nadeo servers.");
            }

            return resMapUid == mapUid;
        } catch {
            return false;
        }
    }

    void EditRoomPayloadSetMaps(Json::Value@ data, string[]@ maps) {
        data["maps"] = Json::Array();
        for (uint i = 0; i < maps.Length; i++) {
            data["maps"].Add(maps[i]);
        }
    }

    void EditRoomPayloadSetTimeout(Json::Value@ data, int timeout) {
        if (!data.HasKey("settings")) {
            data["settings"] = Json::Array();
        }

        auto timeoutSetting = Json::Parse('{"key": "S_TimeLimit", "type": "integer", "value": "1"}');
        timeoutSetting["value"] = tostring(timeout);
        data["settings"].Add(timeoutSetting);
    }

    void ClubRoomSetMapAndSwitchAsync(const NadeoServices::ClubRoom@ &in room, const string &in mapUID) {
        Json::Value bodyJson = Json::Object();
        EditRoomPayloadSetMaps(bodyJson, {mapUID});
        EditRoomPayloadSetTimeout(bodyJson, 5);
        RunClubRoomRequest(room, bodyJson, "ClubRoomSetMapAndSwitch");
    }

    void RunClubRoomRequest(const NadeoServices::ClubRoom@ &in room, Json::Value@ bodyJson, const string &in callingFuncName) {
        string url = NadeoServices::BaseURLLive() + "/api/token/club/" + room.clubId + "/room/" + room.activityId + "/edit";
        string body = Json::Write(bodyJson);

        Log::Trace("NadeoServices - " + callingFuncName + ": " + url + " - " + body);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url, body);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        auto res = req.String();
        Log::Trace("NadeoServices - " + callingFuncName + ": Response: " + res);
    }

    void SetMapToClubRoomAsync(const NadeoServices::ClubRoom@ &in room, const string &in mapUID) {
        string url = NadeoServices::BaseURLLive() + "/api/token/club/" + room.clubId + "/room/" + room.activityId + "/edit";

        Json::Value bodyJson = Json::Object();
        bodyJson["maps"] = Json::Array();
        bodyJson["maps"].Add(mapUID);
        string body = Json::Write(bodyJson);

        Log::Trace("[SetMapToClubRoom]: " + url + " - " + body);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url, body);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        auto res = req.String();
        Log::Trace("[SetMapToClubRoom] Response: " + res);
    }

    void ClubRoomSwitchMapAsync(const NadeoServices::ClubRoom@ &in room) {
        string url = NadeoServices::BaseURLLive() + "/api/token/club/" + room.clubId + "/room/" + room.activityId + "/edit";
        Json::Value bodyJson = Json::Object();

        Json::Value bodyJsonSettingTimeLimit = Json::Object();
        bodyJsonSettingTimeLimit["key"] = "S_TimeLimit";
        bodyJsonSettingTimeLimit["value"] = "1";
        bodyJsonSettingTimeLimit["type"] = "integer";

        Json::Value bodyJsonSettings = Json::Array();
        bodyJsonSettings.Add(bodyJsonSettingTimeLimit);

        bodyJson["settings"] = bodyJsonSettings;
        string body = Json::Write(bodyJson);

        Log::Trace("[ClubRoomSwitchMapAsync]: " + url + " - " + body);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url, body);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        auto res = req.String();
        Log::Trace("[ClubRoomSwitchMapAsync] Response: " + res);
    }

    void ClubRoomSetCountdownTimer(const NadeoServices::ClubRoom@ &in room, const int &in timerSec) {
        Json::Value bodyJson = Json::Object();
        EditRoomPayloadSetTimeout(bodyJson, timerSec);
        RunClubRoomRequest(room, bodyJson, "ClubRoomSetCountdownTimer");
    }

    int GetMapWorldRecord(const string &in mapUid) {
        int worldRecord = TM::GetWorldRecordFromCache(mapUid);

        if (worldRecord > -1) {
            return worldRecord;
        }

        string url = NadeoServices::BaseURLLive() + "/api/token/leaderboard/group/Personal_Best/map/" + mapUid + "/top?length=1&onlyWorld=true&offset=0";

        Log::Trace("[GetMapWorldRecord] URL: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();

        while (!req.Finished()) {
            yield();
        }

        Log::Trace("[GetMapWorldRecord] Response: " + req.String());
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            if (res.GetType() == Json::Type::Array && res[0].GetType() == Json::Type::String) {
                string errorMsg = res[0];
                if (errorMsg.Contains("notFound")) return -1;
            }
            Log::Error("[GetMapWorldRecord] Error when getting WR: " + req.String());
            return -1;
        }

        try {
            uint mapWR = res["tops"][0]["top"][0]["score"];
            string mapWRPlayer =  res["tops"][0]["top"][0]["accountId"];

            Log::Trace("[GetMapWorldRecord] Found WR - Time: " + mapWR + " by accountid " + mapWRPlayer);
            return mapWR;
        } catch {
            Log::Error("[GetMapWorldRecord] Failed to get map WR: " + getExceptionInfo());
            return -1;
        }
    }
#endif

    bool get_IsJoiningRoom() {
        return joiningRoom;
    }

#if DEPENDENCY_BETTERROOMMANAGER
    void AutoDetectRoom() {
        isCheckingRoom = true;
        Log::Trace("[AutoDetectRoom] Detecting current room.");

        auto cs = BRM::GetCurrentServerInfo(GetApp());

        if (cs is null) {
            Log::Error("Couldn't get current server info", true);
            return;
        }
        
        if (cs.clubId <= 0) {
            Log::Error("Could not detect club ID for current server (" + cs.name + " / " + cs.login + ")", true);
            return;
        }

        Log::Trace("[AutoDetectRoom] Current room's club ID: " + cs.clubId);

        auto myClubs = BRM::GetMyClubs();
        const Json::Value@ foundClub = null;

        for (uint i = 0; i < myClubs.Length; i++) {
            if (cs.clubId == int(myClubs[i]['id'])) {
                @foundClub = myClubs[i];
                break;
            }
        }

        if (foundClub is null) {
            Log::Error("Club not found in your list of clubs (refresh from Better Room Manager if you joined the club recently).", true);
            return;
        }

        if (cs.roomId <= 0) {
            Log::Error("[AutoDetectRoom] Room ID is invalid", true);
            return;
        }

        if (!bool(foundClub['isAnyAdmin'])) {
            Log::Error("Club was found but your role isn't enough to edit rooms (refresh from Better Room Manager if this changed recently).", true);
            return;
        }

        Log::Trace("[AutoDetectRoom] Found current room information. Club ID: " + cs.clubId + ", Room ID: " + cs.roomId);

        PluginSettings::RMC_Together_ClubId = cs.clubId;
        PluginSettings::RMC_Together_RoomId = cs.roomId;

        CheckNadeoRoomAsync();
        isCheckingRoom = false;
    }

    void JoinRMTRoom() {
        if (PluginSettings::RMC_Together_ClubId <= 0 || PluginSettings::RMC_Together_RoomId <= 0) {
            Log::Error("Invalid club or room ID when trying to join RMT server", true);
            return;
        }

        Log::Trace("Joining room with ID " + PluginSettings::RMC_Together_RoomId + " from club ID " + PluginSettings::RMC_Together_ClubId);
        joiningRoom = true;

        try {
            BRM::JoinServer(PluginSettings::RMC_Together_ClubId, PluginSettings::RMC_Together_RoomId);
        } catch {
            Log::Warn("Failed to join RMT room: " + getExceptionInfo(), true);
        }

        joiningRoom = false;
    }
#endif
}
