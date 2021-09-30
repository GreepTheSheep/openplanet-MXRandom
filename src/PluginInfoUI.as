// All texts are fetched from the API set in Setting_API_URL (default: https://greep.gq/api/rmc.json)

bool WindowInfo_Show = false;

Resources::Font@ Header1 = Resources::GetFont("DroidSans.ttf", 22);
Resources::Font@ Header2 = Resources::GetFont("DroidSans.ttf", 20);

int WindowInfo_Flags = UI::WindowFlags::NoCollapse + UI::WindowFlags::HorizontalScrollbar;

void RenderPluginInfoInterface() {
    if (!WindowInfo_Show) return;
    
    if (UI::Begin(MXColor + Icons::InfoCircle + " \\$z" + name, WindowInfo_Show, WindowInfo_Flags)) {
        UI::BeginTabBar("MXInfoTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
        if (IsPluginInfoAPILoaded()) {
            if (UI::BeginTabItem(Icons::Book + " Rules")) {
                WindowInfo_Flags = UI::WindowFlags::NoCollapse + UI::WindowFlags::HorizontalScrollbar;
                RenderPluginInfoRules();
                UI::EndTabItem();
            }
            int announcementsLength = PluginInfoNet["announcements"].get_Length();
            if (announcementsLength > 0 && UI::BeginTabItem(Icons::Bullhorn + " Announcements ("+announcementsLength+")")) {
                WindowInfo_Flags = UI::WindowFlags::NoCollapse + UI::WindowFlags::HorizontalScrollbar;
                RenderPluginInfoAnnouncements();
                UI::EndTabItem();
            }
            if (UI::BeginTabItem(Icons::Tag + " Changelog")) {
                WindowInfo_Flags = UI::WindowFlags::NoCollapse + UI::WindowFlags::HorizontalScrollbar;
                RenderPluginInfoChangelog();
                UI::EndTabItem();
            }
        }
        if (UI::BeginTabItem(Icons::Kenney::InfoCircle+" About")) {
            WindowInfo_Flags = UI::WindowFlags::NoCollapse + UI::WindowFlags::AlwaysAutoResize;
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
    UI::Text("Made by \\$777" + Meta::ExecutingPlugin().get_Author() + " \\$aaaand its contributors");
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

    UI::Text(MXColor + Icons::Exchange);
    UI::SameLine();
    UI::PushFont(Header2);
    UI::Text("ManiaExchange");
    UI::PopFont();
    UI::Text("Base URL \\$777" + TMXURL);
    UI::Text("Game Name \\$777" + gameName);

    UI::Separator();

    if (UI::Button(Icons::Heart + " Donate")){
        OpenBrowserURL("https://github.com/sponsors/GreepTheSheep");
    }
    UI::SameLine();
    if (UI::Button(Icons::Kenney::GithubAlt + " Github")){
        OpenBrowserURL(repoURL);
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
    UI::BeginTabBar("MXInfoRulesTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
    if (UI::BeginTabItem("Random Map Challenge")) {
        for (uint i = 0; i < PluginInfoNet["rules"]["challenge"].get_Length(); i++) {
            UI::Text("●");
            UI::SameLine();
            UI::Text(PluginInfoNet["rules"]["challenge"][i]);
        }
        UI::EndTabItem();
    }
    if (UI::BeginTabItem("Random Map Survival")) {
        for (uint i = 0; i < PluginInfoNet["rules"]["survival"].get_Length(); i++) {
            UI::Text("●");
            UI::SameLine();
            UI::Text(PluginInfoNet["rules"]["survival"][i]);
        }
        UI::EndTabItem();
    }
    UI::EndTabBar();
}

void RenderPluginInfoAnnouncements() {
    for (uint i = 0; i < PluginInfoNet["announcements"].get_Length(); i++) {
        UI::PushFont(Header1);
        UI::Text(PluginInfoNet["announcements"][i]["title"]);
        UI::PopFont();
        UI::Text("");
        UI::Text(PluginInfoNet["announcements"][i]["description"]);
        if (i != PluginInfoNet["announcements"].get_Length() - 1) UI::Separator();
    }
}

void RenderPluginInfoChangelog() {
    UI::BeginTabBar("MXInfoChangelogTabBar", UI::TabBarFlags::FittingPolicyScroll);
    for (uint i = 0; i < PluginInfoNet["changelog"].get_Length(); i++) {
        string tabTitle = PluginInfoNet["changelog"][i]["title"];
        if (PluginInfoNet["changelog"][i]["version"] == Meta::ExecutingPlugin().get_Version()) tabTitle += " \\$af0(Installed)";
        if (UI::BeginTabItem(tabTitle)) {
            string tabVersion = PluginInfoNet["changelog"][i]["version"];
            if (OpenplanetHasFullPermissions() && VersionToInt(tabVersion) > PluginVersionInt() && UI::Button(Icons::Wrench + " Help contributing!")) {
                OpenBrowserURL(repoURL+"/blob/main/CONTRIBUTING.md");
            }

            for (uint j = 0; j < PluginInfoNet["changelog"][i]["changes"].get_Length(); j++) {
                UI::Text("●");
                UI::SameLine();
                UI::Text(PluginInfoNet["changelog"][i]["changes"][j]["title"]);
                if (PluginInfoNet["changelog"][i]["changes"][j]["type"].GetType() != Json::Type::Null && PluginInfoNet["changelog"][i]["changes"][j]["githubIssueId"].GetType() != Json::Type::Null) {
                    UI::SameLine();
                    int issueID = PluginInfoNet["changelog"][i]["changes"][j]["githubIssueId"];
                    if (UI::Button("#"+issueID)) {
                        if (PluginInfoNet["changelog"][i]["changes"][j]["type"] == "issue") {
                            OpenBrowserURL(repoURL + "/issues/" + issueID);
                        } else if (PluginInfoNet["changelog"][i]["changes"][j]["type"] == "pull") {
                            OpenBrowserURL(repoURL + "/pull/" + issueID);
                        }
                    }
                }
            }
            UI::EndTabItem();
        }
    }
    UI::EndTabBar();
}