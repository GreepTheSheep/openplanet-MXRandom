bool WindowInfo_Show = true;

Resources::Font@ Header1 = Resources::GetFont("DroidSans.ttf", 22);
Resources::Font@ Header2 = Resources::GetFont("DroidSans.ttf", 20);

void RenderPluginInfoInterface() {
    if (!WindowInfo_Show) return;
    if (UI::Begin(MXColor + Icons::InfoCircle + " \\$z" + name, WindowInfo_Show)) {
        UI::BeginTabBar("MXInfoTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
        if (IsPluginInfoAPILoaded()) {
            if (UI::BeginTabItem("Rules")) {
                RenderPluginInfoRules();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Announcements")) {
                RenderPluginInfoAnnouncements();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem("Changelog")) {
                RenderPluginInfoChangelog();
                UI::EndTabItem();
            }
        }
        if (UI::BeginTabItem("About")) {
            RenderPluginInfoAbout();
            UI::EndTabItem();
        }
        UI::EndTabBar();
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

void RenderPluginInfoRules() {
    UI::Text("Coming soon");
}

void RenderPluginInfoAnnouncements() {
    UI::Text("Coming soon");
}

void RenderPluginInfoChangelog() {
    UI::Text("Coming soon");
}