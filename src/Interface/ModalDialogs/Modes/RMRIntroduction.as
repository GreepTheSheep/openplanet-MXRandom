class RMRIntroModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    string resErrorString;
    Json::Value m_rulesJson;
    bool m_requestError = false;

    RMRIntroModalDialog()
    {
        super(MX_COLOR_STR + Icons::FlagCheckered + " \\$zRandom Map Race###Introduction");
        m_size = vec2(Draw::GetWidth()/2, Draw::GetHeight()/2);
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -32));
        UI::PushFont(g_fontHeader);
        UI::Text("Welcome to the Random Map Race!");
        UI::PopFont();
        UI::Markdown(
            "**The Random Map Race is an online game mode where you can challenge your friends on random maps.**\n\n"
            "Participants will have a list of rooms and can create their own!\n"
            "Room organizers will be able to define its rules, such as the choice of the goal of the medal, the number of skips allowed, the duration of the game... They can also make it private with a password or not.\n"
            "Participants will be on random maps, but will not be together on the same map! This makes the games more dynamic and leaves no time for another player to wait!\n\n"
            "**If you have any questions or suggestions, join the Discord below!**"
        );
        if (UI::GreenButton(Icons::DiscordAlt + " Join Discord")) OpenBrowserURL("https://greep.gq/discord");
        UI::EndChild();
        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }
    }
}