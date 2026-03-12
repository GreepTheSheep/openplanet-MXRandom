namespace PluginSettings {
    array<string> MapAuthorNamesArr = {};

    array<string> ExcludedTermsArr = {};

    array<string> ExcludedAuthorsArr = {};

    [Setting hidden]
    bool UseCustomLength = false;

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
    string ExcludeMapTags = "6,10,23,37,40,46,49";
    array<int> ExcludeMapTagsArr = {6, 10, 23, 37, 40, 46, 49};
#else
    string ExcludeMapTags = "6,10,20,39";
    array<int> ExcludeMapTagsArr = {6, 10, 20, 39};
#endif

    bool initArrays = false;

    [Setting hidden]
    bool TagInclusiveSearch = false;

    [Setting hidden]
    string Vehicles = "";
    array<string> VehiclesArr = {};

    [Setting hidden]
    string Environments = "";
    array<int> EnvironmentsArr = {};

    [Setting hidden]
    int MinRecords = 0;

    [Setting hidden]
    int MaxRecords = 0;

    [Setting hidden]
    string Difficulties = "";
    array<int> DifficultiesArray = {};

    [Setting hidden]
    MapTypes MapType = MapTypes::Race;

    [SettingsTab name="Filters" order="2" icon="Filter"]
    void RenderSearchingSettingTab() {
        bool inSameLine = UI::GetContentRegionAvail().x > 950;

        if (UI::OrangeButton("Reset to default")) {
            UseCustomLength = false;
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
            Vehicles = "";
            Environments = "";
            MapPackID = 0;
            MapTagsArr = {};
            VehiclesArr = {};
            EnvironmentsArr = {};
            MapAuthorNamesArr = {};
            ExcludedTermsArr = {};
            ExcludedAuthorsArr = {};
            DifficultiesArray = {};
            MinRecords = 0;
            MaxRecords = 0;
            TermsExactMatch = false;
            MapType = MapTypes::Race;
#if TMNEXT
            ExcludeMapTagsArr = {6, 10, 23, 37, 40, 46, 49};
#else
            ExcludeMapTagsArr = {6, 10, 20, 39};
#endif
        }
    
        UI::PaddedHeaderSeparator("Length");

        UseCustomLength = UI::Checkbox("Use custom length range for map search", UseCustomLength);

        UI::BeginDisabled(!UseCustomLength);

        UI::SetItemText("From:");
        MinLength = UI::InputInt("##FromLengthFilter", MinLength, 0);
#if TMNEXT
        UI::SettingDescription("Minimum duration of the map, based on the author medal, in milliseconds.\n\nCan also be used for respawns (Platform) and points (Stunt).");
#else
        UI::SettingDescription("Minimum duration of the map, based on the author medal, in milliseconds.");
#endif

        if (MinLength != 0 && UI::ResetButton()) {
            MinLength = 0;
        }

        if (inSameLine) {
            UI::SetCenteredItemText("To:");
        } else {
            UI::BeginDisabled();

            UI::SetItemText("Time:");
            UI::Text(Time::Format(MinLength));
            UI::EndDisabled();

            UI::SetItemText("To:");
        }

        MaxLength = UI::InputInt("##ToLengthFilter", MaxLength, 0);
#if TMNEXT
        UI::SettingDescription("Maximum duration of the map, based on the author medal, in milliseconds.\n\nCan also be used for respawns (Platform) and points (Stunt).");
#else
        UI::SettingDescription("Maximum duration of the map, based on the author medal, in milliseconds.");
#endif

        if (MaxLength != 0 && UI::ResetButton()) {
            MaxLength = 0;
        }

        UI::EndDisabled();

        UI::BeginDisabled();

        if (inSameLine) {
            UI::SetItemText("Time:");
            UI::Text(Time::Format(MinLength));

            UI::SetCenteredItemText("Time:");
            UI::Text(Time::Format(MaxLength));
        } else {
            UI::SetItemText("Time:");
            UI::Text(Time::Format(MaxLength));
        }

        UI::EndDisabled();

        UI::PaddedHeaderSeparator("Date");

        UseDateInterval = UI::Checkbox("Use date interval for map search", UseDateInterval);

        UI::BeginDisabled(!UseDateInterval);

        UI::SetItemText("From:");
        FromDate = UI::InputText("##FromDateFilter", FromDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SettingDescription("Minimum date when the map was uploaded to " + SHORT_MX + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if ((!UI::IsItemActive() && !Date::IsValid(FromDate)) || (FromDate != releaseDate && UI::ResetButton())) {
            FromDate = releaseDate;
        }

        UI::SetItemText("To:", 300, inSameLine);

        ToDate = UI::InputText("##ToDateFilter", ToDate, UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::DateCallback);
        UI::SettingDescription("Maximum date when the map was uploaded to " + SHORT_MX + ", formatted as YYYY-MM-DD.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Different formats won't work / will give unexpected results!");

        if ((!UI::IsItemActive() && !Date::IsValid(ToDate)) || (ToDate != currentDate && UI::ResetButton())) {
            ToDate = currentDate;
        }

        UI::EndDisabled();
        
        UI::PaddedHeaderSeparator("Map");

        UI::SetItemText("Map Name Filter:");
        MapName = UI::InputText("##MapName", MapName);
        UI::SettingDescription("Search maps by their name. When using multiple keywords, they must be comma-separated.\n\n\\$f80" + Icons::ExclamationTriangle + " \\$zNote: All words will have the same weight!");

        if (MapName != "" && UI::ResetButton()) {
            MapName = "";
        }

        UI::SetItemText("Map Author Filter:", 300, inSameLine);

        MapAuthor = UI::InputText("##AuthorFilter", MapAuthor);
        UI::SettingDescription("Search authors by their MX username. When filtering multiple authors, they must be comma-separated.\n\n\\$f80" + Icons::ExclamationTriangle + " \\$zNote: All authors will have the same weight, regardless of their map count on MX!");

        if (MapAuthor != "" && UI::ResetButton()) {
            MapAuthor = "";
        }

        UI::SetItemText("Excluded term(s):");
        ExcludedTerms = UI::InputText("##ExcludedTerms", ExcludedTerms);
        UI::SettingDescription("Filter out maps that contain specific words/phrases in their name.\nFor example, you can filter out \"slop\", \"yeet\", or \"random generated\".\n\nWhen filtering multiple terms, they must be comma-separated.");

        if (ExcludedTerms != "" && UI::ResetButton()) {
            ExcludedTerms = "";
        }

        UI::SameLine();

        TermsExactMatch = UI::Checkbox("Exact match", TermsExactMatch);
        UI::SettingDescription("If enabled, terms will only be excluded when there's an exact match.\n\nExample: If you exclude the word \"AI\", it won't filter out maps with the words \"Air\" or \"Fail\".");

        UI::SetItemText("Excluded Author(s):", 300, inSameLine);

        ExcludedAuthors = UI::InputText("##ExcludedAuthors", ExcludedAuthors);
        UI::SettingDescription("Exclude authors by their MX username.\n\nWhen filtering multiple authors, they must be comma-separated.");

        if (ExcludedAuthors != "" && UI::ResetButton()) {
            ExcludedAuthors = "";
        }

        UI::SetItemText("Map Pack ID:");
        // Using InputText instead of a InputInt because it looks better and using "" as empty value instead of 0 for consistency with the other fields
        MapPackID = Text::ParseInt64(UI::InputText("##MappackId", MapPackID != 0 ? tostring(MapPackID) : "", UI::InputTextFlags::AutoSelectAll | UI::InputTextFlags::CharsDecimal | UI::InputTextFlags::CallbackAlways | UI::InputTextFlags::CallbackCharFilter, UI::MXIdCallback));

        if (MapPackID != 0 && UI::ResetButton()) {
            MapPackID = 0;
        }

        MapAuthorNamesArr = ConvertStringToArray(MapAuthor);
        ExcludedTermsArr = ConvertStringToArray(ExcludedTerms);
        ExcludedAuthorsArr = ConvertStringToArray(ExcludedAuthors);

        if (!initArrays) {
            MapTagsArr = ConvertListToArray(MapTags);
            ExcludeMapTagsArr = ConvertListToArray(ExcludeMapTags);
            DifficultiesArray = ConvertListToArray(Difficulties);
            EnvironmentsArr = ConvertListToArray(Environments);
            VehiclesArr = ConvertStringToArray(Vehicles);
            initArrays = true;
        }

        UI::PaddedHeaderSeparator("Tags");

        if (UI::BeginTable("tags", 2, UI::TableFlags::SizingFixedFit)) {
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text("Include" + (MapTagsArr.IsEmpty() ? "" : " (" + MapTagsArr.Length + " selected)"));
            UI::TableNextColumn();
            UI::AlignTextToFramePadding();
            UI::Text("Exclude" + (ExcludeMapTagsArr.IsEmpty() ? "" : " (" + ExcludeMapTagsArr.Length + " selected)"));

            UI::TableNextColumn();
            if (UI::BeginListBox("##Include Tags", vec2(200, 300))) {
                for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                    MX::MapTag@ tag = MX::m_mapTags[i];
                    if (UI::Selectable(tag.Name, MapTagsArr.Find(tag.ID) >= 0)) MapTagsArr = ToggleMapTag(MapTagsArr, tag.ID);
                }

                UI::EndListBox();
            }

            UI::TableNextColumn();
            if (UI::BeginListBox("##Exclude Tags", vec2(200, 300))) {
                for (uint i = 0; i < MX::m_mapTags.Length; i++) {
                    MX::MapTag@ tag = MX::m_mapTags[i];
                    if (UI::Selectable(tag.Name, ExcludeMapTagsArr.Find(tag.ID) >= 0)) ExcludeMapTagsArr = ToggleMapTag(ExcludeMapTagsArr, tag.ID);
                }

                UI::EndListBox();
            }
            UI::EndTable();
        }

#if TMNEXT
        // TMX tags for their respective map types
        if (
            (MapType == MapTypes::Stunt && ExcludeMapTagsArr.Find(16) >= 0)
            || (MapType == MapTypes::Platform && ExcludeMapTagsArr.Find(18) >= 0)
            || (MapType == MapTypes::Royal && ExcludeMapTagsArr.Find(37) >= 0)
        ) {
            Controls::BeginFrameWarning("\\$f90" + Icons::ExclamationTriangle + " \\$z" + tostring(MapType) + " tag excluded while searching for " + tostring(MapType) + " maps.");
            UI::TextWrapped("It's recommended to not exclude this tag when searching for " + tostring(MapType) + " maps, as it will greatly reduce the map pool available.");
            Controls::EndFrame();
        }
#endif

        TagInclusiveSearch = UI::Checkbox("Tag inclusive search", TagInclusiveSearch);
        UI::SettingDescription("If enabled, maps must contain all selected tags.");

        MapTags = ConvertArrayToList(MapTagsArr);
        ExcludeMapTags = ConvertArrayToList(ExcludeMapTagsArr);

#if TMNEXT
        UI::PaddedHeaderSeparator("Vista / Vehicle");

        UI::SetItemText("Vistas:", 250);
#else
        UI::PaddedHeaderSeparator("Environment / Vehicle");

        UI::SetItemText("Environments:", 250);
#endif

        string enviText;
        switch (EnvironmentsArr.Length) {
            case 0: enviText = "Any"; break;
            case 1: enviText = tostring(MX::Environments(EnvironmentsArr[0])).Replace("_", " "); break;
            default: enviText = tostring(EnvironmentsArr.Length) + " selected"; break;
        }

        if (UI::BeginCombo("###EnvironmentFilter", enviText)) {
            for (uint i = 1; i < MX::Environments::Last; i++) {
                MX::Environments envi = MX::Environments(i);

#if MP4
                // Skip environments not available yet
                if (envi >= MX::Environments::Rally && envi <= MX::Environments::Bay) {
                    continue;
                }
#endif
    
                UI::PushID("EnvironmentBtn" + i);

                bool inArray = EnvironmentsArr.Find(envi) != -1;

                if (UI::Checkbox(tostring(envi).Replace("_", " "), inArray)) {
                    if (!inArray) {
                        EnvironmentsArr.InsertLast(envi);
                    }
                } else if (inArray) {
                    EnvironmentsArr.RemoveAt(EnvironmentsArr.Find(envi));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        Environments = ConvertArrayToList(EnvironmentsArr);

        if (!EnvironmentsArr.IsEmpty() && UI::ResetButton()) {
            EnvironmentsArr.RemoveRange(0, EnvironmentsArr.Length);
        }

        UI::SetItemText("Vehicles:", 250, inSameLine);

        string vehicleText;
        switch (VehiclesArr.Length) {
            case 0: vehicleText = "Any"; break;
            case 1: vehicleText = VehiclesArr[0]; break;
            default: vehicleText = tostring(VehiclesArr.Length) + " selected"; break;
        }

        if (UI::BeginCombo("##VehicleFilter", vehicleText)) {
            for (uint i = 0; i < MX::m_vehicles.Length; i++) {
                string vehicleName = MX::m_vehicles[i];

                UI::PushID("VehicleBtn" + i);

                bool inArray = VehiclesArr.Find(vehicleName) != -1;

                if (UI::Checkbox(vehicleName, inArray)) {
                    if (!inArray) {
                        VehiclesArr.InsertLast(vehicleName);
                    }
                } else if (inArray) {
                    VehiclesArr.RemoveAt(VehiclesArr.Find(vehicleName));
                }

                UI::PopID();
            }

            UI::EndCombo();
        }

        if (!VehiclesArr.IsEmpty() && UI::ResetButton()) {
            VehiclesArr.RemoveRange(0, VehiclesArr.Length);
        }

#if TMNEXT
        UI::SettingDescription("\\$f90" + Icons::ExclamationTriangle + "\\$z This will filter by the base vehicle used by the map, it won't include maps that use car triggers instead.\n\nTo include those maps, consider filtering by tags instead.");
#endif

        Vehicles = string::Join(VehiclesArr, ",");

#if TMNEXT
        UI::PaddedHeaderSeparator("Records");

        UI::SetItemText("Min:", 250);
        MinRecords = UI::InputInt("##MinRecordsFilter", MinRecords, 0);
        UI::SettingDescription("Minimum amount of online records on the map.\n\nNote: Count might be delayed / inaccurate depending on the map.");

        if (MinRecords != 0 && UI::ResetButton()) {
            MinRecords = 0;
        }

        UI::SetItemText("Max:", 250, inSameLine);
        MaxRecords = UI::InputInt("##MaxRecordsFilter", MaxRecords, 0);
        UI::SettingDescription("Maximum amount of online records on the map.\n\nNote: Count might be delayed / inaccurate depending on the map.");

        if (MaxRecords != 0 && UI::ResetButton()) {
            MaxRecords = 0;
        }
#endif

        UI::PaddedHeaderSeparator("Other");

        string difficultyText;
        switch (DifficultiesArray.Length) {
            case 0: difficultyText = "Any"; break;
            case 1: difficultyText = tostring(MX::Difficulties(DifficultiesArray[0])); break;
            default: difficultyText = tostring(DifficultiesArray.Length) + " difficulties"; break;
        }

        UI::SetItemText("Difficulties:", 250);
        if (UI::BeginCombo("###DifficultyFilter", difficultyText)) {
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

#if TMNEXT
        UI::SetItemText("Map Type:", 250, inSameLine);
        if (UI::BeginCombo("##MapTypes", tostring(MapType))) {
            for (int i = 0; i < MapTypes::Last; i++) {
                if (UI::Selectable(tostring(MapTypes(i)), MapType == MapTypes(i))) {
                    MapType = MapTypes(i);
                }
            }

            UI::EndCombo();
        }

        UI::SettingDescription("The game mode of the map.\n\n\\$f90" + Icons::ExclamationTriangle + "\\$z Only Race will work online!");
#endif
    }

    array<int> ToggleMapTag(array<int> tags, int tagID) {
        int position = tags.Find(tagID);
        if (position >= 0) {
            tags.RemoveAt(position);
        } else {
            tags.InsertLast(tagID);
        }
        return tags;
    }

    string ConvertArrayToList(array<int> arr) {
        string res = "";
        for (uint i = 0; i < arr.Length; i++) {
            res += arr[i] + ",";
        }

        if (!arr.IsEmpty()) res = res.SubStr(0, res.Length - 1);
        return res;
    }

    array<int> ConvertListToArray(const string &in arrStr) {
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
                res[i] = res[i].Trim();
            }
        }
        return res;
    }
}
