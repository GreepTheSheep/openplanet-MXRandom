namespace MainUIView {
    void Header() {
#if TMNEXT
        if (!Permissions::PlayLocalMap()) {
            UI::CenteredText(Icons::TimesCircle + " You don't have the permissions to play local maps");
            return;
        }
#endif

        if (MX::APIDown) {
            if (MX::APIRefreshing) {
                UI::CenteredText(Icons::AnimatedHourglass + " Loading...", true);
            } else {
                UI::CenteredText("\\$fc0" + Icons::ExclamationTriangle + " \\$z" + MX_NAME + " is not responding. It might be down.");

                if (UI::CenteredButton("Retry")) {
                    startnew(MX::FetchMapTags);
                }
            }

            return;
        }

        if (TM::CurrentTitlePack() == "") {
            UI::CenteredText("\\$fc0" + Icons::ExclamationTriangle + " \\$zPlease select a title pack.");
            return;
        }

        if (MX::RandomMapIsLoading) {
            UI::CenteredText(Icons::AnimatedHourglass + " Loading...");
        } else {
            if (UI::CenteredButton(Icons::Play + " Play a random map", 0.33f)) {
                startnew(MX::LoadRandomMap);
            }
        }

        if (UI::CenteredButton(Icons::ClockO + " Random Map Challenge", 0.155)) {
            window.isInRMCMode = !window.isInRMCMode;
        }
    }

    void RecentlyPlayedMapsTab() {
        if (DataJson.GetType() == Json::Type::Null || DataJson["recentlyPlayed"].Length == 0) {
            UI::Text("No recently played maps");
            return;
        }

        UI::PushStyleColor(UI::Col::TableRowBgAlt, vec4(0.10f, 0.10f, 0.10f, 1));
        UI::PushStyleColor(UI::Col::TableRowBg, vec4(0.13f, 0.13f, 0.13f, 1));

        if (UI::BeginTable("RecentlyPlayedMaps", 5, UI::TableFlags::ScrollY | UI::TableFlags::NoKeepColumnsVisible | UI::TableFlags::RowBg)) {
            UI::TableSetupScrollFreeze(0, 1);
            float scale = UI::GetScale();

            UI::TableSetupColumn("Name", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Author", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Played at", UI::TableColumnFlags::WidthFixed, 135 * scale);
            UI::TableSetupColumn("Tags", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("Actions", UI::TableColumnFlags::WidthFixed, 90 * scale);
            UI::TableHeadersRow();

            Render::RecentlyPlayedMaps();

            UI::EndTable();
        }

        UI::PopStyleColor(2);
    }

    void ChangelogTabs() {
        GH::CheckReleasesReq();

        if (GH::ReleasesReq !is null) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
            return;
        }

        if (GH::Releases.IsEmpty()) {
            if (!GH::releasesRequestError) {
                GH::StartReleasesReq();
            } else {
                UI::Text("Error while loading releases");
            }

            return;
        }

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