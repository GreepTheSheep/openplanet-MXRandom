namespace Render
{
    void RecentlyPlayedMaps()
    {
        for (uint i = 0; i < DataJson["recentlyPlayed"].Length; i++)
        {
            MX::MapInfo@ map = MX::MapInfo(DataJson["recentlyPlayed"][i]);
            UI::PushID("RecentlyPlayedMap"+i);
            UI::TableNextRow();

            UI::TableSetColumnIndex(0);
            UI::Text(map.Name);
            UI::TableSetColumnIndex(1);
            UI::Text(map.Username);
            UI::TableSetColumnIndex(2);
            if (map.PlayedAt.GetType() == Json::Type::Object) UI::Text(GeneratePlayedAtString(map.PlayedAt));
            else {
                UI::Text("Unknown");
                UI::SetPreviousTooltip("Unable to parse date, maybe this map was migrated from old version.");
            }
            UI::TableSetColumnIndex(3);
            if (map.Tags.get_Length() == 0) UI::Text("No tags");
            else {
                for (uint j = 0; j < map.Tags.Length; j++) {
                    Render::MapTag(map.Tags[j]);
                    UI::SameLine();
                }
            }
            UI::TableSetColumnIndex(4);

            if (UI::ColoredButton(Icons::ExternalLink, 0.55, 1, 0.5)) {
#if DEPENDENCY_MANIAEXCHANGE
                ManiaExchange::ShowMapInfo(map.TrackID);
#else
                OpenBrowserURL("https://"+MX_URL+"/maps/"+map.TrackID);
#endif
            }
            UI::SameLine();
#if TMNEXT
            if (Permissions::PlayLocalMap() && UI::GreenButton(Icons::Play)) {
#else
            if (UI::GreenButton(Icons::Play)) {
#endif
                TM::loadMapURL = "https://"+MX_URL+"/maps/download/"+map.TrackID;
                startnew(TM::LoadMap);
            }

            UI::PopID();
        }
    }

    string GeneratePlayedAtString(Json::Value playedAt){
        int playedAtYear = playedAt["Year"];
        int playedAtMonth = playedAt["Month"];
        int playedAtDay = playedAt["Day"];
        int playedAtHour = playedAt["Hour"];
        int playedAtMinute = playedAt["Minute"];
        int playedAtSecond = playedAt["Second"];
        return playedAtYear + "-" + (playedAtMonth < 10 ? "0":"") + playedAtMonth + "-" + (playedAtDay < 10 ? "0":"") + playedAtDay + " " + (playedAtHour < 10 ? "0":"") + playedAtHour + ":" + (playedAtMinute < 10 ? "0":"") + playedAtMinute + ":" + (playedAtSecond < 10 ? "0":"") + playedAtSecond;
    }
}