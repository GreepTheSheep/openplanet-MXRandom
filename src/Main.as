bool RandomMapProcess = false;
bool isSearching = false;

Json::Value RecentlyPlayedMaps;
Json::Value PluginInfoNet;
Json::Value PluginData;

int loadMapId = 0;
int loadMapIdWithJson = 0;
int keyCodes = 0;
int inputMapID;

void RenderMenu()
{
    if(UI::MenuItem(MXColor + Icons::Random + " \\$z"+shortMXName+" Randomizer", "", Setting_Window_Show)) {
		Setting_Window_Show = !Setting_Window_Show;
	}
    if(UI::MenuItem(MXColor + Icons::HourglassO + " \\$zRandom Map Challenge", "", Setting_RMC_DisplayTimer)) {
		Setting_RMC_DisplayTimer = !Setting_RMC_DisplayTimer;
	}
}

void Main()
{
    startnew(GetInfoAPILoop);
    PluginData = loadPluginData();
    startnew(SaveDataLoop);
    RecentlyPlayedMaps = loadRecentlyPlayed();
    while (true){
        yield();
        startnew(SearchCoroutine);
        startnew(TimerYield);
        if (loadMapId != 0) {
#if TMNEXT
            ClosePauseMenu();
#endif
            DownloadAndLoadMap(loadMapId);
            loadMapId = 0;
        }
        if (loadMapIdWithJson != 0) {
            Json::Value mapInfo = GetMap(loadMapIdWithJson);
            if (mapInfo.GetType() == Json::Type::Object) {
#if MP4
                if (mapInfo["TitlePack"] == getTitlePack()) {
#endif
                    CreatePlayedMapJson(mapInfo);
                    loadMapId = loadMapIdWithJson;
#if MP4
                } else customError("You can't play a map from a different titlepack", mapInfo["TitlePack"]);
#endif
            } else customError("Returned data is not valid", "Returned type is " + changeEnumStyle(tostring(mapInfo.GetType())));
            loadMapIdWithJson = 0;
        }
    }
}

void SearchCoroutine() {
    if (RandomMapProcess && isSearching) {
        RandomMapProcess = false;

        string savedMPTitlePack = getTitlePack(true);
        Json::Value mapRes;
        if (isTitePackLoaded()) {
            print("Starting looking for a random map");
            mapRes = GetRandomMap();
            if (mapRes.GetType() == Json::Type::Null){
                customError("Returned data is not valid, API must be down", "Returned type is null");
                isSearching = false;
                return;
            }
            if (isSearching && savedMPTitlePack == getTitlePack(true)) {
                isSearching = false;
                int mapId = mapRes["TrackID"];
                string mapName = mapRes["Name"];
                string mapAuthor = mapRes["Username"];
                print("Track found: " + mapName + " - ID: " + mapId);
                vec4 color = UI::HSV(0.25, 1, 0.7);
                UI::ShowNotification(Icons::Check + " Map found!", mapName + "\nby: "+mapAuthor+"\n\n"+Icons::Download+"Downloading...", color, 5000);
                CreatePlayedMapJson(mapRes);
                loadMapId = mapId;
                PlaySound();
            } else {
                if (savedMPTitlePack != getTitlePack(true)) customError("Titlepack changed, search has been canceled", "Old pack: " + savedMPTitlePack + " | New pack: " + getTitlePack(true));
            }
        }
    }
    if (RandomMapProcess && !isSearching)
    {
        RandomMapProcess = false;
        print("Stopped searching");
    }
}

void GetInfoAPILoop(){
    while (true) {
        if (Setting_API_Enable){
            print("Getting Plugin info from API...");
            PluginInfoNet = GetInfoAPI();
            string version = PluginInfoNet["version"];
            int announcementsLength = PluginInfoNet["announcements"].get_Length();
            print("Plugin info received, version: " + version + " | " + announcementsLength + " announcements");

            if (version != Meta::ExecutingPlugin().get_Version()) {
                print("Versions does not corresponds. Installed version: " + Meta::ExecutingPlugin().get_Version());
            }
            sleep(30 * 60 * 1000); // 30 minutes
        } else {
            // empty the variable by adding a empty array
            PluginInfoNet = Json::Array();
        }
        yield();
    }
}

void SaveDataLoop() {
    while (true) {
        if (isDevMode()) {
            yield();
        } else {
            sleep(10 * 60 * 1000); // 10 minutes
            print("Saving data");
        }
        Json::ToFile(PluginDataJSON, PluginData);
    }
}

void OnDestroyed() {
    Json::ToFile(PluginDataJSON, PluginData);
}