// ---------Openplanet utilities--------
int OpenplanetVersionInt(){
    return Text::ParseInt(Meta::OpenplanetVersion().Replace(".", ""));
}

int PluginVersionInt(){
    return Text::ParseInt(Meta::ExecutingPlugin().get_Version().Replace(".", ""));
}

int VersionToInt(string version){
    return Text::ParseInt(version.Replace(".", ""));
}

bool isDevMode(){
    return Meta::ExecutingPlugin().get_Type() == Meta::PluginType::Folder;
}

// -----------Logging-----------

void log(string msg)
{
    print("\\$z[" + MXColor + name + "\\$z] " + msg);
}

void error(string msg, string log = "")
{
    vec4 color = UI::HSV(0.0, 0.5, 1.0);
    UI::ShowNotification(Icons::Kenney::ButtonTimes + " " + name + " - Error", msg, color, 5000);
    print("\\$z[\\$f00Error: " + name + "\\$z] " + msg);
    if (log != "")
    {
        print("\\$z[\\$f00Error: " + name + "\\$z] " + log);
    }
}

// ----------- Utility -----------

string changeEnumStyle(string enumName){
#if MP4
    string str = enumName.SubStr(enumName.IndexOf(":") + 2);
#elif TMNEXT
    string str = enumName.SubStr(enumName.IndexOf(":") + 1);
#endif
    //replace "_" with " "
    str = str.Replace("_", " ");
    return str;
}

// -----------Map download-----------

void DownloadAndLoadMap(int mapId)
{
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    app.BackToMainMenu(); // If we're on a map, go back to the main menu else we'll get stuck on the current map
    while(!app.ManiaTitleControlScriptAPI.IsReady) {
        yield(); // Wait until the ManiaTitleControlScriptAPI is ready for loading the next map
    }
    app.ManiaTitleControlScriptAPI.PlayMap("https://"+TMXURL+"/maps/download/"+mapId, "", "");
}

bool IsMapLoaded(){
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app.RootMap is null) return false;
    else return true;
}

// -----------MP4-----------

bool isTitePackLoaded()
{
    auto appMP = cast<CGameManiaPlanet>(GetApp());
    if (appMP.LoadedManiaTitle is null){
        return false;
    } else {
        return true;
    }
}

string getTitlePack(bool full = false)
{
    if (isTitePackLoaded()){
        auto appMP = cast<CGameManiaPlanet>(GetApp());
        if (full) return appMP.LoadedManiaTitle.TitleId.SubStr(0, appMP.LoadedManiaTitle.TitleId.IndexOf("@"));
        else return appMP.LoadedManiaTitle.BaseTitleId;
    } else {
        return "";
    }
}

void sendNoTitlePackError()
{
    vec4 color = UI::HSV(0.0, 0.5, 1.0);
    UI::ShowNotification(Icons::Times + " " + name + " - No titlepack loaded", "Please enter in a titlepack before trying to load a map.", color, 5000);
}

bool isMapTitlePackCompatible(string titlepack)
{
    return getTitlePack() == titlepack;
}

bool isMapMP4Compatible(Json::Value MapMX)
{
    bool isMP4 = MapMX["IsMP4"];
    return isMP4;
}

// ------------ Game utilities -----------

void ClosePauseMenu() {		
	CTrackMania@ app = cast<CTrackMania>(GetApp());		
	if(app.ManiaPlanetScriptAPI.ActiveContext_InGameMenuDisplayed) {
		CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
		if(playground !is null) {
			playground.Interface.ManialinkScriptHandler.CloseInGameMenu(CGameScriptHandlerPlaygroundInterface::EInGameMenuResult::Resume);
		}
	}
}

