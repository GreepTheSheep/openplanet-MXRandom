[SettingsTab name="About" order="5" icon="InfoCircle"]
void RenderAboutTab() {
    if (MX::APIDown) {
        if (!MX::APIRefreshing) {
            UI::Text("\\$fc0" + Icons::ExclamationTriangle);

            UI::SameLine();

            UI::PushFont(Fonts::HeaderSub);
            UI::Text("\\$fc0" + MX_NAME + " is not responding. It might be down.");
            UI::PopFont();

            if (UI::Button("Retry")) {
                startnew(MX::FetchMapTags);
            }
        } else {
            UI::TextDisabled(Icons::AnimatedHourglass + " Loading...");
        }

        UI::Separator();
    }

    UI::PushFont(Fonts::Header);
    UI::SeparatorText(MX_COLOR_STR + Icons::Random + " \\$z " + PLUGIN_NAME);
    UI::PopFont();

    UI::PushID(PLUGIN_NAME);

    UI::Text("Made by \\$777" + Meta::ExecutingPlugin().Author + " \\$aaaand its contributors");
    UI::Text("Version \\$777" + PLUGIN_VERSION);
    UI::Text("Plugin ID \\$777" + Meta::ExecutingPlugin().ID);
    UI::Text("Site ID \\$777" + Meta::ExecutingPlugin().SiteID);
    UI::Text("Type \\$777" + tostring(Meta::ExecutingPlugin().Type));

    if (IS_DEV_MODE) {
        UI::SameLine();
        UI::Text("\\$777(\\$f39" + Icons::Code + " \\$777Dev mode)");
    }

    if (UI::Button(Icons::Heart + " Donate")) {
        OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
    }

    UI::SameLine();

    if (UI::Button(Icons::Kenney::GithubAlt + " Github")) {
        OpenBrowserURL(GITHUB_URL);
    }

    UI::SameLine();

    if (UI::Button(Icons::Heartbeat + " Plugin Home")) {
        OpenBrowserURL("https://openplanet.dev/plugin/" + Meta::ExecutingPlugin().SiteID);
    }

    UI::PopID();

    UI::PushFont(Fonts::HeaderSub);
    UI::SeparatorText("\\$f39" + Icons::Heartbeat + "\\$z Openplanet");
    UI::PopFont();

    UI::PushID("Openplanet");

    UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());

    if (UI::Button(Icons::DiscordAlt + " Discord")) {
        OpenBrowserURL("https://discord.com/invite/openplanet");
    }

    UI::SameLine();

    if (UI::Button(Icons::Kenney::GithubAlt + " Github")) {
        OpenBrowserURL("https://github.com/openplanet-nl");
    }

    UI::SameLine();

    if (UI::Button(Icons::Mastodon + " Mastodon")) {
        OpenBrowserURL("https://mastodon.gamedev.place/@openplanet");
    }

    UI::PopID();

    UI::PushFont(Fonts::HeaderSub);
    UI::SeparatorText(MX_COLOR_STR + Icons::ManiaExchange + "\\$z ManiaExchange");
    UI::PopFont();

    UI::PushID("ManiaExchange");

    if (UI::Button(Icons::KeyboardO + " Contact ManiaExchange")) {
        OpenBrowserURL(MX_URL + "/postcreate?PmTargetUserId=11");
    }

    UI::SameLine();

    if (UI::RedButton(Icons::Heart + " Support ManiaExchange")) {
        OpenBrowserURL(MX_URL + "/about?r=support");
    }

    UI::Text("Base URL \\$777" + PluginSettings::RMC_MX_Url);

    UI::AlignTextToFramePadding();
    UI::Text("Follow the ManiaExchange network on");

    UI::SameLine();

    if (UI::Button(Icons::Facebook + " Facebook")) {
        OpenBrowserURL("https://facebook.com/maniaexchange/");
    }

    UI::SameLine();

    // TODO missing icon
    if (UI::Button("Bluesky")) {
        OpenBrowserURL("https://bsky.app/profile/maniaexchange.bsky.social");
    }

    UI::SameLine();

    if (UI::Button(Icons::YoutubePlay + " YouTube")) {
        OpenBrowserURL("https://youtube.com/maniaexchangetracks/");
    }

    UI::SameLine();

    if (UI::Button(Icons::DiscordAlt + " Discord")) {
        OpenBrowserURL("https://discord.mania.exchange/");
    }

    UI::PopID();
}