namespace Render {
    void RecentlyPlayedMaps() {
        UI::ListClipper clipper(DataJson["recentlyPlayed"].Length);

        while (clipper.Step()) {
            for (int i = clipper.DisplayStart; i < clipper.DisplayEnd; i++) {
                MX::MapInfo@ map = MX::MapInfo(DataJson["recentlyPlayed"][i]);

                UI::PushID("RecentlyPlayedMap"+i);
                UI::TableNextRow();
                UI::TableNextColumn();

                UI::AlignTextToFramePadding();
                UI::Text(map.Name);
                UI::TableNextColumn();

                UI::Text(map.Username);
                UI::TableNextColumn();

                if (map.PlayedAt > 0) {
                    UI::Text(GeneratePlayedAtString(map.PlayedAt));
                } else {
                    UI::Text("Unknown");
                    UI::SetPreviousTooltip("Unable to parse date, maybe this map was migrated from old version.");
                }
                UI::TableNextColumn();

                if (map.Tags.IsEmpty()) {
                    UI::Text("No tags");
                } else {
                    for (uint j = 0; j < map.Tags.Length; j++) {
                        Render::MapTag(map.Tags[j]);
                        UI::SameLine();
                    }
                }
                UI::TableNextColumn();

                if (UI::ButtonColored(Icons::ExternalLink, 0.55, 1, 0.5)) {
#if DEPENDENCY_MANIAEXCHANGE
                    ManiaExchange::ShowMapInfo(map.MapId);
#else
                    OpenBrowserURL(MX_URL + "/mapshow/" + map.MapId);
#endif
                }
                UI::SameLine();
#if TMNEXT
                if (Permissions::PlayLocalMap() && UI::GreenButton(Icons::Play)) {
#elif FALSE
                }
#else
                if (TM::CurrentTitlePack() != map.TitlePack) {
                    if (UI::OrangeButton(Icons::Play)) {
                        startnew(TM::LoadMap, map);
                    }

                    if (UI::BeginItemTooltip()) {
                        UI::Text(Icons::ExclamationTriangle + " Loaded titlepack doesn't match the map's titlepack,\nmap might fail to load or return you to the menu.");
                        UI::Separator();
                        UI::TextDisabled("Titlepack: " + map.TitlePack);
                        UI::EndTooltip();
                    }
                } else if (UI::GreenButton(Icons::Play)) {
#endif
                    startnew(TM::LoadMap, map);
                }

                UI::PopID();
            }
        }
    }

    string GeneratePlayedAtString(int stamp) {
        return Time::FormatString("%F %T", stamp);
    }
}