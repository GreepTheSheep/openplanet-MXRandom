namespace DataManager
{
    void CheckData()
    {
        if (Versioning::IsPluginUpdated())
        {
            Log::Log("Plugin was updated, old version was "+ Json::Write(DataJson["version"]));
            if (!PluginSettings::dontShowChangeLog) Renderables::Add(ChangelogModalDialog());
            DataJson["version"] = PLUGIN_VERSION;
            // SaveData();
        }
    }

    void SaveData()
    {
        Json::ToFile(DATA_JSON_LOCATION, DataJson);
    }
}