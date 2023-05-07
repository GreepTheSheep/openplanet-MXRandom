class RMTHelpModalDialog : ModalDialog
{
    UI::Texture@ clubIdTex;
    UI::Texture@ roomIdTex;

    RMTHelpModalDialog()
    {
        super(Icons::InfoCircle + " \\$zRandom Map Together###RMTHelp");
        m_size = vec2(Draw::GetWidth(), Draw::GetHeight()) * 0.6f;
        @clubIdTex = UI::LoadTexture("src/Assets/Images/help_clubId.jpg");
        @roomIdTex = UI::LoadTexture("src/Assets/Images/help_roomId.jpg");
    }

    void RenderDialog() override
    {
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::PushFont(g_fontHeader);
        UI::Text("Random Map Together");
        UI::PopFont();
        UI::Markdown(
            "Random Map Together is an online mode where your connected players can participate cooperatively to get the most goal medals.\n\n" +
            "The game mode requires all players to join the server you have set up. Players have no plugins to install and is compatible with console players.\n\n"
        );
        UI::NewLine();
        UI::Separator();
        UI::PushFont(g_fontHeader);
        UI::Text("Prerequisites for a good functioning of the RMT mode");
        UI::PopFont();
        UI::Markdown(
            "The prerequisite for a good functioning is to have imperatively these 3 dependencies activated: NadeoServices, MLHook and MLFeed.\n\n" +
            "NadeoServices is automatically delivered with Openplanet. However, it may not be delivered on your computer and therefore may be listed as corrupted. If this is the case, please reinstall Openplanet.\n\n" +
            "The MLHook and MLFeed dependencies are external dependencies; you will have to install them through the plugin manager.\n\n" +
            "NadeoServices is essential to be able to send events to the Nadeo room like changing the map and resetting the remaining time.\n\n" +
            "MlHook and MLFeed are essential to retrieve the content of players in the server to retrieve their best time on the current map and determine their scores.\n\n" +
            "Better Chat plugin is optional but can be used to send game statistics to other players through in-game chat."
        );
        UI::NewLine();
        UI::Separator();
        UI::PushFont(g_fontHeader);
        UI::Text("Setting up a Room");
        UI::PopFont();
        UI::Markdown(
            "Create a Nadeo Room with a single map of your choice on it, this map will be used as a lobby map.\n\n" +
            "Set the gamemode as 'Time Attack' and set the 'Time Limit' setting to '0'\n\n" +
            "Desativate the 'Scalable Room' setting so everyone can join and participate in the RMT mode."
        );
        UI::NewLine();
        UI::Separator();
        UI::PushFont(g_fontHeader);
        UI::Text("Finding your Club and Room ID");
        UI::PopFont();
        UI::Markdown(
            "To find your club and room ID, go to [Trackmania.io](https://trackmania.io/#/clubs) and search for your club.\n\n" +
            "Once on it, look up for the club ID, and paste this value on its appropriate input.\n\n" +
            "In the club page on Trackmania.io, go to Activities and find your room.\n\n" +
            "Once on it, look up for the room ID, and paste this value on its appropriate input."
        );

        vec2 imgSize = clubIdTex.GetSize();
        UI::Image(clubIdTex, vec2(
            m_size.x-20*scale,
            imgSize.y / (imgSize.x / (m_size.x-20*scale))
        ));
        UI::Image(roomIdTex, vec2(
            m_size.x-20*scale,
            imgSize.y / (imgSize.x / (m_size.x-20*scale))
        ));
        UI::EndChild();
        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }
    }
}