namespace MX
{
    void DownloadMap(const int &in mapId, string fileName = "") {
        try {
            auto json = API::GetAsync(PluginSettings::RMC_MX_Url+"/api/maps/get_map_info/multi/"+mapId);
            if (json.Length == 0) {
                Log::Error("Track not found.", true);
                return;
            }
            MX::MapInfo@ map = MX::MapInfo(json[0]);

            string downloadedMapFolder = IO::FromUserGameFolder("Maps/Downloaded");
            string mxDLFolder = downloadedMapFolder;
            if (!IO::FolderExists(downloadedMapFolder)) IO::CreateFolder(downloadedMapFolder);
            if (!IO::FolderExists(mxDLFolder)) IO::CreateFolder(mxDLFolder);

            Net::HttpRequest@ netMap = API::Get(PluginSettings::RMC_MX_Url+"/maps/download/"+mapId);
            Log::Trace("Started downloading map "+map.Name+" ("+mapId+") to "+mxDLFolder);
            while(!netMap.Finished()) {
                yield();
            }

            if (fileName.Length > 0) fileName = map.TrackID + " - " + map.Name;
            netMap.SaveToFile(mxDLFolder + "/" + fileName + ".Map.Gbx");
            Log::Log("Map downloaded to " + mxDLFolder + "/" + fileName + ".Map.Gbx");
        } catch {
            Log::Error("Error while downloading map");
        }
    }
}