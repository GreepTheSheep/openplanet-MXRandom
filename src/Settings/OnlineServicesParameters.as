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
        UI::TextWrapped("This plugin uses online services for the upcoming online modes on this plugin!");
        UI::NewLine();
        if (OnlineServices::isServerAvailable) {
            if (!OnlineServices::authenticated) {
                if (!OnlineServices::authenticationInProgress) {
                    UI::Text("You're not authenticated");
                    if (OnlineServices::authURL.Length > 0 && UI::Button(Icons::ExternalLink + " Authentificate")) {
                        OpenBrowserURL(OnlineServices::authURL);
                        startnew(OnlineServices::CheckAuthenticationButton);
                    }
                } else {
                    int HourGlassValue = Time::Stamp % 3;
                    string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                    UI::Text(Hourglass + " Authentication in progress...");
                    UI::Text("Attempt: " + tostring(OnlineServices::authenticationAttempts) + "/" + tostring(OnlineServices::authenticationAttemptsMax));
                }
            } else {
                string displayName = OnlineServices::userInfoAPI["displayName"];
                UI::Text("You're authenticated as " + displayName);
                if (UI::RedButton(Icons::ChainBroken + " Logout")) {
                    startnew(OnlineServices::Logout);
                }
            }
        } else {
            UI::Text("\\$f00" + Icons::Times + " \\$zServer is not available");
        }
        UI::Separator();
        if (OnlineServices::isServerAvailable) UI::Text("Server version: " + g_onlineServices.getServerVersion());
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

            if (!useCustomAPIURL) {
                useRescueHosts = UI::Checkbox("Use rescue hostname", useRescueHosts);
                UI::SetPreviousTooltip("In case of connection issues, use this.");
            }

            if (IS_DEV_MODE) {
                UI::Text("Session ID: " + OnlineServices::SessionId);
                UI::Text("Auth URL: " + OnlineServices::authURL);
                UI::Text("State: " + OnlineServices::state);
            }
            UI::TreePop();
        }
    }
}