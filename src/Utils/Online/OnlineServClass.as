class OnlineService
{
    CTrackManiaNetwork@ network;

    // Player info
    string playerName;
    string playerLogin;
    string webId;

    // Plugin info
    Meta::Plugin@ plugin = Meta::ExecutingPlugin();
    string version = plugin.Version;

    bool pluginAuthed = false;
    bool isAuthenticating = false;
    bool authWindowOpened = false;

    OnlineService() {
        auto app = GetApp();
        @network = cast<CTrackManiaNetwork>(app.Network);
    }
}