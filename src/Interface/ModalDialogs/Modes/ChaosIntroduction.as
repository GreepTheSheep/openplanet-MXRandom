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
        UI::BeginChild("Content", vec2(0, -32) * UI::GetScale());
        UI::PushFont(g_fontHeader);
        UI::Text("The Chaos Mode comes in the Random Map Challenge!");
        UI::PopFont();
        UI::Markdown(
            "**Chaos mode is a mode developed by Nsgr featuring game physics modification (No Engine, No steer and more!) during your run. Including Twitch chat voting!**\n"
            "**To get it, please install the Chaos Mode plugin in the plugin manager!**\n"
            "To get Twitch Integration with the Chaos Mode, please install the 'Twitch Base' plugin in the plugin manager and insert your Twitch authentification key in the Twitch Base plugin settings (details on this [plugin page](https://openplanet.dev/plugin/twitchbase)), then enable Twitch voting in the Chaos Mode settings\n\n"
            "If you got this dialog box again after installing the plugins, try to restart the script engine by pressing Ctrl+Shift+R.\n"
            "Note that Chaos mode is a fun mode, and will not be ranked in the leaderboard"
        );
        UI::EndChild();
        if (UI::Button(Icons::Times + " Close")) {
            Close();
        }
    }
}