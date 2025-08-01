namespace PluginSettings
{
    [Setting hidden]
    bool CustomRules = false;

    array<string> MapAuthorNamesArr = {};

    array<string> ExcludedTermsArr = {};

    array<string> ExcludedAuthorsArr = {};

    [Setting hidden]
    int MinLength = 0;

    [Setting hidden]
    int MaxLength = 0;

    [Setting hidden]
    string MapAuthor = "";

    [Setting hidden]
    string MapName = "";
    
    [Setting hidden]
    string ExcludedTerms = "";

    [Setting hidden]
    bool TermsExactMatch = false;

    [Setting hidden]
    string ExcludedAuthors = "";

    [Setting hidden]
    bool UseDateInterval = false;

#if TMNEXT
    const string releaseDate = "2020-01-01";
#else
    const string releaseDate = "2011-01-01";
#endif

    [Setting hidden]
    string FromDate = releaseDate;

    const string currentDate = Time::FormatString("%F", Time::Stamp);

    [Setting hidden]
    string ToDate = currentDate;

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

    [Setting hidden]
    string Difficulties = "";
    array<int> DifficultiesArray = {};

    [Setting hidden]
    bool SkipSeenMaps = false;

    [SettingsTab name="Searching" order="2" icon="Search"]
    void RenderSearchingSettingTab()
    {
        CustomRules = UI::Checkbox("\\$fc0"+Icons::ExclamationTriangle+" \\$zUse custom parameters. Forbidden on official leaderboards.", CustomRules);
        UI::Separator();

        UI::BeginDisabled(!CustomRules);

        if (UI::OrangeButton("Reset to default")) {
            MinLength = 0;
            MaxLength = 0;
            UseDateInterval = false;
            FromDate = releaseDate;
            ToDate = currentDate;
            TagInclusiveSearch = false;
            MapAuthor = "";
            ExcludedAuthors = "";
            MapName = "";
            ExcludedTerms = "";
            Difficulties = "";
            MapPackID = 0;
            MapTagsArr = {};
            MapAuthorNamesArr = {};
            ExcludedTermsArr = {};
            ExcludedAuthorsArr = {};
            DifficultiesArray = {};
            TermsExactMatch = false;
#if TMNEXT
            ExcludeMapTagsArr = {23, 37, 40};
#else
            ExcludeMapTagsArr = {20};
#endif
        }
    
        UI::PaddedHeaderSeparator("Length");

        UI::SetItemText("From:");
        MinLength = UI::InputInt("##FromLengthFilter", MinLength, 0);
        UI::SetItemTooltip("Minimum duration of the map, based on the author medal, in milliseconds.");

        if (MinLength != 0 && UI::ResetButton()) {
            MinLength = 0;
        }

        UI::SetCenteredItemText("To:");
        MaxLength = UI::InputInt("##ToLengthFilter", MaxLength, 0);
        UI::SetItemTooltip("Maximum duration of the map, based on the author medal, in milliseconds.");

        if (MaxLength != 0 && UI::ResetButton()) {
            MaxLength = 0;
        }

        UI::BeginDisabled();

        UI::SetItemText("Time:");
        UI::Text(Time::Format(MinLength));

        UI::SetCenteredItemText("Time:");
        UI::Text(Time::Format(MaxLength));

        UI::EndDisabled();

        UI::PaddedHeaderSeparator("Date");

        UseDateInterval = UI::Checkbox("Use date interval for map search", UseDateInterval);

        UI::BeginDisabled(!UseDateInterval);

        UI::SetItemText("From:");
        FromDate = UI::InputText("##FromDateFilter", FromDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::InputTextCallback(UI::DateCallback));
        UI::SetItemTooltip("Minimum date when the map was uploaded to " + SHORT_MX + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if ((!UI::IsItemActive() && !Date::IsValid(FromDate)) || (FromDate != releaseDate && UI::ResetButton())) {
            FromDate = releaseDate;
        }

        UI::SetCenteredItemText("To:");
        ToDate = UI::InputText("##ToDateFilter", ToDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::InputTextCallback(UI::DateCallback));
        UI::SetItemTooltip("Maximum date when the map was uploaded to " + SHORT_MX + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if ((!UI::IsItemActive() && !Date::IsValid(ToDate)) || (ToDate != currentDate && UI::ResetButton())) {
            ToDate = currentDate;
        }

        UI::EndDisabled();
        
        UI::PaddedHeaderSeparator("Map");

        UI::SetNextItemWidth(200);
        MapName = UI::InputText("Map Name Filter", MapName, false);

        if (MapName != "" && UI::ResetButton()) {
            MapName = "";
        }

        UI::SetNextItemWidth(200);
        ExcludedTerms = UI::InputText("Excluded term(s)", ExcludedTerms, false);
        UI::SetPreviousTooltip("Filter out maps that contain specific words/phrases in their name.\nFor example, you can filter out \"slop\", \"yeet\", or \"random generated\".\n\nWhen filtering multiple terms, they must be comma-separated.");

        if (ExcludedTerms != "" && UI::ResetButton()) {
            ExcludedTerms = "";
        }

        UI::SameLine();

        TermsExactMatch = UI::Checkbox("Exact match", TermsExactMatch);
        UI::SetPreviousTooltip("If enabled, terms will only be excluded when there's an exact match.\n\nExample: If you exclude the word \"AI\", it won't filter out maps with the words \"Air\" or \"Fail\".");

        UI::SetNextItemWidth(200);
        // Using InputText instead of a InputInt because it looks better and using "" as empty value instead of 0 for consistency with the other fields
        MapPackID = Text::ParseInt64(UI::InputText("Map Pack ID", MapPackID != 0 ? tostring(MapPackID) : "", UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::InputTextCallback(UI::MXIdCallback)));

        if (MapPackID != 0 && UI::ResetButton()) {
            MapPackID = 0;
        }

        UI::SetNextItemWidth(200);
        MapAuthor = UI::InputText("Map Author Filter", MapAuthor, false);

        if (MapAuthor != "" && UI::ResetButton()) {
            MapAuthor = "";
        }

        if (MapAuthor.Contains(",")) UI::TextWrapped("\\$f90" + Icons::ExclamationTriangle + " \\$z MX 2.0 doesn't support searching multiple authors yet. Only the first one will be included.");

        UI::SetNextItemWidth(200);
        ExcludedAuthors = UI::InputText("Excluded Author(s)", ExcludedAuthors, false);
        UI::SetPreviousTooltip("Exclude authors by their MX username.\n\nWhen filtering multiple authors, they must be comma-separated.");

        if (ExcludedAuthors != "" && UI::ResetButton()) {
            ExcludedAuthors = "";
        }

        MapAuthorNamesArr = ConvertStringToArray(MapAuthor);
        ExcludedTermsArr = ConvertStringToArray(ExcludedTerms);
        ExcludedAuthorsArr = ConvertStringToArray(ExcludedAuthors);

        if (!initArrays) {
            MapTagsArr = ConvertListToArray(MapTags);
            ExcludeMapTagsArr = ConvertListToArray(ExcludeMapTags);
            DifficultiesArray = ConvertListToArray(Difficulties);
            initArrays = true;
        }

        UI::PaddedHeaderSeparator("Tags");

        if (UI::BeginTable("tags", 2, UI::TableFlags::SizingFixedFit)) {
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text("Include" + (MapTagsArr.Length == 0 ? "" : " (" + MapTagsArr.Length + " selected)"));
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text("Exclude" + (ExcludeMapTagsArr.Length == 0 ? "" : " (" + ExcludeMapTagsArr.Length + " selected)"));

            UI::TableNextColumn();
            if (UI::BeginListBox("##Include Tags", vec2(200, 300))) {
                for (uint i = 0; i < MX::m_mapTags.Length; i++)
                {
                    MX::MapTag@ tag = MX::m_mapTags[i];
                    if (UI::Selectable(tag.Name, MapTagsArr.Find(tag.ID) >= 0)) MapTagsArr = ToggleMapTag(MapTagsArr, tag.ID);
                }
                UI::EndListBox();
            }

            UI::TableNextColumn();
            if (UI::BeginListBox("##Exclude Tags", vec2(200, 300))) {
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

        UI::PaddedHeaderSeparator("Other");

        string difficultyText;
        switch (DifficultiesArray.Length) {
            case 0: difficultyText = "Any"; break;
            case 1: difficultyText = tostring(MX::Difficulties(DifficultiesArray[0])); break;
            default: difficultyText = tostring(DifficultiesArray.Length) + " difficulties"; break;
        }

        UI::SetNextItemWidth(160);
        if (UI::BeginCombo("Difficulties###DifficultyFilter", difficultyText)) {
            for (uint i = 0; i <= MX::Difficulties::Impossible; i++) {
                UI::PushID("DifficultyBtn" + i);

                bool inArray = DifficultiesArray.Find(MX::Difficulties(i)) != -1;

                if (UI::Checkbox(tostring(MX::Difficulties(i)), inArray)) {
                    if (!inArray) {
                        DifficultiesArray.InsertLast(MX::Difficulties(i));
                    }
                } else if (inArray) {
                    DifficultiesArray.RemoveAt(DifficultiesArray.Find(MX::Difficulties(i)));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        if (!DifficultiesArray.IsEmpty() && UI::ResetButton()) {
            DifficultiesArray.RemoveRange(0, DifficultiesArray.Length);
        }

        Difficulties = ConvertArrayToList(DifficultiesArray);

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

    string ConvertArrayToList(array<int> arr)
    {
        string res = "";
        for (uint i = 0; i < arr.Length; i++)
        {
            res += arr[i] + ",";
        }

        if (arr.Length > 0) res = res.SubStr(0, res.Length - 1);
        return res;
    }

    array<int> ConvertListToArray(const string &in arrStr)
    {
        array<int> res = {};
        if (arrStr.Length == 0) return res;

        array<string> values = arrStr.Split(",");

        for (uint i = 0; i < values.Length; i++) {
            int n;

            if (values[i] != "" && Text::TryParseInt(values[i], n)) {
                res.InsertLast(n);
            }
        }

        return res;
    }

    array<string> ConvertStringToArray(const string &in str, const string &in separator = ",") {
        array<string> res = str.Split(separator);
        for (int i = int(res.Length) - 1; i >= 0; i--) {
            if (res[i] == "") {
                res.RemoveAt(i);
            } else {
                res[i] = res[i].ToLower().Trim();  // It does not look like TMX considers case when searching for author names, so we can just use lowercase
            }
        }
        return res;
    }

}
