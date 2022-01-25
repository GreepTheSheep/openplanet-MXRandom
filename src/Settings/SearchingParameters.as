namespace PluginSettings
{
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
    string MapTag = "Anything";

    [Setting hidden]
    int MapTagID = 0;

    [SettingsTab name="Searching"]
    void RenderSearchingSettingTab()
    {
        UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$zKeep in mind that search parameters are disabled during Random Map Challenge due to their rules.");
        UI::NewLine();

        UI::Separator();

        if (UI::OrangeButton("Reset to default")){
            MapLengthOperator = SearchingMapLengthOperators[0];
            MapLength = SearchingMapLengths[0];
            MapTag = "Anything";
            MapTagID = 0;
        }
        UI::NewLine();

        UI::SetNextItemWidth(160);
        // Length Operator
        if (UI::BeginCombo("", MapLengthOperator)){
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

        UI::SetNextItemWidth(150);
        if (UI::BeginCombo("Tags", MapTag)){
            if (UI::Selectable("Anything", MapTag == "Anything")){
                MapTag = "Anything";
                MapTagID = 0;
                Log::Trace("Searching map tag reseted to Anything (" + MapTagID + ")");
            }
            for (uint i = 0; i < MX::m_mapTags.Length; i++)
            {
                MX::MapTag@ tag = MX::m_mapTags[i];
                if (UI::Selectable(tag.Name, MapTag == tag.Name)){
                    MapTag = tag.Name;
                    MapTagID = tag.ID;
                    Log::Trace("Searching map tag changed to " + MapTag + " (" + MapTagID + ")");
                }

                if (MapTag == tag.Name) {
                    UI::SetItemDefaultFocus();
                }
            }
            UI::EndCombo();
        }
    }
}