int GetCurrentMapMedal(){
    auto app = cast<CTrackMania>(GetApp());
    auto map = app.RootMap;
    CGamePlayground@ GamePlayground = cast<CGamePlayground>(app.CurrentPlayground);
    int medal = 0;
    if (map !is null && GamePlayground !is null){
        int authorTime = map.TMObjective_AuthorTime;
        int goldTime = map.TMObjective_GoldTime;
        int silverTime = map.TMObjective_SilverTime;
        int bronzeTime = map.TMObjective_BronzeTime;
        int time = -1;

#if MP4
        CGameCtnPlayground@ GameCtnPlayground = cast<CGameCtnPlayground>(app.CurrentPlayground);
        if (GameCtnPlayground.PlayerRecordedGhost !is null){
            time = GameCtnPlayground.PlayerRecordedGhost.RaceTime;
        } else time = -1;
#elif TMNEXT
        CSmArenaRulesMode@ PlaygroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);
        if (PlaygroundScript !is null && GamePlayground.GameTerminals.get_Length() > 0) {
            CSmPlayer@ player = cast<CSmPlayer>(GamePlayground.GameTerminals[0].ControlledPlayer);
            if (GamePlayground.GameTerminals[0].UISequence_Current == CGameTerminal::ESGamePlaygroundUIConfig__EUISequence::Finish && player !is null) {
                auto ghost = PlaygroundScript.Ghost_RetrieveFromPlayer(player.ScriptAPI);
                if (ghost !is null) {
                    if (ghost.Result.Time > 0 && ghost.Result.Time < 4294967295) time = ghost.Result.Time;
                    PlaygroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                } else time = -1;
            } else time = -1;
        } else time = -1;
#endif
        medal = 0;
        if (time != -1){
            if(time <= authorTime) medal = 4;
            else if(time <= goldTime) medal = 3;
            else if(time <= silverTime) medal = 2;
            else if(time <= bronzeTime) medal = 1;
            else medal = 0;
        }
    }
    return medal;
}

// ------------NET--------------

Json::Value GetRandomMap() {
    Net::HttpRequest req;
    req.Method = Net::HttpMethod::Get;
    req.Url = "https://"+TMXURL+"/mapsearch2/search?api=on&random=1";

    if (RMCStarted){
        req.Url += "&etags=23%2C37";
        req.Url += "&lengthop=1";
        req.Url += "&length=9";
#if TMNEXT
        // prevent loading shootmania maps
        req.Url += "&vehicles=1";
#endif
    } else {
        req.Url += "&etags=37";
        if (Setting_MapLengthOperator != MapLengthOp::Equals){
            req.Url += "&lengthop=" + Setting_MapLengthOperator;
        }
        if (Setting_MapLength != MapLength::Anything){
            req.Url += "&length=" + Setting_MapLength;
        }
        if (Setting_MapType != MapType::Anything){
            req.Url += "&style=" + Setting_MapType;
        }
    }
    
#if MP4
    req.Url += "&tpack=" + getTitlePack(true) + "&gv=1";
#endif
    log("Request URL: " + req.Url);
    dictionary@ Headers = dictionary();
    Headers["Accept"] = "application/json";
    Headers["Content-Type"] = "application/json";
    req.Body = "";
    Json::Type returnedType = Json::Type::Null;
    Json::Value json;
    string mapType = "";
    while (returnedType != Json::Type::Object ||
#if MP4
    mapType != "Race"
#elif TMNEXT
    mapType != "TM_Race"
#endif
    ) {
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        json = ResponseToJSON(req.String());
        returnedType = json.GetType();
        if (returnedType != Json::Type::Object) error("Warn: returned JSON is not valid, retrying", "Returned type is " + changeEnumStyle(tostring(returnedType)));
        else mapType = json["results"][0]["MapType"];
    }
    return json["results"][0];
}

