namespace MainUIView
{
    void Header()
    {
        float scale = UI::GetScale();
        if (MX::APIDown) {
            if (!MX::APIRefreshing) {
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.20, 35*scale));
                UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$z"+MX_NAME + " is not responding. It might be down.");
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.45, 70*scale));
                if (UI::Button("Retry")) {
                    startnew(MX::FetchMapTags);
                }
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.44, 35*scale));
                UI::TextDisabled(Hourglass + " Loading...");
            }
        } else {
#if TMNEXT
            if (Permissions::PlayLocalMap()) {
#endif
                if (TM::CurrentTitlePack() == "") {
                    UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.36, 55*scale));
                    UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$zPlease select a title pack.");
                } else {
                    if (!MX::RandomMapIsLoading) {
                        UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.36, 35*scale));
                        if (UI::GreenButton(Icons::Play + " Play a random map")) {
                            startnew(MX::LoadRandomMap);
                        }
                    } else {
                        UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.42, 35*scale));
                        int HourGlassValue = Time::Stamp % 3;
                        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                        UI::Text(Hourglass + " Loading...");
                    }
                    UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.34, 70*scale));
                    if (UI::ButtonColored(Icons::ClockO +" Random Map Challenge", 0.155)) {
                        window.isInRMCMode = !window.isInRMCMode;
                    }
                }
#if TMNEXT
            } else {
                UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.30, 45*scale));
                UI::Text(Icons::TimesCircle + "You don't have the permissions to play local maps");
            }
#endif
        }
        UI::SetCursorPos(vec2(0, 100) * scale);
        UI::Separator();
    }

    void RecentlyPlayedMapsTab()
    {
        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.10f, 0.10f, 0.10f, 1));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, 1));

        if (DataJson.GetType() != Json::Type::Null && DataJson["recentlyPlayed"].Length > 0 && UI::BeginTable("RecentlyPlayedMaps", 5, UI::TableFlags::ScrollX | UI::TableFlags::NoKeepColumnsVisible | UI::TableFlags::RowBg)) {
            float scale = UI::GetScale();
            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Created by", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Played", UI::TableColumnFlags::WidthFixed, 135 * scale);
            UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 90 * scale);
            UI::TableSetupScrollFreeze(0, 1);
            UI::TableHeadersRow();
            Render::RecentlyPlayedMaps();
            UI::EndTable();
        } else {
            UI::Text("No recently played maps");
        }

        UI::PopStyleColor(2);
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

                if (UI::BeginTabItem((release.name.Replace("v", "") == PLUGIN_VERSION ? "\\$090": "") + Icons::Tag + " \\$z" + release.name)) {
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