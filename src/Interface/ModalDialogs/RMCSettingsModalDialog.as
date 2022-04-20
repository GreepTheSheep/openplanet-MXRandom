class RMCSettingsModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    string resErrorString;
    Json::Value m_rulesJson;
    bool m_requestError = false;

    RMCSettingsModalDialog()
    {
        super(MX_COLOR_STR + Icons::Cog + " \\$zRandom Map Challenge");
        m_size = vec2(Draw::GetWidth()/2, Draw::GetHeight()/2);
        StartRulesRequest();
    }

    void RenderRulesContent()
    {
        if (m_request !is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        } else {
            if (m_requestError) {
                UI::Text("Error loading rules!");
                UI::TextDisabled(resErrorString);
                if (UI::Button("Retry")) {
                    StartRulesRequest();
                }
            } else {
                UI::BeginTabBar("RMCRulesTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
                if (UI::BeginTabItem(Icons::ClockO + " Random Map Challenge"))
                {
                    for (uint i = 0; i < m_rulesJson["challenge"].Length; i++) {
                        string rule = m_rulesJson["challenge"][i];
                        UI::Markdown("- " + rule);
                    }
                    UI::EndTabItem();
                }
                if (UI::BeginTabItem(Icons::Heart + " Random Map Survival"))
                {
                    for (uint i = 0; i < m_rulesJson["survival"].Length; i++) {
                        string rule = m_rulesJson["survival"][i];
                        UI::Markdown("- " + rule);
                    }
                    UI::EndTabItem();
                }
                UI::EndTabBar();
            }
        }
    }

    void StartRulesRequest()
    {
        string url = "https://openplanet.dev/plugin/mxrandom/config/user-rules";
        @m_request = API::Get(url);
    }

    void CheckRulesRequest()
    {
        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            Log::Trace("Rules::CheckRequest : " + res);
            auto json = Json::Parse(res);
            @m_request = null;

            if (json.GetType() != Json::Type::Object) {
                Log::Error("Rules::CheckRequest : Error parsing response");
                m_requestError = true;
                return;
            }

            if (json.HasKey("error")) {
                resErrorString = json["error"];
                Log::Error("Rules::CheckRequest : Error: " + resErrorString);
                m_requestError = true;
                return;
            }

            // Handle the response
            m_rulesJson = json;
        }
    }


    void RenderDialog() override
    {
        UI::BeginTabBar("RMCModalMainTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
        if (UI::BeginTabItem(Icons::InfoCircle + " Informations"))
        {
            RMC::RenderBaseInfos();
            CheckRulesRequest();
            RenderRulesContent();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::Cogs + " Settings##2"))
        {
            PluginSettings::RenderRMCSettingTab(true);
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }
}