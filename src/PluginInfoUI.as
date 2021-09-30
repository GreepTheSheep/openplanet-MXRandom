bool WindowInfo_Show = true;

enum WindowInfoState {
    WINDOW_INFO_STATE_NONE,
    WINDOW_INFO_STATE_ABOUT,
    WINDOW_INFO_STATE_RULES,
    WINDOW_INFO_STATE_ANNOUNCEMENTS,
    WINDOW_INFO_STATE_CHANGELOG
}
WindowInfoState ActualWindowInfo_State = WINDOW_INFO_STATE_ABOUT;
Resources::Font@ Header1 = Resources::GetFont("DroidSans.ttf", 22);
Resources::Font@ Header2 = Resources::GetFont("DroidSans.ttf", 20);

void RenderPluginInfoInterface() {
    if (!WindowInfo_Show) return;
    if (UI::Begin(MXColor + Icons::InfoCircle + " \\$z" + name, WindowInfo_Show)) {
        switch (ActualWindowInfo_State) {
            case WINDOW_INFO_STATE_ABOUT:
                RenderPluginInfoAbout();
            break;
            case WINDOW_INFO_STATE_RULES:
                UI::Text("Rules");
                // RenderPluginInfoRules();
            break;
            case WINDOW_INFO_STATE_ANNOUNCEMENTS:
                UI::Text("Announcements");
                // RenderPluginInfoAnnouncements();
            break;
            case WINDOW_INFO_STATE_CHANGELOG:
                UI::Text("Changelog");
                // RenderPluginInfoChangelog();
            break;
            default:
                UI::Text("\\$f00Error: No Window State!");
            break;
        }
    }
    UI::End();
}

void RenderPluginInfoAbout() {
    UI::Text(MXColor + Icons::Random);
    UI::SameLine();
    UI::PushFont(Header1);
    UI::Text(name);
    UI::PopFont();
    UI::Text("Made by \\$777" + Meta::ExecutingPlugin().get_Author());
    UI::Text("Version \\$777" + Meta::ExecutingPlugin().get_Version());
    UI::Text("Plugin ID \\$777" + Meta::ExecutingPlugin().get_ID());
    UI::Text("Site ID \\$777" + Meta::ExecutingPlugin().get_SiteID());
    UI::Text("Type \\$777" + changeEnumStyle(tostring(Meta::ExecutingPlugin().get_Type())));
    
    UI::Separator();

    UI::Text("\\$f39" + Icons::Heartbeat);
    UI::SameLine();
    UI::PushFont(Header2);
    UI::Text("Openplanet");
    UI::PopFont();
    UI::Text("Version \\$777" + Meta::OpenplanetBuildInfo());

    UI::Separator();

    if (UI::Button(Icons::Heart + " Donate")){
        OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
    }
    UI::SameLine();
    if (UI::Button(Icons::Kenney::GithubAlt + " Github")){
        OpenBrowserURL("https://github.com/GreepTheSheep/openplanet-mx-random");
    }
    UI::SameLine();
    if (UI::Button(Icons::DiscordAlt + " Discord")){
        OpenBrowserURL("https://greep.gq/discord");
    }
    UI::SameLine();
    if (UI::Button(Icons::Heartbeat + " Plugin Home")){
        OpenBrowserURL("https://openplanet.nl/files/" + Meta::ExecutingPlugin().get_SiteID());
    }
    UI::SameLine();
}