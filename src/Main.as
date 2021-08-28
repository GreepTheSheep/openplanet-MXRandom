bool RandomMapProcess = false;
bool isSearching = false;

void RenderMenu()
{
	if(UI::MenuItem(MXColor + Icons::Random + " \\$z"+shortMXName+" Random map", "", isSearching)) {
        if (!isTitePackLoaded()) sendNoTitlePackError();
        else
        {
#if TMNEXT
            if (!Permissions::PlayLocalMap())
            {
                vec4 color = UI::HSV(999, 1, 0.7);
                UI::ShowNotification(Icons::Times + " Missing permissions!", "You don't have permissions to play other maps than the official campaign.", color, 20000);
            } else {
#endif
                RandomMapProcess = true;
                isSearching = !isSearching;
#if TMNEXT
            }
#endif
        }
	}
}

void Main()
{
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
                    log("Track found: " + mapName + " - ID: " + mapId);
                    vec4 color = UI::HSV(999, 1, 0.7);
                    UI::ShowNotification(Icons::Check + " Map found!", mapName + "\n\n"+Icons::Download+"Downloading...", color, 5000);
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
            log("Stopped searching");
        }
    }
}