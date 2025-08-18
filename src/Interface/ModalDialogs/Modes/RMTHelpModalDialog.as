class RMTHelpModalDialog : ModalDialog {
    UI::Texture@ clubIdTex;
    UI::Texture@ roomIdTex;

    RMTHelpModalDialog() {
        super(Icons::InfoCircle + " \\$zRandom Map Together###RMTHelp");
        m_size = vec2(Draw::GetWidth(), Draw::GetHeight()) * 0.6f;
        @clubIdTex = UI::LoadTexture("src/Assets/Images/help_clubId.jpg");
        @roomIdTex = UI::LoadTexture("src/Assets/Images/help_roomId.jpg");
    }

    void RenderDialog() override {
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);

        UI::PaddedHeaderSeparator("Random Map Together");

        UI::Markdown("""
Random Map Together is an online mode where players can play together in a room to get the most goal medals.

The game mode requires all players to join the server you have set up. The other players only need Club access to join.
        """);

        UI::PaddedHeaderSeparator("Requirements");

        UI::Markdown("""
The game mode requires 3 dependencies / plugins:

- **NadeoServices:** This is automatically shipped with Openplanet. If you are missing it, please reinstall Openplanet, as your installation might be corruped.
- **[MLHook](https://openplanet.dev/plugin/mlhook)**
- **[MLFeed](https://openplanet.dev/plugin/mlfeedracedata)**

The MLHook and MLFeed dependencies are external plugins made by Xertrov; you will have to install them through the Plugin Manager or download them from the site.


Furthermore, the game mode can use 2 optional plugins if they are installed:

- **[Better Chat](https://openplanet.dev/plugin/betterchat):** If installed, the plugin can send game statistics to other players through the in-game chat.
- **[Better Room Manager](https://openplanet.dev/plugin/betterroommanager):** If installed, the plugin can autodetect the current Club and Room ID if you are in a server.
        """);

        UI::PaddedHeaderSeparator("Setting up the room");

        UI::Markdown("""
Create a Nadeo Room with a single map of your choice on it. This map will be used as the lobby map.

Set the gamemode as "Time Attack" and the "Time Limit" to 0.

Deactivate the "Scalable Room" setting so everyone can join and participate.
        """);

        UI::PaddedHeaderSeparator("Finding your Club and Room ID");

        UI::Markdown("""
To find your club and room ID, visit [Trackmania.io](https://trackmania.io/#/clubs) and search for your club.

Once there, look up for the club ID. Paste this number in the Club ID field of the RMT menu.
        """);

        UI::NewLine();

        vec2 imgSize = clubIdTex.GetSize();

        UI::Image(clubIdTex, vec2(
            m_size.x-20*scale,
            imgSize.y / (imgSize.x / (m_size.x-20*scale))
        ));

        UI::NewLine();

        UI::Markdown("""
In the club page on Trackmania.io, go to the Activities tab and find the room you want to use to host RMT.

There, you can find the room ID. Paste this number in the Room ID field of the RMT menu.
        """);

        UI::NewLine();

        UI::Image(roomIdTex, vec2(
            m_size.x-20*scale,
            imgSize.y / (imgSize.x / (m_size.x-20*scale))
        ));

        UI::Markdown("Once you have found both IDs, you can press \"Check Room\". If the plugin finds the room, you can start playing RMT.");

        UI::EndChild();
        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }
    }
}