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

    bool authentified = false;
    bool authentificationInProgress = false;
    int authentificationAttempts = 0;
    int authentificationAttemptsMax = 10;
    int authentificationAttemptsDelay = 10000;
    string authentificationToken = "";
    Json::Value AuthState;

    array<Group@> groups;
    Group@ currentPlayerGroup;

    void CheckAuthentification()
    {
        authentificationInProgress = true;
        authentificationAttempts = 0;
        while (authentificationAttempts < authentificationAttemptsMax)
        {
            Log::Trace("[RMC Online Services] Authentification attempt " + authentificationAttempts);
            AuthState = API::GetAsync(API_URL + 'oauth/getUserStatus?userlogin=' + GetLocalLogin());
            Log::Trace("CheckAuthentification::Result: " + Json::Write(AuthState));
            if (AuthState.GetType() != Json::Type::Object) {
                Log::Error("[RMC Online Services] JSON is not an Object");
                authentificationAttemptsMax++;
                authentificationAttempts++;
                sleep(authentificationAttemptsDelay);
                continue;
            }
            if (AuthState["auth"]) {
                authentified = true;
                string tokenType = AuthState["tokenType"];
                string accessToken = AuthState["accessToken"];
                authentificationToken = tokenType + " " + accessToken;
                Log::Trace("auth token: " + authentificationToken);
                break;
            }
            else {
                authentificationAttempts++;
                if (authentificationAttempts+1 == authentificationAttemptsMax) sleep(authentificationAttemptsDelay);
            }
        }
        if (!authentified) {
            Log::Warn("[RMC Online Services] You're not authentified.", IS_DEV_MODE);
        } else {
            string displayName = AuthState["displayName"];
            Log::Log("[RMC Online Services] Authentification success, welcome "+displayName+"!", true);
        }
        authentificationInProgress = false;
    }

    void GetGroups()
    {
        Json::Value groupsJson = API::GetAsync(API_URL + 'groups/allGroups');
        if (groupsJson.GetType() != Json::Type::Array) {
            if (groupsJson.GetType() == Json::Type::Object) {
                string errorMessage = groupsJson["error"]["message"];
                Log::Error("[RMC Online Services] Error: " + errorMessage, true);
            } else {
                Log::Error("[RMC Online Services] JSON is invalid", true);
            }
            return;
        }
        for (uint i = 0; i < groupsJson.Length; i++) {
            string groupName = groupsJson[i]["name"];
            Log::Trace("Loading group " + groupName);
            Group@ group = Group(groupsJson[i]);
            groups.InsertLast(group);
            int playerGroupId = AuthState["groupId"];
            if (group.Id == playerGroupId) {
                @currentPlayerGroup = group;
            }
        }
        Log::Trace("[RMC Online Services] "+ groups.Length +" user groups loaded");
    }
}