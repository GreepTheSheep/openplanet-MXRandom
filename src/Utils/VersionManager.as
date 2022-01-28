namespace Versioning
{
    int VersionToInt(string version){
        return Text::ParseInt(version.Replace(".", ""));
    }

    bool IsPluginUpdated(){
        return Text::ParseInt(PLUGIN_VERSION.Replace(".", "")) > VersionToInt(DataJson["version"]);
    }

    bool IsVersion1(string version){
        int majorVersionProvided = Text::ParseInt(version.Split('.')[0]);
        return majorVersionProvided == 1;
    }
}