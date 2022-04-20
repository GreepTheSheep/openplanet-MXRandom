namespace OnlineServices
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
    string API_URL = API_URLS[0];

    [Setting hidden]
    string SessionId = "";

    string authURL = "";
    string state = "";

    bool authenticated = false;
    bool authenticationInProgress = false;
    int authenticationAttempts = 0;
    int authenticationAttemptsMax = 10;
    int authenticationAttemptsDelay = 5000;
    string authenticationToken = "";
    Json::Value userInfoAPI;

    array<Group@> groups;
    Group@ currentPlayerGroup;

    // Workaround method for checkServer to ensure checkServer is only called when webId and playerLogin are not the equal
    void waitForValidWebId() {
        while (g_onlineService.network.PlayerInfo.Login == g_onlineService.network.PlayerInfo.WebServicesUserId) {
            sleep(50);
            yield();
        }

        g_onlineService.playerName = g_onlineService.network.PlayerInfo.Name;
        g_onlineService.playerLogin = g_onlineService.network.PlayerInfo.Login;
        g_onlineService.webId = g_onlineService.network.PlayerInfo.WebServicesUserId;
    }

    void CheckAuthenticationStartup()
    {
        authenticationInProgress = true;
        Json::Value AuthState = API::GetAsync(API_URL + 'oauth/getUserStatus?name=' + g_onlineService.playerName + '&login=' + g_onlineService.playerLogin + '&webid=' + g_onlineService.webId + '&sessionid=' + OnlineServices::SessionId + '&pluginVersion=' + g_onlineService.version);
        if (AuthState.GetType() != Json::Type::Object) {
            Log::Error("[RMC Online Services] JSON is not an Object");
            return;
        }
        if (AuthState.HasKey("error")) {
            string errorMessage = AuthState["error"]["message"];
            Log::Error("[RMC Online Services] " + errorMessage);
            return;
        }
        if (AuthState["auth"]) getMyUserStatus(true);
        else Log::Warn("[RMC Online Services] You're not authenticated.", IS_DEV_MODE);

        if (AuthState.HasKey("login")) authURL = AuthState["login"];
        if (AuthState.HasKey("state")) state = AuthState["state"];
        authenticationInProgress = false;
    }

    void CheckAuthenticationButton()
    {
        authenticationInProgress = true;
        authenticationAttempts = 0;
        while (authenticationAttempts < authenticationAttemptsMax)
        {
            Log::Trace("[RMC Online Services] Authentication attempt " + authenticationAttempts);
            Json::Value getSessionJson = API::GetAsync(API_URL + 'oauth/pluginSecret?state=' + state + '&pluginVersion=' + g_onlineService.version);
            if (getSessionJson.GetType() != Json::Type::Object) {
                Log::Error("[RMC Online Services] JSON is not an Object");
                break;
            }
            if (getSessionJson.HasKey("error")) {
                string errorMessage = getSessionJson["error"]["message"];
                Log::Error("[RMC Online Services] " + errorMessage);
                break;
            }
            if (getSessionJson.HasKey("sessionid")) {
                if (getSessionJson["sessionid"].GetType() != Json::Type::String) {
                    Log::Error("[RMC Online Services] session id is not a string");
                    authenticationAttempts++;
                    sleep(authenticationAttemptsDelay);
                    continue;
                }
                OnlineServices::SessionId = getSessionJson["sessionid"];
                OnlineServices::getMyUserStatus(true);
                break;
            } else {
                Log::Error("[RMC Online Services] session id not found");
                break;
            }
        }
        authenticationInProgress = false;
    }

    void getMyUserStatus(bool logAuthSuccess = true)
    {
        userInfoAPI = API::GetAsync(API_URL + 'users/me');
        if (userInfoAPI.GetType() != Json::Type::Object) {
            Log::Error("[RMC Online Services] JSON is not an Object");
            return;
        }
        if (userInfoAPI.HasKey("error")) {
            string errorMessage = userInfoAPI["error"]["message"];
            Log::Error("[RMC Online Services] " + errorMessage);
            return;
        }
        if (logAuthSuccess) {
            string displayName = userInfoAPI["displayName"];
            Log::Log("[RMC Online Services] Authentication success, welcome " + displayName + "!", true);
            authenticated = true;
        }
    }

    void Logout()
    {
        if (!authenticated)
        {
            Log::Warn("[RMC Online Services] You're not authenticated.", IS_DEV_MODE);
            return;
        }
        string logoutBody = "{\"sessionid\":\"" + OnlineServices::SessionId + "\"}";
        Net::HttpRequest@ req = API::Post(API_URL + "oauth/logout?pluginVersion=" + g_onlineService.version, logoutBody);
        while (!req.Finished()) {
            yield();
        }
        int status = req.ResponseCode();
        string response = req.String();
        if (status == 200) {
            Log::Log("[RMC Online Services] You're now logged out.", true);
            OnlineServices::SessionId = "";
            OnlineServices::authenticated = false;
            startnew(OnlineServices::CheckAuthenticationStartup);
        } else {
            Log::Error("[RMC Online Services] Logout failed, status code " + status, true);
            Log::Error("[RMC Online Services] " + response, false);
        }
    }
}