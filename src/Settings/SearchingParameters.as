namespace PluginSettings
{
    [Setting hidden]
    bool CustomRules = false;

    const array<string> SearchingMapLengthOperators = {
        "Exacts",
        "Shorter than",
        "Longer than",
        "Exacts or shorter to",
        "Exacts or longer to"
    };

    [Setting hidden]
    string MapLengthOperator = SearchingMapLengthOperators[0];

    const array<string> SearchingMapLengths = {
        "Anything",
        "15 seconds",
        "30 seconds",
        "45 seconds",
        "1 minute",
        "1 minutes and 15 seconds",
        "1 minutes and 30 seconds",
        "1 minutes and 45 seconds",
        "2 minutes",
        "2 minutes and 30 seconds",
        "3 minutes",
        "3 minutes and 30 seconds",
        "4 minutes",
        "4 minutes and 30 seconds",
        "5 minutes",
        "Longer than 5 minutes"
    };

    const array<int> SearchingMapLengthsMilliseconds = {
        0,
        15000,
        30000,
        45000,
        60000,
        75000,
        90000,
        105000,
        120000,
        150000,
        180000,
        210000,
        240000,
        270000,
        300000,
        100000000,  // infinity, I guess.
    };

    array<string> MapAuthorNamesArr = {};

#if TMNEXT
    const int releaseYear = 2020;
#else
    const int releaseYear = 2011;
#endif

    [Setting hidden]
    string MapLength = SearchingMapLengths[0];

    [Setting hidden]
    string MapAuthor = "";

    [Setting hidden]
    bool MapAuthorNameNeedsExactMatch = true;

    [Setting hidden]
    string MapName = "";
    
    [Setting hidden]
    bool UseDateInterval = false;

    [Setting hidden]
    int FromYear = releaseYear;

    [Setting hidden]
    int FromMonth = 1;

    [Setting hidden]
    int FromDay = 1;

    Time::Info currentDate = Time::Parse();
    [Setting hidden]
    int ToYear = currentDate.Year;

    [Setting hidden]
    int ToMonth = currentDate.Month;

    [Setting hidden]
    int ToDay = currentDate.Day;

    [Setting hidden]
    int64 MapPackID = 0;

    [Setting hidden]
    string MapTags = "";
    array<int> MapTagsArr = {};

    [Setting hidden]
#if TMNEXT
    string ExcludeMapTags = "23,37,40";
    array<int> ExcludeMapTagsArr = {23, 37, 40};
#else
    string ExcludeMapTags = "20";
    array<int> ExcludeMapTagsArr = {20};
#endif

    bool initArrays = false;

    [Setting hidden]
    bool TagInclusiveSearch = false;

    const array<string> SearchingDifficultys = {
        "Anything",
        "Beginner",
        "Intermediate",
        "Advanced",
        "Expert",
        "Lunatic",
        "Impossible"
    };

    [Setting hidden]
    string Difficulty = SearchingDifficultys[0];

    [Setting hidden]
    bool SkipSeenMaps = false;

    [SettingsTab name="Searching" order="2" icon="Search"]
    void RenderSearchingSettingTab()
    {
        CustomRules = UI::Checkbox("\\$fc0"+Icons::ExclamationTriangle+" \\$zUse custom parameters. Forbidden on official leaderboards.", CustomRules);
        UI::Separator();

        UI::BeginDisabled(!CustomRules);

        if (UI::OrangeButton("Reset to default")){
            MapLengthOperator = SearchingMapLengthOperators[0];
            MapLength = SearchingMapLengths[0];
            UseDateInterval = false;
            FromYear = releaseYear;
            FromMonth = 1;
            FromDay = 1;
            ToYear = currentDate.Year;
            ToMonth = currentDate.Month;
            ToDay = currentDate.Day;
            TagInclusiveSearch = false;
            MapAuthor = "";
            MapName = "";
            MapPackID = 0;
            MapTagsArr = {};
            MapAuthorNamesArr = {};
            MapAuthorNameNeedsExactMatch = true;
#if TMNEXT
            ExcludeMapTagsArr = {23, 37, 40};
#else
            ExcludeMapTagsArr = {20};
#endif
        }

        // Length Operator
        UI::SetNextItemWidth(160);
        if (UI::BeginCombo("##LengthOperator", MapLengthOperator)){
            for (uint i = 0; i < SearchingMapLengthOperators.Length; i++) {
                string operator = SearchingMapLengthOperators[i];

                if (UI::Selectable(operator, MapLengthOperator == operator)) {
                    MapLengthOperator = operator;
                }

                if (MapLengthOperator == operator) {
                    UI::SetItemDefaultFocus();
                }
            }
            UI::EndCombo();
        }

        UI::SameLine();
        UI::SetNextItemWidth(200);
        // Length
        if (UI::BeginCombo("Map length", MapLength)){
            for (uint i = 0; i < SearchingMapLengths.Length; i++) {
                string length = SearchingMapLengths[i];

                if (UI::Selectable(length, MapLength == length)) {
                    MapLength = length;
                }

                if (MapLength == length) {
                    UI::SetItemDefaultFocus();
                }
            }
            UI::EndCombo();
        }

        UI::NewLine();
        UseDateInterval = UI::Checkbox("Use date interval for map search", UseDateInterval);
        UI::SetPreviousTooltip("If enabled, you will only get maps uploaded or updated inside the set date interval.\nSetting a very small interval can end in no map being found for a very long time and the API being spammed.\nPlease use responsibly.");
        if (UseDateInterval) {
            if (UI::BeginTable("DateIntervals", 2, UI::TableFlags::SizingFixedFit)) {
                UI::TableNextColumn();
                UI::Text("From date");
                UI::SetNextItemWidth(150);
                FromYear = UI::SliderInt("##From year", FromYear, releaseYear, currentDate.Year, "Year: %d");
                UI::SetNextItemWidth(150);
                FromMonth = UI::SliderInt("##From month", FromMonth, 1, 12, "Month: %.02d");
                UI::SetNextItemWidth(150);
                FromDay = UI::SliderInt("##From day", FromDay, 1, 31, "Day: %.02d");

                UI::TableNextColumn();
                UI::Text("To date");
                UI::SetNextItemWidth(150);
                ToYear = UI::SliderInt("##To year", ToYear, releaseYear, currentDate.Year, "Year: %d");
                UI::SetNextItemWidth(150);
                ToMonth = UI::SliderInt("##To month", ToMonth, 1, 12, "Month: %.02d");
                UI::SetNextItemWidth(150);
                ToDay = UI::SliderInt("##To day", ToDay, 1, 31, "Day: %.02d");
                UI::EndTable();
            }
        }
        
        UI::NewLine();

        UI::SetNextItemWidth(200);
        MapName = UI::InputText("Map Name Filter", MapName, false);
        UI::SetNextItemWidth(200);
        MapPackID = Text::ParseInt64(UI::InputText("Map Pack ID", MapPackID != 0 ? tostring(MapPackID) : "", false));
        // Using InputText instead of a InputInt because it looks better and using "" as empty value instead of 0 for consistency with the other fields
        UI::SetNextItemWidth(200);
        MapAuthor = UI::InputText("Map Author(s) Filter", MapAuthor, false);
        UI::SameLine();
        MapAuthorNameNeedsExactMatch = UI::Checkbox("Exact name matches", MapAuthorNameNeedsExactMatch);
        UI::SetPreviousTooltip("If disabled, you will get results for any author that contains the text you entered.\nIf you search for \"Nadeo\", you will get results for \"Nadeo\", \"Nadeo123\", \"Nadeo_\", etc.\nIf enabled, you will only get results for \"Nadeo\".\nHowever this can lead to issues if the author has changed their MX username since uploading the map. This can be avoided by specifying all the names the author has used.");
        UI::NewLine();

        MapAuthorNamesArr = ConvertStringToArray(MapAuthor);


        if (!initArrays) {
            MapTagsArr = ConvertListToArray(MapTags);
            ExcludeMapTagsArr = ConvertListToArray(ExcludeMapTags);
            initArrays = true;
        }

        if (UI::BeginTable("tags", 2, UI::TableFlags::SizingFixedFit)) {
            UI::TableNextColumn();
            UI::Text("Include Tags" + (MapTagsArr.Length == 0 ? "" : " (" + MapTagsArr.Length + " selected)"));
            UI::TableNextColumn();
            UI::Text("Exclude Tags" + (ExcludeMapTagsArr.Length == 0 ? "" : " (" + ExcludeMapTagsArr.Length + " selected)"));

            UI::TableNextColumn();
            if (UI::BeginListBox("##Include Tags", vec2(200, 300))){
                for (uint i = 0; i < MX::m_mapTags.Length; i++)
                {
                    MX::MapTag@ tag = MX::m_mapTags[i];
                    if (UI::Selectable(tag.Name, MapTagsArr.Find(tag.ID) >= 0)) MapTagsArr = ToggleMapTag(MapTagsArr, tag.ID);
                }
                UI::EndListBox();
            }

            UI::TableNextColumn();
            if (UI::BeginListBox("##Exclude Tags", vec2(200, 300))){
                for (uint i = 0; i < MX::m_mapTags.Length; i++)
                {
                    MX::MapTag@ tag = MX::m_mapTags[i];
                    if (UI::Selectable(tag.Name, ExcludeMapTagsArr.Find(tag.ID) >= 0)) ExcludeMapTagsArr = ToggleMapTag(ExcludeMapTagsArr, tag.ID);
                }
                UI::EndListBox();
            }
            UI::EndTable();
        }

        TagInclusiveSearch = UI::Checkbox("Tag inclusive search", TagInclusiveSearch);
        UI::SetPreviousTooltip("If enabled, maps must contain all selected tags.");

        MapTags = ConvertArrayToList(MapTagsArr);
        ExcludeMapTags = ConvertArrayToList(ExcludeMapTagsArr);

        UI::NewLine();

        UI::SetNextItemWidth(160);
        if (UI::BeginCombo("Difficulty", Difficulty)){
            for (uint i = 0; i < SearchingDifficultys.Length; i++) {
                string difficulty = SearchingDifficultys[i];

                if (UI::Selectable(difficulty, Difficulty == difficulty)) {
                    Difficulty = difficulty;
                }

                if (Difficulty == difficulty) {
                    UI::SetItemDefaultFocus();
                }
            }
            UI::EndCombo();
        }

        UI::NewLine();

        SkipSeenMaps = UI::Checkbox("Skip Seen Maps", SkipSeenMaps);
        UI::SetPreviousTooltip("If enabled, every map will only appear once per run.");

        UI::EndDisabled();
    }

    array<int> ToggleMapTag(array<int> tags, int tagID)
    {
        int position = tags.Find(tagID);
        if (position >= 0) {
            tags.RemoveAt(position);
        } else {
            tags.InsertLast(tagID);
        }
        return tags;
    }

    string ConvertArrayToList(array<int> tags)
    {
        string res = "";
        for (uint i = 0; i < tags.Length; i++)
        {
            res += tags[i] + ",";
        }

        if (tags.Length > 0) res = res.SubStr(0, res.Length - 1);
        return res;
    }

    array<int> ConvertListToArray(string _tags)
    {
        array<int> res = {};
        int i = 0;
        while ((i = _tags.IndexOf(",")) > 0) {
            res.InsertLast(Text::ParseInt(_tags.SubStr(0, i)));
            _tags = _tags.SubStr(i + 1);
        }
        if (_tags != "") res.InsertLast(Text::ParseInt(_tags));
        return res;
    }

    array<string> ConvertStringToArray(const string &in str, const string &in separator = ",") {
        array<string> res = str.Split(separator);
        for (uint i = 0; i < res.Length; i++) {
            res[i] = res[i].ToLower();  // It does not look like TMX considers case when searching for author names, so we can just use lowercase
        }
        return res;
    }

}