Json::Value GetMap(int mapId) {
    Net::HttpRequest req;
    req.Method = Net::HttpMethod::Get;
    req.Url = "https://"+TMXURL+"/api/maps/get_map_info/multi/"+tostring(mapId);
    dictionary@ Headers = dictionary();
    Headers["Accept"] = "application/json";
    Headers["Content-Type"] = "application/json";
    req.Body = "";
    Json::Type returnedType = Json::Type::Null;
    Json::Value json;
    while (returnedType != Json::Type::Array) {
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        json = ResponseToJSON(req.String());
        returnedType = json.GetType();
        if (returnedType != Json::Type::Array) error("Warn: returned JSON is not valid, retrying", "Returned type is " + changeEnumStyle(tostring(returnedType)));
    }
    if (json.get_Length() < 1) return json;
    else return json[0];
}

Json::Value GetInfoAPI(){
    Net::HttpRequest req;
    req.Method = Net::HttpMethod::Get;
    req.Url = Setting_API_URL;
    dictionary@ Headers = dictionary();
    Headers["Accept"] = "application/json";
    Headers["Content-Type"] = "application/json";
    req.Body = "";
    Json::Type returnedType = Json::Type::Null;
    Json::Value json;
    while (returnedType != Json::Type::Object) {
        req.Start();
        while (!req.Finished()) {
            yield();
        }
        json = ResponseToJSON(req.String());
        returnedType = json.GetType();
    }
    return json;
}

bool IsPluginInfoAPILoaded(){
    return PluginInfoNet.GetType() == Json::Type::Object;
}

Json::Value ResponseToJSON(const string &in HTTPResponse) {
    Json::Value ReturnedObject;
    try {
        ReturnedObject = Json::Parse(HTTPResponse);
    } catch {
        error("JSON Parsing of string failed!", HTTPResponse);
    }
    return ReturnedObject;
}


// --- Sounds (Thanks Nsgr) ---

void PlaySound(string FileName = "Race3.wav", float Volume = 1, float Pitch = 1) {
    auto audioPort = GetApp().AudioPort;
    for (uint i = 0; i < audioPort.Sources.Length; i++) {
        auto source = audioPort.Sources[i];
        auto sound = source.PlugSound;
        if (cast<CSystemFidFile>(GetFidFromNod(sound.PlugFile)).FileName == FileName) {
            source.Stop();
            // Yield twice : Later while loop will be exited by already playing sounds
            // Their coroutines will end and the pitch and volume will be set to the correct values
            yield();yield();
            float PrevPitch = sound.Pitch;
            float PrevSoundVol = sound.VolumedB;
            float PrevSourceVol = source.VolumedB;
            if (FileName == "Race3.wav") {
                sound.Pitch = 1.5;
            } else {
                sound.Pitch = Pitch;
            }
            sound.VolumedB = Volume;
            source.VolumedB = Volume;
            source.Play();
            while (source.IsPlaying) {
                yield();
            }
            sound.Pitch = PrevPitch;
            sound.VolumedB = PrevSoundVol;
            source.VolumedB = PrevSourceVol;
            return;
        }
    }
    error("Couldn't find sound to play!", "Filename: " + FileName);

    // Backup sound: "Race3.wav"
    for (uint i = 0; i < audioPort.Sources.Length; i++) {
        auto source = audioPort.Sources[i];
        auto sound = source.PlugSound;
        if (cast<CSystemFidFile>(GetFidFromNod(sound.PlugFile)).FileName == "Race3.wav") {
            source.Stop();
            // Yield twice : Later while loop will be exited by already playing sounds, ending their coroutines
            yield();yield();
            float PrevPitch = sound.Pitch;
            float PrevSoundVol = sound.VolumedB;
            float PrevSourceVol = source.VolumedB;
            sound.Pitch = 1.5;
            source.VolumedB = Volume;
            source.Play();
            while (source.IsPlaying) {
                yield();
            }
            sound.Pitch = PrevPitch;
            sound.VolumedB = PrevSoundVol;
            source.VolumedB = PrevSourceVol;
            return;
        }
    }
    error("Couldn't find backup Race3.wav", "Sources: " + audioPort.Sources.Length);
}

// ---------- JSON (Recently played maps) ----------

