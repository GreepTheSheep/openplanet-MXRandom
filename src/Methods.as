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

// -----------MP4-----------

bool isTitePackLoaded()
{
    auto appMP = cast<CGameManiaPlanet>(GetApp());
    if (appMP.LoadedManiaTitle == null){
        return false;
    } else {
        return true;
    }
}

string getTitlePack(bool full = false)
{
    if (isTitePackLoaded()){
        auto appMP = cast<CGameManiaPlanet>(GetApp());
        if (full) return appMP.LoadedManiaTitle.TitleId;
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

bool isMapTitlePackCompatible(Json::Value MapMX)
{
    string tmxTitlePack = MapMX["TitlePack"];
    return getTitlePack() == tmxTitlePack;
}

bool isMapMP4Compatible(Json::Value MapMX)
{
    bool isMP4 = MapMX["IsMP4"];
    return isMP4;
}

// ------------Map compare-----------

bool isMapSettingsCompatible(Json::Value MapMX)
{
    bool length = isMapLengthCompatible(MapMX);
    if (!length) {
        log("Map length is not compatible.");
    };
#if MP4
    bool titlepack = isMapTitlePackCompatible(MapMX);
    if (!titlepack) {
        log("Titlepack is not compatible.");
    };

    bool mp4 = isMapMP4Compatible(MapMX);
    if (!mp4) {
        log("Map is not compatible with MP4.");
    };

    return length && titlepack && mp4;
#elif TMNEXT
    return length;
#endif
}

bool isMapLengthCompatible(Json::Value MapMX)
{
    string mapLength;
    switch (Setting_MapLength) {
        case MapLength::Anything :
            mapLength = "Anything";
            break;
        case MapLength::_15seconds :
            mapLength = "15 secs";
            break;
        case MapLength::_30seconds :
            mapLength = "30 secs";
            break;
        case MapLength::_45seconds :
            mapLength = "45 secs";
            break;
        case MapLength::_1minutes :
            mapLength = "1 min";
            break;
        case MapLength::_1minutes_15seconds :
            mapLength = "1 m 15 s";
            break;
        case MapLength::_1minutes_30seconds :
            mapLength = "1 m 30 s";
            break;
        case MapLength::_1minutes_45seconds :
            mapLength = "1 m 45 s";
            break;
        case MapLength::_2minutes :
            mapLength = "2 min";
            break;
        case MapLength::_2minutes_30seconds :
            mapLength = "2 m 30 s";
            break;
        case MapLength::_3minutes :
            mapLength = "3 min";
            break;
        case MapLength::_3minutes_30seconds :
            mapLength = "3 m 30 s";
            break;
        case MapLength::_4minutes :
            mapLength = "4 min";
            break;
        case MapLength::_4minutes_30seconds :
            mapLength = "4 m 30 s";
            break;
        case MapLength::_5minutes :
            mapLength = "5 min";
            break;
        case MapLength::Long :
            mapLength = "Long";
            break;
    }
    string tmxLength = MapMX["LengthName"];
    if (mapLength == "Anything") return true;
    else return mapLength == tmxLength;
}

// ------------NET--------------

Json::Value GetRandomMap() {
    Net::HttpRequest req;
    req.Method = Net::HttpMethod::Get;
    req.Url = "https://"+TMXURL+"/mapsearch2/search?api=on&random=1";
    dictionary@ Headers = dictionary();
    Headers["Accept"] = "application/json";
    Headers["Content-Type"] = "application/json";
    req.Body = "";
    req.Start();
    while (!req.Finished()) {
        yield();
    }
    Json::Value json = ResponseToJSON(req.String());
    return json["results"][0];
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
		UI::ShowNotification("\\$afa" + Icons::Bullhorn + " Thanks for installing "+name+"!","No data file was detected, that means it's your first install. Welcome!", 15000);
        saveRecentlyPlayed(Json::Array());
        return Json::Array();
    } else if (FileData.GetType() != Json::Type::Array) {
        error("The data file seems to yield invalid data. If it persists, consider deleting the file " + RecentlyPlayedJSON, "(is not of the correct JSON type.) Data file: " + RecentlyPlayedJSON);
        return Json::Array();
    } else return FileData;
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

void CreatePlayedMapJson(Json::Value mapData) {
    int mxMapId = mapData["TrackID"];
    string mapName = mapData["Name"];
    string mapAuthor = mapData["Username"];
    string mapUid = mapData["TrackUID"];
    string playedAt = Time::FormatString("%F %r");

    Json::Value mapJson = Json::Object();
    mapJson["MXID"] = mxMapId;
    mapJson["name"] = mapName;
    mapJson["author"] = mapAuthor;
    mapJson["UID"] = mapUid;
    mapJson["playedAt"] = playedAt;

    addToRecentlyPlayed(mapJson);
}