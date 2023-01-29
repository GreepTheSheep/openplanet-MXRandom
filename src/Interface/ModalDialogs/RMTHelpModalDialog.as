class RMTHelpModalDialog : ModalDialog
{
    UI::Texture@ clubIdTex;
    UI::Texture@ roomIdTex;

    RMTHelpModalDialog()
    {
        super(Icons::InfoCircle + " \\$zRandom Map Together###RMTHelp");
        m_size = vec2(Math::Ceil(Draw::GetWidth()/1.2f), Math::Ceil(Draw::GetHeight()/1.2f));
        @clubIdTex = UI::LoadTexture("src/Assets/Images/help_clubId.png");
        @roomIdTex = UI::LoadTexture("src/Assets/Images/help_roomId.png");
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -32));
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
            m_size.x-20,
            imgSize.y / (imgSize.x / (m_size.x-20))
        ));
        UI::Image(roomIdTex, vec2(
            m_size.x-20,
            imgSize.y / (imgSize.x / (m_size.x-20))
        ));
        UI::EndChild();
        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }
    }
}