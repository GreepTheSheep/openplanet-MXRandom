bool RandomMapProcess = false;
bool isSearching = false;

bool menu_visibility = false;

Json::Value RecentlyPlayedMaps;

int loadMapId = 0;

void RenderMenu()
{
    if(UI::MenuItem(MXColor + Icons::Random + " \\$z"+shortMXName+" Randomizer", "", menu_visibility)) {
		menu_visibility = !menu_visibility;	
	}
    if(UI::MenuItem(MXColor + Icons::ExternalLink + " \\$zRandom Map Challenge")) {
		OpenBrowserURL("https://flinkblog.de/RMC/");
	}
}

void Main()
{
    startnew(SearchCoroutine);
    RecentlyPlayedMaps = loadRecentlyPlayed();
    while (true){
        yield();
        if (loadMapId != 0) {
            DownloadAndLoadMap(loadMapId);
            loadMapId = 0;
        }
        
    }
}

void SearchCoroutine() {
    while (true) {
        yield();
        if (RandomMapProcess && isSearching) {
            RandomMapProcess = false;

            UI::ShowNotification(Icons::Kenney::Reload + " Please Wait", "Looking for a map that matches your settings...");
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
            UI::ShowNotification(Icons::Check + " Stopped searching", "You have canceled the search");
            log("Stopped searching");
        }
    }
}