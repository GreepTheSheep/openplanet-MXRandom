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
        Net::HttpRequest@ req = NadeoServices::Get("NadeoLiveServices", NadeoServices::BaseURL()+"/api/token/club/"+PluginSettings::RMC_Together_ClubId+"/room/"+PluginSettings::RMC_Together_RoomId);
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        if (IS_DEV_MODE) Log::Trace("NadeoServices - Check server: " + req.String());
        auto res = Json::Parse(req.String());
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
            trace("UploadMapFromLocal: Map uploaded: " + AddMapToServer_MapUid);
        dfm.TaskResult_Release(regScript.Id);
        string downloadedMapFolder = IO::FromUserGameFolder("Maps/Downloaded");
        IO::Delete(downloadedMapFolder + "/" + AddMapToServer_MapUid + ".Map.Gbx");
    }
#endif
}