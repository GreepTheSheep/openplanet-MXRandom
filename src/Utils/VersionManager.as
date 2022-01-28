namespace Versioning
{
    int VersionToInt(string version){
        return Text::ParseInt(version.Replace(".", ""));
    }

    bool IsVersionUpdated(string version){
        return Text::ParseInt(PLUGIN_VERSION.Replace(".", "")) > VersionToInt(version);
    }

    bool IsVersion1(string version){
        int majorVersionProvided = Text::ParseInt(version.Split('.')[0]);
        return majorVersionProvided == 1;
    }
}