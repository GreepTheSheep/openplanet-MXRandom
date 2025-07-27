namespace MXNadeoServicesGlobal
{
    bool APIDown = false;
    bool APIRefresh = false;
    bool isCheckingRoom = false;
    string roomCheckErrorCode = "";
    string roomCheckError = "";
    NadeoServices::ClubRoom@ foundRoom;
    string AddMapToServer_MapUid = "";
    int AddMapToServer_MapMXId;

#if DEPENDENCY_NADEOSERVICES
    void LoadNadeoLiveServices()
    {
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

    void CheckAuthentication()
    {
        NadeoServices::AddAudience("NadeoLiveServices");
        while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
            yield();
        }
        Log::Trace("NadeoLiveServices authenticated");
    }

    void CheckNadeoRoomAsync() {
        isCheckingRoom = true;
        roomCheckErrorCode = "";
        roomCheckError = "";
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", NadeoServices::BaseURLLive()+"/api/token/club/"+PluginSettings::RMC_Together_ClubId+"/room/"+PluginSettings::RMC_Together_RoomId);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        Log::Trace("NadeoServices - Check server: " + req.String());
        auto res = req.Json();
        isCheckingRoom = false;

        if (res.GetType() == Json::Type::Array) {
            roomCheckErrorCode = res[0];
            if (roomCheckErrorCode.Contains("notFound")) roomCheckError = "Room is not Found";
            else roomCheckError = "Unknown error";
            return;
        }

        if (res.GetType() == Json::Type::Object)
            @foundRoom = NadeoServices::ClubRoom(res);

        return;
    }

    void UploadMapToNadeoServices() {
        MX::DownloadMap(AddMapToServer_MapMXId, AddMapToServer_MapUid);
        auto app = cast<CGameManiaPlanet>(GetApp());
        auto cma = app.MenuManager.MenuCustom_CurrentManiaApp;
        auto dfm = cma.DataFileMgr;
        auto userId = cma.UserMgr.Users[0].Id;
        yield();
        auto regScript = dfm.Map_NadeoServices_Register(userId, AddMapToServer_MapUid);
        while (regScript.IsProcessing) yield();
        if (regScript.HasFailed)
            Log::Error("Uploading map failed: " + regScript.ErrorType + ", " + regScript.ErrorCode + ", " + regScript.ErrorDescription);
        else if (regScript.HasSucceeded)
            Log::Trace("UploadMapFromLocal: Map uploaded: " + AddMapToServer_MapUid);
        dfm.TaskResult_Release(regScript.Id);

        string mapLocation = IO::FromUserGameFolder("Maps/Downloaded") + "/" + AddMapToServer_MapUid + ".Map.Gbx";

        if (IO::FileExists(mapLocation)) {
            IO::Delete(mapLocation);
        }
    }

    bool CheckIfMapExistsAsync(const string &in mapUid)
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/map/"+mapUid;
        Log::Trace("NadeoServices - Check if map exists: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            if (res.GetType() == Json::Type::Array && res[0].GetType() == Json::Type::String) {
                string errorMsg = res[0];
                if (errorMsg.Contains("notFound")) return false;
            }
            Log::Error("NadeoServices - Error checking if map exists: " + req.String());
            return false;
        }

        try {
            string resMapUid = res["uid"];
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
        EditRoomPayloadSetTimeout(bodyJson, 1);
        RunClubRoomRequest(room, bodyJson, "ClubRoomSetMapAndSwitch");
    }

    void RunClubRoomRequest(const NadeoServices::ClubRoom@ &in room, Json::Value@ bodyJson, const string &in callingFuncName) {
        string url = NadeoServices::BaseURLLive()+"/api/token/club/"+room.clubId+"/room/"+room.activityId+"/edit";
        string body = Json::Write(bodyJson);
        Log::Trace("NadeoServices - "+callingFuncName+": " + url + " - " + body);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url, body);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = req.String();
        Log::Trace("NadeoServices - "+callingFuncName+"::Res: " + res);
    }

    void SetMapToClubRoomAsync(const NadeoServices::ClubRoom@ &in room, const string &in mapUID)
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/club/"+room.clubId+"/room/"+room.activityId+"/edit";
        Json::Value bodyJson = Json::Object();
        bodyJson["maps"] = Json::Array();
        bodyJson["maps"].Add(mapUID);
        string body = Json::Write(bodyJson);
        Log::Trace("NadeoServices - SetMapToClubRoom: " + url + " - " + body);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url, body);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = req.String();
        Log::Trace("NadeoServices - SetMapToClubRoom::Res: " + res);
    }

    void ClubRoomSwitchMapAsync(const NadeoServices::ClubRoom@ &in room)
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/club/"+room.clubId+"/room/"+room.activityId+"/edit";
        Json::Value bodyJson = Json::Object();

        Json::Value bodyJsonSettingTimeLimit = Json::Object();
        bodyJsonSettingTimeLimit["key"] = "S_TimeLimit";
        bodyJsonSettingTimeLimit["value"] = "1";
        bodyJsonSettingTimeLimit["type"] = "integer";

        Json::Value bodyJsonSettings = Json::Array();
        bodyJsonSettings.Add(bodyJsonSettingTimeLimit);

        bodyJson["settings"] = bodyJsonSettings;
        string body = Json::Write(bodyJson);

        Log::Trace("NadeoServices - ClubRoomSwitchMapAsync: " + url + " - " + body);
        Net::HttpRequest@ req = NadeoServices::Post("NadeoLiveServices", url, body);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        auto res = req.String();
        Log::Trace("NadeoServices - ClubRoomSwitchMapAsync::Res: " + res);
    }

    void ClubRoomSetCountdownTimer(const NadeoServices::ClubRoom@ &in room, const int &in timerSec)
    {
        string url = NadeoServices::BaseURLLive()+"/api/token/club/"+room.clubId+"/room/"+room.activityId+"/edit";
        Json::Value bodyJson = Json::Object();
        EditRoomPayloadSetTimeout(bodyJson, timerSec);
        RunClubRoomRequest(room, bodyJson, "ClubRoomSetCountdownTimer");
    }

    int GetMapWorldRecord(const string &in mapUid) {
        string url = NadeoServices::BaseURLLive()+"/api/token/leaderboard/group/Personal_Best/map/"+mapUid+"/top?length=1&onlyWorld=true&offset=0";
        Log::Trace("NadeoServices - Get Map WR: " + url);
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", url);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        Log::Trace("NadeoServices - Get Map WR Res: " + req.String());
        auto res = req.Json();

        if (res.GetType() != Json::Type::Object) {
            if (res.GetType() == Json::Type::Array && res[0].GetType() == Json::Type::String) {
                string errorMsg = res[0];
                if (errorMsg.Contains("notFound")) return -1;
            }
            Log::Error("NadeoServices - Error get map WR: " + req.String());
            return -1;
        }

        try {
            uint mapWR = res["tops"][0]["top"][0]["score"];
            string mapWRPlayer =  res["tops"][0]["top"][0]["accountId"];
            Log::Trace("NadeoServices - Map WR: " + mapWR + " by accountid " + mapWRPlayer);
            return mapWR;
        } catch {
            Log::Error("NadeoServices - Map WR failed: " + getExceptionInfo());
            return -1;
        }
    }
#endif
}
