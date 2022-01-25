#if MP4

const string MX_NAME            = "ManiaExchange";
const string SHORT_MX           = "MX";
const string MX_COLOR_STR       = "\\$39f";
const vec4   MX_COLOR_VEC       = vec4(0.2, 0.6, 1, 1);
const string MX_URL             = "tm.mania.exchange";
const string SUPPORTED_MAP_TYPE = "Race";

#elif TMNEXT

const string MX_NAME            = "TrackmaniaExchange";
const string SHORT_MX           = "TMX";
const string MX_COLOR_STR       = "\\$9fc";
const vec4   MX_COLOR_VEC       = vec4(0.3, 0.7, 0.4, 1);
const string MX_URL             = "trackmania.exchange";

const string SUPPORTED_MAP_TYPE = "TM_Race";
#endif

const string PLUGIN_NAME        = MX_NAME + " Random Map Picker";
const string GITHUB_URL         = "https://github.com/GreepTheSheep/openplanet-mx-random";

const string RecentlyPlayedJSON = IO::FromDataFolder("TMXRandom_PlayedMaps.json");
const string PluginDataJSON = IO::FromDataFolder("TMXRandom_Data.json");
