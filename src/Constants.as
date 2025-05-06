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
const bool hasPermissions               = OpenplanetHasPaidPermissions();
#endif

const string PLUGIN_NAME                = MX_NAME + " Random Map Picker";
const string PLUGIN_VERSION             = Meta::ExecutingPlugin().Version;
const array<string> PLUGIN_VERSION_SPLIT= PLUGIN_VERSION.Split(".");

const string GITHUB_REPO_FULLNAME       = "GreepTheSheep/openplanet-mx-random";
const string GITHUB_URL                 = "https://github.com/" + GITHUB_REPO_FULLNAME;

#if FORCE_NO_DEV
const bool IS_DEV_MODE                  = false;
#else
const bool IS_DEV_MODE                  = Meta::IsDeveloperMode();
#endif

const string DATA_JSON_LOCATION         = IO::FromStorageFolder("MXRandom_Data.json");
const string SAVE_DATA_LOCATION         = DATA_JSON_LOCATION.Replace("MXRandom_Data.json", "Saves/");
Json::Value DataJson                    = Json::FromFile(DATA_JSON_LOCATION);
Json::Value DataJsonOldVersion          = Json::FromFile(IO::FromDataFolder("TMXRandom_Data.json"));
const string DATA_JSON_LOCATION_DATADIR = IO::FromDataFolder("MXRandom_Data.json");
Json::Value DataJsonFromDataFolder      = Json::FromFile(DATA_JSON_LOCATION_DATADIR);
const string MX_V1_BACKUP_LOCATION      = IO::FromStorageFolder("Old/");

const array<string> MAP_FIELDS_ARRAY = {
	"MapId",
	"MapUid",
	"OnlineMapId",
	"Uploader.UserId",
	"Uploader.Name",
	"MapType",
	"UploadedAt",
	"UpdatedAt",
	"Name",
	"GbxMapName",
	"TitlePack",
	"Length",
	"Medals.Author",
	"AwardCount",
	"ServerSizeExceeded",
	"Tags",
	"Exebuild"
};
const string MAP_FIELDS = string::Join(MAP_FIELDS_ARRAY, ",");
