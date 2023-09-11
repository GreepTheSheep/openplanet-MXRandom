namespace MX
{
    void DownloadMap(const int &in mapId, string _fileName = "") {
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

            if (_fileName.Length > 0) _fileName = map.TrackID + " - " + map.Name;
            netMap.SaveToFile(mxDLFolder + "/" + _fileName + ".Map.Gbx");
            Log::Log("Map downloaded to " + mxDLFolder + "/" + _fileName + ".Map.Gbx");
        } catch {
            Log::Error("Error while downloading map");
        }
    }
}