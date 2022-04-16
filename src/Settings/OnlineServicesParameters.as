namespace PluginSettings
{

    array<string> API_URLS_BRANCHS = {
        "production",
        "staging"
    };

    array<string> API_URLS = {
        "https://rmcapi.greep.gq/",
        "https://rmcapi-dev.greep.gq/"
    };

    array<string> API_URLS_RESCUE = {
        "https://tm-rmc-prod.herokuapp.com/",
        "https://tm-rmc-staging.herokuapp.com/"
    };

    [Setting hidden]
    string selectedAPI = API_URLS_BRANCHS[0];

    string API_URL = API_URLS[0];

    [Setting hidden]
    bool useRescueHosts = false;

    [Setting hidden]
    bool useCustomAPIURL = false;

    [SettingsTab name="Online Services"]
    void RenderNetServicesSettings()
    {
        UI::PushFont(g_fontHeaderSub);
        UI::Text("Online Services");
        UI::PopFont();
        UI::TextWrapped("This plugin uses online services for the Random Map Race, and soon the leaderboard of the RMC/RMS");
        UI::Separator();
        if (UI::OrangeButton("Reset to default"))
        {
            selectedAPI = API_URLS_BRANCHS[0];
            API_URL = API_URLS[0];
            useRescueHosts = false;
            useCustomAPIURL = false;
        }
        if (UI::TreeNode("Advanced options")){
            if (!useCustomAPIURL) {
                if (IS_DEV_MODE && UI::BeginCombo("Backend Branch", selectedAPI)){
                    for (uint i = 0; i < API_URLS_BRANCHS.Length; i++) {
                        string branch = API_URLS_BRANCHS[i];

                        if (UI::Selectable(branch, selectedAPI == branch)) {
                            selectedAPI = branch;
                        }

                        if (selectedAPI == branch) {
                            UI::SetItemDefaultFocus();
                        }
                    }
                    UI::EndCombo();
                }

                if (!useRescueHosts) API_URL = API_URLS[API_URLS_BRANCHS.Find(selectedAPI)];
                else API_URL = API_URLS_RESCUE[API_URLS_BRANCHS.Find(selectedAPI)];
            } else {
                API_URL = UI::InputText("Custom API URL", API_URL);
            }

            useCustomAPIURL = UI::Checkbox("Use custom hostname", useCustomAPIURL);
            UI::SetPreviousTooltip("Use this if you know what are you doing.");

            useRescueHosts = UI::Checkbox("Use rescue hostnames", useRescueHosts);
            UI::SetPreviousTooltip("In case of connection issues, use this.");
            UI::TreePop();
        }
    }
}