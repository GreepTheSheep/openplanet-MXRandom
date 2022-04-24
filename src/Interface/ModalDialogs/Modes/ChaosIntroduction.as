class ChaosModeIntroModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    string resErrorString;
    Json::Value m_rulesJson;
    bool m_requestError = false;

    ChaosModeIntroModalDialog()
    {
        super(MX_COLOR_STR + Icons::Fire + " \\$zChaos Mode###Introduction");
        m_size = vec2(Draw::GetWidth()/2, Draw::GetHeight()/2);
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -32));
        UI::PushFont(g_fontHeader);
        UI::Text("The Chaos Mode comes in the Random Map Challenge!");
        UI::PopFont();
        UI::Markdown(
            "**Chaos mode is a mode developed by Nsgr featuring game physics modification (No Engine, No steer and more!) during your run.**\n"
            "**To get it, please install the Chaos Mode plugin in the plugin manager!**\n\n"
            "Note that Chaos mode is a fun mode, and will not be ranked in the leaderboard"
        );
        UI::EndChild();
        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }
    }
}