#if MP4

const string MX_NAME                    = "ManiaExchange";
const string SHORT_MX                   = "MX";
const string MX_COLOR_STR               = "\\$39f";
const vec4   MX_COLOR_VEC               = vec4(0.2, 0.6, 1, 1);
const string MX_URL                     = "tm.mania.exchange";
const string SUPPORTED_MAP_TYPE         = "Race";

#elif TMNEXT

const string MX_NAME                    = "TrackmaniaExchange";
const string SHORT_MX                   = "TMX";
const string MX_COLOR_STR               = "\\$9fc";
const vec4   MX_COLOR_VEC               = vec4(0.3, 0.7, 0.4, 1);
const string MX_URL                     = "trackmania.exchange";
const string SUPPORTED_MAP_TYPE         = "TM_Race";
#endif

const string PLUGIN_NAME                = MX_NAME + " Random Map Picker";
const string PLUGIN_VERSION             = Meta::ExecutingPlugin().get_Version();
const array<string> PLUGIN_VERSION_SPLIT= PLUGIN_VERSION.Split(".");

const string GITHUB_REPO_FULLNAME       = "GreepTheSheep/openplanet-mx-random";
const string GITHUB_URL                 = "https://github.com/" + GITHUB_REPO_FULLNAME;

const bool IS_DEV_MODE                  = Meta::IsDeveloperMode();

const string DATA_JSON_LOCATION         = IO::FromDataFolder("MXRandom_Data.json");
Json::Value DataJson                    = Json::FromFile(DATA_JSON_LOCATION);
Json::Value DataJsonOldVersion          = Json::FromFile(IO::FromDataFolder("TMXRandom_Data.json"));