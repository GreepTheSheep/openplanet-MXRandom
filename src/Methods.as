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
#endif

    return length 
#if MP4
    && titlepack && mp4
#endif
    ;
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
    Headers["User-Agent"] = "Openplanet" /* add here OP version */ + " " + name + "/" + Meta::ExecutingPlugin().get_Version();
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

void PlaySound(
#if MP4
    string FileName = "Race3.wav",
#if TMNEXT
    string FileName = "MatchFound.wav",
#endif
    float Volume = 1,
    float Pitch = 1
    ) {
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

    // Backup sound: "ManiaPlanetZoomIn.wav"
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
    error("Couldn't find backup ManiaPlanetZoomIn.wav", "Sources: " + audioPort.Sources.Length);
}