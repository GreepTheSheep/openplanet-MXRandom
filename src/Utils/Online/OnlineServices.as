#if TMNEXT
namespace OnlineServices
{
    array<string> API_URLS_BRANCHS = {
        "production",
        "staging",
        "develop (localhost:3000)"
    };
    array<string> API_URLS = {
        "https://rmcapi.greep.gq/",
        "https://rmcapi-dev.greep.gq/",
        "http://localhost:3000/"
    };
    array<string> API_URLS_RESCUE = {
        "https://tm-rmc-prod.herokuapp.com/",
        "https://tm-rmc-staging.herokuapp.com/",
        "http://localhost:3000/"
    };

    [Setting hidden]
    string API_URL = API_URLS[0];

    [Setting hidden]
    string SessionId = "";

    string authURL = "";
    string state = "";

    bool authenticated = false;
    bool authenticationInProgress = false;
    bool isServerAvailable = false;
    int authenticationAttempts = 0;
    int authenticationAttemptsMax = 10;
    int authenticationAttemptsDelay = 5000;
    Json::Value userInfoAPI;

    // Workaround method for checkServer to ensure CheckAuthenticationStartup is only called when webId and playerLogin are not the equal
    void waitForValidWebId() {
        while (g_onlineServices.network.PlayerInfo.Login == g_onlineServices.network.PlayerInfo.WebServicesUserId) {
            sleep(50);
            yield();
        }

        g_onlineServices.playerName = g_onlineServices.network.PlayerInfo.Name;
        g_onlineServices.playerLogin = g_onlineServices.network.PlayerInfo.Login;
        g_onlineServices.webId = g_onlineServices.network.PlayerInfo.WebServicesUserId;
    }

    void checkServer()
    {
        g_onlineServices.serverInfo = API::GetAsync(API_URL);
        if (g_onlineServices.serverInfo.GetType() != Json::Type::Object) {
            isServerAvailable = false;
            Log::Error("[RMC Online Services] Server is not available");
            return;
        }
        isServerAvailable = true;
        Log::Trace("[RMC Online Services] Server is available");
        if (IS_DEV_MODE) Log::Trace(Json::Write(g_onlineServices.serverInfo));
    }

    void CheckAuthenticationStartup()
    {
        authenticationInProgress = true;
        Json::Value AuthState = API::GetAsync(API_URL + 'oauth/getUserStatus?name=' + g_onlineServices.playerName + '&login=' + g_onlineServices.playerLogin + '&webid=' + g_onlineServices.webId + '&sessionid=' + OnlineServices::SessionId + '&pluginVersion=' + g_onlineServices.version);
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
            Json::Value getSessionJson = API::GetAsync(API_URL + 'oauth/pluginSecret?state=' + state + '&pluginVersion=' + g_onlineServices.version);
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
        Net::HttpRequest@ req = API::Post(API_URL + "oauth/logout?pluginVersion=" + g_onlineServices.version, logoutBody);
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
#endif