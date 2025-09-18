class RMCRulesModalDialog : ModalDialog {
    Net::HttpRequest@ m_request;
    string resErrorString;
    Json::Value m_rulesJson;
    bool m_requestError = false;

    RMCRulesModalDialog() {
        super(MX_COLOR_STR + Icons::Book + " \\$zRandom Map Challenge Rules");
        m_size = vec2(Draw::GetWidth() / 2, 600);
        StartRulesRequest();
    }

    void RenderRulesContent() {
        if (m_request !is null) {
            UI::Text(Icons::AnimatedHourglass + " Loading...");
        } else {
            if (m_requestError) {
                UI::Text("Error loading rules!");
                UI::TextDisabled(resErrorString);

                if (UI::Button("Retry")) {
                    StartRulesRequest();
                }
            } else {
                UI::BeginTabBar("RMCRulesTabBar", UI::TabBarFlags::FittingPolicyResizeDown);

                UI::PushTextWrapPos(UI::GetWindowContentRegionWidth());

                array<string> rules;

                if (UI::BeginTabItem("General")) {
                    for (uint i = 0; i < m_rulesJson["general"].Length; i++) {
                        rules.InsertLast("- " + string(m_rulesJson["general"][i]));
                    }

                    UI::Markdown(string::Join(rules, "\n\n"));
                    UI::EndTabItem();
                }

                if (UI::BeginTabItem(Icons::ClockO + " Random Map Challenge")) {
                    for (uint i = 0; i < m_rulesJson["challenge"].Length; i++) {
                        rules.InsertLast("- " + string(m_rulesJson["challenge"][i]));
                    }

                    UI::Markdown(string::Join(rules, "\n\n"));
                    UI::EndTabItem();
                }

                if (UI::BeginTabItem(Icons::Heart + " Random Map Survival")) {
                    for (uint i = 0; i < m_rulesJson["survival"].Length; i++) {
                        rules.InsertLast("- " + string(m_rulesJson["survival"][i]));
                    }

                    UI::Markdown(string::Join(rules, "\n\n"));
                    UI::EndTabItem();
                }

                if (UI::BeginTabItem(Icons::Trophy + " Random Map Objective")) {
                    for (uint i = 0; i < m_rulesJson["objective"].Length; i++) {
                        rules.InsertLast("- " + string(m_rulesJson["objective"][i]));
                    }

                    UI::Markdown(string::Join(rules, "\n\n"));
                    UI::EndTabItem();
                }

                UI::PopTextWrapPos();

                UI::EndTabBar();
            }
        }
    }

    void StartRulesRequest() {
        string url = "https://openplanet.dev/plugin/mxrandom/config/user-rules";
        @m_request = API::Get(url);
    }

    void CheckRulesRequest() {
        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            auto json = m_request.Json();
            @m_request = null;

            Log::Trace("[Rules::CheckRequest] Response: " + res);

            if (json.GetType() != Json::Type::Object) {
                Log::Error("[Rules::CheckRequest] Error parsing response");
                m_requestError = true;
                return;
            }

            if (json.HasKey("error")) {
                resErrorString = json["error"];
                Log::Error("[Rules::CheckRequest] Error: " + resErrorString);
                m_requestError = true;
                return;
            }

            // Handle the response
            m_rulesJson = json;
        }
    }


    void RenderDialog() override {
        RMC::RenderBaseInfo();
        CheckRulesRequest();
        RenderRulesContent();
    }
}