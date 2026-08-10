class CustomParameters {
    array<array<string>> m_parameters;

    CustomParameters() {}

    CustomParameters(Json::Value@ json) {
        LoadJson(json);
    }

    void RemoveAll() {
        m_parameters.RemoveRange(0, m_parameters.Length);
    }

    Json::Value@ ToJson() {
        Json::Value@ json = Json::Array();

        for (uint i = 0; i < m_parameters.Length; i++) {
            if (m_parameters[i].Length != 2) {
                continue;
            }

            Json::Value@ fieldValue = Json::Array();

            fieldValue.Add(m_parameters[i][0]);
            fieldValue.Add(m_parameters[i][1]);

            json.Add(fieldValue);
        }

        return json;
    }

    void LoadJson(Json::Value@ json) {
        if (json.GetType() != Json::Type::Array) {
            Log::Warn("Invalid JSON type received for API fields! Expected Array, received " + tostring(json.GetType()));
            return;
        }

        for (uint i = 0; i < json.Length; i++) {
            if (json[i].GetType() != Json::Type::Array || json[i].Length != 2) {
                continue;
            }

            string parameter = json[i][0];
            string value = json[i][1];

            if (parameter != "" && value != "") {
                m_parameters.InsertLast({ parameter, value });
            }
        }
    }

    void AddToDictionary(dictionary@ params) {
        for (uint i = 0; i < m_parameters.Length; i++) {
            if (m_parameters[i].Length != 2) {
                continue;
            }

            string parameter = m_parameters[i][0];
            string value = m_parameters[i][1];

            if (parameter != "" && value != "") {
                params.Set(parameter, value);
            }
        }
    }

    void Render(bool wide = true) {
        UI::PushFontSize(18);

        UI::Text("Parameter");

        UI::SameLine();
        UI::CenterAlign();

        UI::Text("Value");

        UI::PopFontSize();

        UI::Separator();

        for (uint i = 0; i < m_parameters.Length; i++) {
            UI::SetNextItemWidth(wide ? 250 : 150);
            m_parameters[i][0] = UI::InputText("##Parameter" + i, m_parameters[i][0]);

            UI::SameLine();
            UI::CenterAlign();

            UI::SetNextItemWidth(wide ? 250 : 150);
            m_parameters[i][1] = UI::InputText("##Value" + i, m_parameters[i][1]);

            UI::SameLine();

            if (UI::RedButton(Icons::TrashO + "##" + i)) {
                m_parameters.RemoveAt(i);
            }

            if (i < m_parameters.Length - 1) UI::NewLine();
        }

        if (UI::GreenButton(Icons::Plus + " New parameter")) {
            m_parameters.InsertLast({"", ""});
        }
    }
}
