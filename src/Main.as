bool RandomMapProcess = false;
bool isSearching = false;

Json::Value RecentlyPlayedMaps;

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
    startnew(SearchCoroutine);
    RecentlyPlayedMaps = loadRecentlyPlayed();
    while (true){
        yield();
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
                } else error("You can't play a map from a different titlepack", mapInfo["TitlePack"]);
#endif
            } else error("Returned data is not valid", "Returned type is " + changeEnumStyle(tostring(mapInfo.GetType())));
            loadMapIdWithJson = 0;
        }
    }
}

void SearchCoroutine() {
    while (true) {
        yield();
        if (RandomMapProcess && isSearching) {
            RandomMapProcess = false;

            string savedMPTitlePack = getTitlePack(true);
            Json::Value mapRes;
            if (isTitePackLoaded()) {
                log("Starting looking for a random map");
                mapRes = GetRandomMap();
                if (isSearching && savedMPTitlePack == getTitlePack(true)) {
                    isSearching = false;
                    int mapId = mapRes["TrackID"];
                    string mapName = mapRes["Name"];
                    string mapAuthor = mapRes["Username"];
                    log("Track found: " + mapName + " - ID: " + mapId);
                    vec4 color = UI::HSV(0.25, 1, 0.7);
                    UI::ShowNotification(Icons::Check + " Map found!", mapName + "\nby: "+mapAuthor+"\n\n"+Icons::Download+"Downloading...", color, 5000);
                    CreatePlayedMapJson(mapRes);
                    loadMapId = mapId;
                    PlaySound();
                } else {
                    if (savedMPTitlePack != getTitlePack(true)) error("Titlepack changed, search has been canceled", "Old pack: " + savedMPTitlePack + " | New pack: " + getTitlePack(true));
                }
            }
        }
        if (RandomMapProcess && !isSearching)
        {
            RandomMapProcess = false;
            RMCStarted = false;
            log("Stopped searching");
        }
    }
}

