namespace MainUIView
{
    void Header()
    {
        if (MX::APIDown) {
            if (!MX::APIRefreshing) {
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.20, 35));
                UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$z"+MX_NAME + " is not responding. It might be down.");
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.45, 70));
                if (UI::Button("Retry")) {
                    startnew(MX::FetchMapTags);
                }
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.44, 35));
                UI::TextDisabled(Hourglass + " Loading...");
            }
        } else {
            vec2 pos_orig = UI::GetCursorPos();
            if (!MX::RandomMapIsLoading) {
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.36, 35));
                if (UI::GreenButton(Icons::Play + " Play a random map")) {
                    startnew(MX::LoadRandomMap);
                }
            } else {
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.42, 35));
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            }
            UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.34, 70));
            if (UI::ColoredButton(Icons::ClockO +" Random Map Challenge", 0.155)) {
                window.isInRMCMode = !window.isInRMCMode;
            }
        }

        UI::SetCursorPos(vec2(0, 100));
        UI::Separator();
    }

    void RecentlyPlayedMapsTab()
    {
        UI::Text("Recently played maps");
        if (DataJson.GetType() != Json::Type::Null && DataJson["recentlyPlayed"].Length > 0 && UI::BeginTable("RecentlyPlayedMaps", 5, UI::TableFlags::ScrollX | UI::TableFlags::NoKeepColumnsVisible)) {
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Played", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 90);
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableHeadersRow();
            Render::RecentlyPlayedMaps();
            UI::EndTable();
        } else {
            UI::Text("No recently played maps");
        }
    }

    void ChangelogTabs()
    {
        GH::CheckReleasesReq();
        if (GH::ReleasesReq is null && GH::Releases.Length == 0) {
            if (!GH::releasesRequestError) {
                GH::StartReleasesReq();
            } else {
                UI::Text("Error while loading releases");
            }
        }
        if (GH::ReleasesReq !is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        }

        if (GH::ReleasesReq is null && GH::Releases.Length > 0) {
            UI::BeginTabBar("MainUISettingsTabBar", UI::TabBarFlags::FittingPolicyScroll);
            for (uint i = 0; i < GH::Releases.Length; i++) {
                GH::Release@ release = GH::Releases[i];

                if (UI::BeginTabItem((release.name.Replace('v', '') == PLUGIN_VERSION ? "\\$090": "") + Icons::Tag + " \\$z" + release.name)) {
                    UI::BeginChild("Changelog"+release.name);
                    UI::Markdown(Render::FormatChangelogBody(release.body));
                    UI::EndChild();
                    UI::EndTabItem();
                }
            }
            UI::EndTabBar();
        }
    }
}