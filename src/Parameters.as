#if MP4
string name = "ManiaExchange Random Map Picker";
string shortMXName = "MX";
string MXColor = "\\$39f";
string gameName = "MP4";
string TMXURL = "tm.mania.exchange";
#elif TMNEXT
string name = "TrackmaniaExchange Random Map Picker";
string shortMXName = "TMX";
string MXColor = "\\$9fc";
string gameName = "TMNEXT";
string TMXURL = "trackmania.exchange";
#endif

string RecentlyPlayedJSON = IO::FromDataFolder("TMXRandom_PlayedMaps.json");