Json::Value loadRecentlyPlayed() {
    Json::Value FileData = Json::FromFile(RecentlyPlayedJSON);
    if (FileData.GetType() == Json::Type::Null) {
		UI::ShowNotification("\\$afa" + Icons::InfoCircle + " Thanks for installing "+name+"!","No data file was detected, that means it's your first install. Welcome!", 15000);
        saveRecentlyPlayed(Json::Array());
        return Json::Array();
    } else if (FileData.GetType() != Json::Type::Array) {
        error("The data file seems to yield invalid data. If it persists, consider deleting the file " + RecentlyPlayedJSON, "(is not of the correct JSON type.) Data type: " + changeEnumStyle(tostring(FileData.GetType())));
        return Json::Array();
    } else {
        if (FileData.get_Length() > 0) {
            if (FileData[0].GetType() != Json::Type::Object) {
                error("The data file seems to yield invalid data. If it persists, consider deleting the file " + RecentlyPlayedJSON, "(is not of the correct JSON type.) Data type: " + changeEnumStyle(tostring(FileData[0].GetType())));
                return Json::Array();
            }
            if (FileData[0]["awards"].GetType() != Json::Type::Number || FileData[0]["style"].GetType() != Json::Type::String) {
                error("The data file is outdated. It has been reseted.", "Awards or style is missing (JSON v1.1)");
                saveRecentlyPlayed(Json::Array());
                return Json::Array();
            }
            return FileData;
        } else return FileData;
    }
}

void saveRecentlyPlayed(Json::Value data) {
    Json::ToFile(RecentlyPlayedJSON, data);
}

void addToRecentlyPlayed(Json::Value data) {
    // Method: Creates a new Array to save first the new map, then the old ones.
    Json::Value arr = Json::Array();
    arr.Add(data);
    Json::Value FileData = loadRecentlyPlayed();
    if (FileData.get_Length() > 0) {
        for (uint i = 0; i < FileData.get_Length(); i++) {
            arr.Add(FileData[i]);
        }
    }
    saveRecentlyPlayed(arr);
}

Json::Value loadPluginData(){
    Json::Value FileData = Json::FromFile(PluginDataJSON);
    if (FileData.GetType() == Json::Type::Null) {
        Json::ToFile(PluginDataJSON, Json::Object());
        return Json::Object();
    } else if (FileData.GetType() != Json::Type::Object) {
        error("The data file seems to yield invalid data. If it persists, consider deleting the file " + PluginDataJSON, "(is not of the correct JSON type.) Data type: " + changeEnumStyle(tostring(FileData.GetType())));
        return Json::Object();
    } else {
        return FileData;
    }
}

void CreatePlayedMapJson(Json::Value mapData) {
    int mxMapId = mapData["TrackID"];
    string mapName = mapData["Name"];
    string mapAuthor = mapData["Username"];
    string mapUid = mapData["TrackUID"];
    string titlepack = mapData["TitlePack"];
    string style = "Unknown";
    if (mapData["StyleName"].GetType() == Json::Type::String) style = mapData["StyleName"];
    int awards = mapData["AwardCount"];

    Json::Value playedAt = Json::Object();
    Time::Info date = Time::Parse();
    playedAt["Year"] = date.Year;
    playedAt["Month"] = date.Month;
    playedAt["Day"] = date.Day;
    playedAt["Hour"] = date.Hour;
    playedAt["Minute"] = date.Minute;
    playedAt["Second"] = date.Second;

    Json::Value mapJson = Json::Object();
    mapJson["MXID"] = mxMapId;
    mapJson["name"] = mapName;
    mapJson["author"] = mapAuthor;
    mapJson["UID"] = mapUid;
    mapJson["titlepack"] = titlepack;
    mapJson["style"] = style;
    mapJson["awards"] = awards;
    mapJson["playedAt"] = playedAt;

    addToRecentlyPlayed(mapJson);
}
