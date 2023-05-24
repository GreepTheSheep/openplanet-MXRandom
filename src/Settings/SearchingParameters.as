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

    [Setting hidden]
    string MapLength = SearchingMapLengths[0];

    [Setting hidden]
    string MapTags = "";
    array<int> MapTagsArr = {};

    [Setting hidden]
#if TMNEXT
    string ExcludeMapTags = "25,37,40";
    array<int> ExcludeMapTagsArr = {23, 37, 40};
#else
    string ExcludeMapTags = "20";
    array<int> ExcludeMapTagsArr = {20};
#endif

    bool initArrays = false;

    [Setting hidden]
    bool TagInclusiveSearch = false;

    [SettingsTab name="Searching"]
    void RenderSearchingSettingTab()
    {
        CustomRules = UI::Checkbox("\\$fc0"+Icons::ExclamationTriangle+" \\$zAllow search parameters in RMC. Forbidden on official Leaderboard.", CustomRules);
        UI::NewLine();

        UI::Separator();

        if (UI::OrangeButton("Reset to default")){
            MapLengthOperator = SearchingMapLengthOperators[0];
            MapLength = SearchingMapLengths[0];
            TagInclusiveSearch = false;
            MapTagsArr = {};
#if TMNEXT
            ExcludeMapTagsArr = {23, 37, 40};
#else
            ExcludeMapTagsArr = {20};
#endif
        }
        UI::NewLine();

        UI::SetNextItemWidth(160);
        // Length Operator
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

        if (!initArrays) {
            MapTagsArr = ConvertListToArray(MapTags);
            ExcludeMapTagsArr = ConvertListToArray(ExcludeMapTags);
            initArrays = true;
        }

        if (UI::BeginTable("tags", 2, UI::TableFlags::SizingFixedFit)) {
            UI::TableNextColumn();
            UI::Text("Include Tags");
            UI::TableNextColumn();
            UI::Text("Exclude Tags");

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

        MapTags = ConvertArrayToList(MapTagsArr);
        ExcludeMapTags = ConvertArrayToList(ExcludeMapTagsArr);
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

    array<int> ConvertListToArray(string tags)
    {
        array<int> res = {};
        int i = 0;
        while ((i = tags.IndexOf(",")) > 0) {
            res.InsertLast(Text::ParseInt(tags.SubStr(0, i)));
            tags = tags.SubStr(i + 1);
        }
        if (tags != "") res.InsertLast(Text::ParseInt(tags));
        return res;
    }

}
