namespace Versioning
{
    int VersionToInt(const string &in version){
        return Text::ParseInt(version.Replace(".", ""));
    }

    bool IsPluginUpdated(){
        return Text::ParseInt(PLUGIN_VERSION.Replace(".", "")) > VersionToInt(DataJson["version"]);
    }

    bool IsVersion1(const string &in version){
        int majorVersionProvided = Text::ParseInt(version.Split(".")[0]);
        return majorVersionProvided == 1;
    }
}