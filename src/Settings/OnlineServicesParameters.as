namespace PluginSettings
{
    [Setting hidden]
    string selectedAPI = OnlineServices::API_URLS_BRANCHS[0];

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
        UI::TextWrapped("This plugin uses online services for the Random Map Race and other online modes coming soon!");
        UI::NewLine();
        if (!OnlineServices::authentified) {
            if (!OnlineServices::authentificationInProgress) {
                UI::Text("You're not authentified");
                if (UI::Button("Authentificate")) {
                    OpenBrowserURL(OnlineServices::API_URL + "oauth/login?userlogin=" + GetLocalLogin());
                    startnew(OnlineServices::CheckAuthentification);
                }
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Authentification in progress...");
                UI::Text("Attempt: " + tostring(OnlineServices::authentificationAttempts) + "/" + tostring(OnlineServices::authentificationAttemptsMax));
            }
        } else {
            string displayName = OnlineServices::AuthState["displayName"];
            UI::Text("You're logged in as " + displayName);
        }
        UI::Separator();
        if (UI::TreeNode("Advanced options")){
            if (UI::OrangeButton("Reset to default"))
            {
                selectedAPI = OnlineServices::API_URLS_BRANCHS[0];
                OnlineServices::API_URL = OnlineServices::API_URLS[0];
                useRescueHosts = false;
                useCustomAPIURL = false;
            }
            if (!useCustomAPIURL) {
                if (IS_DEV_MODE && UI::BeginCombo("Backend Branch", selectedAPI)){
                    for (uint i = 0; i < OnlineServices::API_URLS_BRANCHS.Length; i++) {
                        string branch = OnlineServices::API_URLS_BRANCHS[i];

                        if (UI::Selectable(branch, selectedAPI == branch)) {
                            selectedAPI = branch;
                        }

                        if (selectedAPI == branch) {
                            UI::SetItemDefaultFocus();
                        }
                    }
                    UI::EndCombo();
                }

                if (!useRescueHosts) OnlineServices::API_URL = OnlineServices::API_URLS[OnlineServices::API_URLS_BRANCHS.Find(selectedAPI)];
                else OnlineServices::API_URL = OnlineServices::API_URLS_RESCUE[OnlineServices::API_URLS_BRANCHS.Find(selectedAPI)];
            } else {
                OnlineServices::API_URL = UI::InputText("Custom API URL", OnlineServices::API_URL);
            }

            useCustomAPIURL = UI::Checkbox("Use custom hostname", useCustomAPIURL);
            UI::SetPreviousTooltip("Use this if you know what are you doing.");

            useRescueHosts = UI::Checkbox("Use rescue hostname", useRescueHosts);
            UI::SetPreviousTooltip("In case of connection issues, use this.");
            UI::TreePop();
        }
    }
}