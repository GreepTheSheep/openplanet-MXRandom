[SettingsTab name="About" order="5" icon="InfoCircle"]
void RenderAboutTab()
{
    if (MX::APIDown)
    {
        if (!MX::APIRefreshing)
        {
            UI::Text("\\$fc0"+Icons::ExclamationTriangle);
            UI::SameLine();
            UI::PushFont(Fonts::HeaderSub);
            UI::Text("\\$fc0"+MX_NAME + " is not responding. It might be down.");
            UI::PopFont();
            if (UI::Button("Retry")) startnew(MX::FetchMapTags);
        }
        else
        {
            UI::TextDisabled(Icons::AnimatedHourglass() + " Loading...");
        }
        UI::Separator();
    }

    UI::PushFont(Fonts::Header);
    UI::SeparatorText(MX_COLOR_STR + Icons::Random + " \\$z " + PLUGIN_NAME);
    UI::PopFont();
    UI::Text("Made by \\$777" + Meta::ExecutingPlugin().Author + " \\$aaaand its contributors");
    UI::Text("Version \\$777" + PLUGIN_VERSION);
    UI::Text("Plugin ID \\$777" + Meta::ExecutingPlugin().ID);
    UI::Text("Site ID \\$777" + Meta::ExecutingPlugin().SiteID);
    UI::Text("Type \\$777" + tostring(Meta::ExecutingPlugin().Type));
    if (IS_DEV_MODE) {
        UI::SameLine();
        UI::Text("\\$777(\\$f39"+Icons::Code+" \\$777Dev mode)");
    }

    if (UI::Button(Icons::Heart + " Donate")) OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
    UI::SameLine();
    if (UI::Button(Icons::Kenney::GithubAlt + " Github")) OpenBrowserURL(GITHUB_URL);
    UI::SameLine();
    if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://greep.gq/discord");
    UI::SameLine();
    if (UI::Button(Icons::Heartbeat + " Plugin Home")) OpenBrowserURL("https://openplanet.nl/files/" + Meta::ExecutingPlugin().SiteID);

    UI::PushFont(Fonts::HeaderSub);
    UI::SeparatorText("\\$f39" + Icons::Heartbeat + " \\$z " + "Openplanet");
    UI::PopFont();
    UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());

    UI::PushFont(Fonts::HeaderSub);
    UI::SeparatorText(MX_COLOR_STR + Icons::ManiaExchange + " \\$z " + "ManiaExchange");
    UI::PopFont();
    if (UI::Button(Icons::KeyboardO + " \\$zContact ManiaExchange")) OpenBrowserURL("https://"+MX_URL+"/postcreate?PmTargetUserId=11");
    UI::SameLine();
    if (UI::RedButton(Icons::Heart + " \\$zSupport ManiaExchange")) OpenBrowserURL("https://"+MX_URL+"/about?r=support");

    UI::Text("Base URL \\$777" + PluginSettings::RMC_MX_Url);

    UI::AlignTextToFramePadding();
    UI::Text("Follow the ManiaExchange network on");
    UI::SameLine();
    if (UI::Button(Icons::Facebook + " Facebook")) OpenBrowserURL("https://facebook.com/maniaexchange/");
    UI::SameLine();
    if (UI::Button(Icons::Twitter + " Twitter")) OpenBrowserURL("https://twitter.com/maniaexchange/");
    UI::SameLine();
    if (UI::Button(Icons::YoutubePlay + " YouTube")) OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
    UI::SameLine();
    if (UI::Button(Icons::DiscordAlt + " Discord")) OpenBrowserURL("https://discord.mania.exchange/");
}