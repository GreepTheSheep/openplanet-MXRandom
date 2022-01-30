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
            UI::Text(GeneratePlayedAtString(map.PlayedAt));
            UI::TableSetColumnIndex(3);
            if (map.Tags.get_Length() == 0) UI::Text("No tags");
            else {
                for (uint j = 0; j < map.Tags.Length; j++) {
                    Render::MapTag(map.Tags[j]);
                    UI::SameLine();
                }
            }
            UI::TableSetColumnIndex(4);
            UI::Text(tostring(map.AwardCount));
            UI::TableSetColumnIndex(5);

            if (UI::ColoredButton(Icons::ExternalLink, 0.55, 1, 0.5)) {
                OpenBrowserURL("https://"+MX_URL+"/maps/"+map.TrackID);
            }
            UI::SameLine();
            if (TM::GameEdition == TM::GameEditions::NEXT && Permissions::PlayLocalMap() && UI::GreenButton(Icons::Play)) {
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