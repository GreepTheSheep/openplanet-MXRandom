#if TMNEXT
class OnlineServices
{
    CTrackManiaNetwork@ network;

    // Player info
    string playerName;
    string playerLogin;
    string webId;

    // Plugin info
    Meta::Plugin@ plugin = Meta::ExecutingPlugin();
    string version = plugin.Version;

    // Server info
    Json::Value serverInfo;

    OnlineServices() {
        auto app = GetApp();
        @network = cast<CTrackManiaNetwork>(app.Network);
    }

    string getServerVersion()
    {
        if (serverInfo.GetType() == Json::Type::Object) {
            string version = serverInfo["version"];
            return version;
        }
        return "unknown";
    }
}
#endif