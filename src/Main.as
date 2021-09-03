bool RandomMapProcess = false;
bool isSearching = false;

bool menu_visibility = false;

Json::Value RecentlyPlayedMaps;

int64 QueueTimeStart;

void RenderMenu()
{
    if(UI::MenuItem(MXColor + Icons::Random + " \\$z"+shortMXName+" Randomizer", "", menu_visibility)) {
		menu_visibility = !menu_visibility;	
	}
}

void Main()
{
    RecentlyPlayedMaps = loadRecentlyPlayed();
    while (true){
        yield();
        if (RandomMapProcess && isSearching)
        {
            RandomMapProcess = false;

            string waitTxt = "Looking for a map that matches your settings...";
#if MP4
            waitTxt += "\n\nOn Maniaplanet, it can take a very long time (because it needs more verification)\nSo sit back and let it happen!";
#endif
            UI::ShowNotification(Icons::Kenney::Reload + " Please Wait", waitTxt, 10000);
            string tmxTitlePack = "";
            string savedMPTitlePack = getTitlePack(true);
            int requestsNb = 1;
            Json::Value mapRes;
            if (isTitePackLoaded()) {
                log("Starting looking for a random map - request #" + requestsNb);
                mapRes = GetRandomMap();
                while (!isMapSettingsCompatible(mapRes)) {
                    yield();
                    // On MP4, it can happens that the user changes the title pack while the request is running
                    if (savedMPTitlePack != getTitlePack(true) || !isSearching) {
                        break;
                    }
                    requestsNb++;
                    log("Starting looking for a random map - request #" + requestsNb);
                    mapRes = GetRandomMap();
                }
                if (isSearching && savedMPTitlePack == getTitlePack(true)) {
                    isSearching = false;
                    int mapId = mapRes["TrackID"];
                    string mapName = mapRes["Name"];
                    string mapAuthor = mapRes["Username"];
                    log("Track found: " + mapName + " - ID: " + mapId);
                    vec4 color = UI::HSV(0.25, 1, 0.7);
                    UI::ShowNotification(Icons::Check + " Map found!", mapName + "\nby: "+mapAuthor+"\n\n"+Icons::Download+"Downloading...", color, 5000);
                    CreatePlayedMapJson(mapRes);
                    DownloadAndLoadMap(mapId);
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