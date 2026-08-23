namespace MX {
    class MapInfo {
        int MapId;
        string MapUid;
        string OnlineMapId;
        int UserId;
        string Username;
        string MapType;
        string ExeBuild;
        string UploadedAt;
        string UpdatedAt;
        int UploadedAtTimestamp;
        int UpdatedAtTimestamp;
        int PlayedAt;
        string Name;
        string GbxMapName;
        string TitlePack;
        string Vehicle = "Unknown";
        int Environment = -1;
        int AuthorTime;
        int GoldTime;
        int SilverTime;
        int BronzeTime;
        int AwardCount;
        int Length;
        bool ServerSizeExceeded;
        bool AuthorBeaten;
        bool AuthorBeatable = true;
        int OnlineRecordCount = 0;
        array<MapTag@> Tags;
        int OnlineWRTime;
        string OnlineWRName = "Unknown";
        Json::Value@ jsonCache;
        PrepatchMapTag@ PrepatchTag;

        // Stats
        int Attempts = 0;
        int TimeSpent;
        int SessionPB;
        int GoalTime;
        RMC::MapResult Result;
        string PlayerName; // for RMT
        int TimerStart;
        int TimerEnd;
        bool Highlighted;

        bool CountAttempts = true;

        MapInfo(const Json::Value &in json) {
            try {
                MapId = json["MapId"];
                MapUid = json["MapUid"];
                if (json["OnlineMapId"].GetType() != Json::Type::Null) OnlineMapId = json["OnlineMapId"];
                Name = Format::GbxText(json["Name"]);
                MapType = json["MapType"];
                ExeBuild = json["Exebuild"];
                UploadedAt = json["UploadedAt"];
                if (json["GbxMapName"].GetType() != Json::Type::Null) GbxMapName = Format::GbxText(json["GbxMapName"]);
                if (json["TitlePack"].GetType() != Json::Type::Null) TitlePack = json["TitlePack"];
                AwardCount = json["AwardCount"];
                ServerSizeExceeded = json["ServerSizeExceeded"];

                if (json.HasKey("PlayedAt") && json["PlayedAt"].GetType() != Json::Type::Null) PlayedAt = json["PlayedAt"];
                else PlayedAt = Time::Stamp;

                OnlineRecordCount = json.Get("OnlineRecordCount", OnlineRecordCount);
                AuthorBeaten = json.Get("AuthorBeaten", AuthorBeaten);
                AuthorBeatable = json.Get("AuthorBeatable", AuthorBeatable);
                Vehicle = json.Get("VehicleName", Vehicle);
                Environment = json.Get("Environment", Environment);

#if TMNEXT
                if (json.HasKey("OnlineWR") && json["OnlineWR"].GetType() != Json::Type::Null && json["OnlineWR"]["RecordTime"].GetType() != Json::Type::Null) {
                    OnlineWRTime = json["OnlineWR"]["RecordTime"];

                    if (json["OnlineWR"]["DisplayName"].GetType() != Json::Type::Null) {
                        OnlineWRName = json["OnlineWR"]["DisplayName"];
                    }
                }
#endif

                if (json["UpdatedAt"].GetType() != Json::Type::Null) {
                    UpdatedAt = json["UpdatedAt"];
                } else {
                    UpdatedAt = json["UploadedAt"];
                }

                try {
                    UploadedAtTimestamp = Time::ParseFormatString('%FT%T', this.UploadedAt);
                    UpdatedAtTimestamp = Time::ParseFormatString('%FT%T', this.UpdatedAt);
                } catch {
                    UploadedAtTimestamp = 0;
                    UpdatedAtTimestamp = 0;
                }

                if (json["Uploader"].GetType() != Json::Type::Null) {
                    UserId = json["Uploader"]["UserId"];
                    Username = json["Uploader"]["Name"];
                }

                if (json["Medals"].GetType() != Json::Type::Null) {
                    AuthorTime = json["Medals"]["Author"];

                    if (!json["Medals"].HasKey("Gold")) {
                        GoldTime = GetDefaultMedalTime(Medals::Gold);
                    } else {
                        GoldTime = json["Medals"]["Gold"];
                    }

                    if (!json["Medals"].HasKey("Silver")) {
                        SilverTime = GetDefaultMedalTime(Medals::Silver);
                    } else {
                        SilverTime = json["Medals"]["Silver"];
                    }

                    if (!json["Medals"].HasKey("Bronze")) {
                        BronzeTime = GetDefaultMedalTime(Medals::Bronze);
                    } else {
                        BronzeTime = json["Medals"]["Bronze"];
                    }
                }

                if (json["Length"].GetType() != Json::Type::Null) {
                    Length = json["Length"];
                } else {
                    Length = AuthorTime;
                }

                // Tags is an array of tag objects
                if (json["Tags"].GetType() != Json::Type::Null) {
                    const Json::Value@ tagObjects = json["Tags"];

                    for (uint i = 0; i < tagObjects.Length; i++) {
                        for (uint j = 0; j < m_mapTags.Length; j++) {
                            if (m_mapTags[j].ID == tagObjects[i]["TagId"]) {
                                Tags.InsertLast(m_mapTags[j]);
                                break;
                            }
                        }
                    }

                    if (Tags.Length > 1) {
                        Tags.Sort(function(a, b) { return a.Name < b.Name; });
                    }
                }

                @PrepatchTag = RMC::config.GetPrepatchTag(this);

                Attempts = json.Get("Attempts", 0);
                SessionPB = json.Get("SessionPB", -1);
                GoalTime = json.Get("GoalTime", -1);
                TimeSpent = json.Get("TimeSpent", 0);
                TimerStart = json.Get("TimerStart", 0);
                TimerEnd = json.Get("TimerEnd", 0);
                Result = RMC::MapResult(int(json.Get("Result", 0)));
                PlayerName = json.Get("PlayerName", "");
                Highlighted = json.Get("Highlighted", false);
            } catch {
                Name = json["Name"];
                Log::Warn("Error parsing infos for the map: " + Name + "\nReason: " + getExceptionInfo(), true);
            }
        }

        Json::Value ToJson() {
            if (jsonCache !is null) {
                jsonCache["PlayedAt"] = PlayedAt; // value might have been updated since the cache was created
                return jsonCache;
            }

            Json::Value json = Json::Object();

            try {
                json["MapId"] = MapId;
                json["MapUid"] = MapUid;
                json["OnlineMapId"] = OnlineMapId;
                json["Name"] = Name;
                json["MapType"] = MapType;
                json["Exebuild"] = ExeBuild;
                json["UploadedAt"] = UploadedAt;
                json["UpdatedAt"] = UpdatedAt;
                json["PlayedAt"] = PlayedAt;
                json["GbxMapName"] = GbxMapName;
                json["TitlePack"] = TitlePack;
                json["VehicleName"] = Vehicle;
                json["Environment"] = Environment;
                json["AwardCount"] = AwardCount;
                json["ServerSizeExceeded"] = ServerSizeExceeded;
                json["Length"] = Length;
                json["OnlineRecordCount"] = OnlineRecordCount;
                json["AuthorBeatable"] = AuthorBeatable;
                json["AuthorBeaten"] = AuthorBeaten;

                Json::Value uploaderObject = Json::Object();
                uploaderObject["UserId"] = UserId;
                uploaderObject["Name"] = Username;

                json["Uploader"] = uploaderObject;

                Json::Value medalsObject = Json::Object();
                medalsObject["Author"] = AuthorTime;
                medalsObject["Gold"] = GoldTime;
                medalsObject["Silver"] = SilverTime;
                medalsObject["Bronze"] = BronzeTime;

                json["Medals"] = medalsObject;

                Json::Value tagArray = Json::Array();
                for (uint i = 0; i < Tags.Length; i++) {
                    tagArray.Add(Tags[i].ToJson());
                }

                json["Tags"] = tagArray;

                json["Attempts"] = Attempts;
                json["TimeSpent"] = TimeSpent;
                json["Result"] = Result;
                json["SessionPB"] = SessionPB;
                json["GoalTime"] = GoalTime;
                json["PlayerName"] = PlayerName;
                json["TimerStart"] = TimerStart;
                json["TimerEnd"] = TimerEnd;
                json["Highlighted"] = Highlighted;

                @jsonCache = json;
            } catch {
                Log::Error("Error converting map info to JSON for map " + Name, true);
            }

            return json;
        }

        void TrackStats() {
            Log::Trace("Started tracking stats for " + this.toString());

            TimerStart = RMC::currentRun.TimeLeft;
            startnew(CoroutineFunc(AttemptsLoop));
        }

        void AttemptsLoop() {
            while (!TM::IsPlayerReady()) {
                yield();
            }

            bool handled = false;

            while (CountAttempts) {
                yield();

                if (RMC::currentRun is null || (!RMC::currentRun.IsRunning && !RMC::currentRun.IsStarting)) {
                    break;
                }

                CTrackMania@ app = cast<CTrackMania>(GetApp());

                if (!TM::IsMapCorrect(MapUid)) {
                    sleep(100);
                    continue;
                }

                auto playground = app.CurrentPlayground;

                if (playground is null || playground.GameTerminals.Length == 0) {
                    sleep(100);
                    continue;
                }

#if TMNEXT
                auto player = cast<CSmPlayer>(playground.GameTerminals[0].ControlledPlayer);

                if (player is null) {
                    continue;
                }

                CSmScriptPlayer::EPost state = cast<CSmScriptPlayer>(player.ScriptAPI).Post;
#else
                auto player = cast<CTrackManiaPlayer>(playground.GameTerminals[0].ControlledPlayer);

                if (player is null) {
                    continue;
                }

                CTrackManiaScriptPlayer::ERaceState state = player.ScriptAPI.RaceState;
#endif

                switch (state) {
#if TMNEXT
                    case CSmScriptPlayer::EPost::Char:
#else
                    case CTrackManiaScriptPlayer::ERaceState::BeforeStart:
#endif
                        handled = false;
                        break;

                    default:
                        if (!handled) {
                            handled = true;
                            Attempts++;
                        }

                        break;
                }

                sleep(100);
            }

            Log::Trace("Finished tracking attempts for " + this.toString());
            Log::Trace("Total attempts: " + Attempts);
        }

        void SetStats(RMC::MapResult result, int timerEnd, int timeSpent, int pb, const string &in playerName = "") {
            Log::Trace("Setting stats for " + this.toString());
            Log::Trace("Result: " + tostring(result));
            Log::Trace("PB: " + Time::Format(pb));

            CountAttempts = false;
            Result = result;
            TimeSpent = timeSpent;
            TimerEnd = timerEnd;
            SessionPB = pb;
            GoalTime = GetMedalTime(RMC::currentRun.RunConfig.GoalMedal, RMC::currentRun.RunConfig.CalculateMedals);
            PlayerName = playerName;

            // Update cache if there's one
            if (jsonCache !is null) {
                jsonCache["Attempts"] = Attempts;
                jsonCache["TimeSpent"] = TimeSpent;
                jsonCache["TimerStart"] = TimerStart;
                jsonCache["TimerEnd"] = TimerEnd;
                jsonCache["Result"] = Result;
                jsonCache["SessionPB"] = SessionPB;
                jsonCache["GoalTime"] = GoalTime;
                jsonCache["PlayerName"] = PlayerName;
                jsonCache["Highlighted"] = Highlighted;

                Log::Trace("Updated JSON cache for " + this.toString());
                Log::Trace("New cache: " + Json::Write(jsonCache, true));
            }

            Log::Trace("Succesfully set stats for " + this.toString());
        }

        bool get_IsUploadedToServers() {
#if TMNEXT
            if (this.OnlineMapId != "") {
                return true;
            }

            return MXNadeoServicesGlobal::CheckIfMapExistsAsync(this.MapUid);
#else
            return false;
#endif
        }

        bool get_IsPrepatch() {
            return PrepatchTag !is null;
        }

        CachedImage@ get_Thumbnail() {
            return Images::CachedFromURL(MX_URL + "/mapthumb/" + this.MapId);
        }

        string get_TagsText() {
            if (this.Tags.IsEmpty()) {
                return "None";
            }

            string text = this.Tags[0].Name;

            for (uint i = 1; i < this.Tags.Length; i++) {
                text += ", " + this.Tags[i].Name;
            }

            return text;
        }

        string get_EnvironmentName() {
            if (Environment < 1 || Environment >= MX::Environments::Last) {
                return "Unknown";
            }

            return tostring(MX::Environments(Environment)).Replace("_", " ");
        }

        bool HasTag(int tagId) {
            for (uint i = 0; i < Tags.Length; i++) {
                if (Tags[i].ID == tagId) {
                    return true;
                }
            }

            return false;
        }

        bool HasTag(const string &in tagName) {
            for (uint i = 0; i < Tags.Length; i++) {
                if (Tags[i].Name == tagName) {
                    return true;
                }
            }

            return false;
        }

        MapTypes get_Type() {
            if (this.MapType.Contains("Stunt")) {
                return MapTypes::Stunt;
            } else if (this.MapType.Contains("Platform")) {
                return MapTypes::Platform;
            } else if (this.MapType.EndsWith("Royal")) {
                return MapTypes::Royal;
            }

            return MapTypes::Race;
        }

        uint GetMedalTime(Medals medal, bool defaultTime = false) {
            if (defaultTime && this.IsMedalEdited(medal)) {
                return this.GetDefaultMedalTime(medal);
            }

            switch (medal) {
#if TMNEXT
                case Medals::WR:
                    return TM::GetWorldRecordFromCache(this.MapUid);
#endif
                case Medals::Author:
                    return this.AuthorTime;
                case Medals::Gold:
                    return this.GoldTime;
                case Medals::Silver:
                    return this.SilverTime;
                case Medals::Bronze:
                    return this.BronzeTime;
                default:
                    return uint(-1);
            }
        }

        uint GetDefaultMedalTime(Medals medal) {
            uint normalGold;
            uint normalSilver;
            uint normalBronze;

            switch (this.Type) {
                case MapTypes::Stunt:
                    // Credits to beu and Ezio for the formula
                    normalGold = uint(Math::Floor(AuthorTime * 0.085) * 10);
                    normalSilver = uint(Math::Floor(AuthorTime * 0.06) * 10);
                    normalBronze = uint(Math::Floor(AuthorTime * 0.037) * 10);
                    break;
                case MapTypes::Platform:
                    normalGold = AuthorTime + 3;
                    normalSilver = AuthorTime + 10;
                    normalBronze = AuthorTime + 30;
                    break;
                case MapTypes::Race:
                case MapTypes::Royal:
                default:
                    normalGold = uint((AuthorTime * 1.06) / 1000 + 1) * 1000;
                    normalSilver = uint((AuthorTime * 1.2) / 1000 + 1) * 1000;
                    normalBronze = uint((AuthorTime * 1.5) / 1000 + 1) * 1000;
                    break;
            }

            switch (medal) {
#if TMNEXT
                case Medals::WR:
                    return TM::GetWorldRecordFromCache(this.MapUid);
#endif
                case Medals::Author:
                    return AuthorTime;
                case Medals::Gold:
                    return normalGold;
                case Medals::Silver:
                    return normalSilver;
                case Medals::Bronze:
                    return normalBronze;
                default:
                    return uint(-1);
            }
        }

        bool get_HasEditedMedals() {
            for (uint i = 0; i <= Medals::Gold; i++) {
                if (IsMedalEdited(Medals(i))) {
                    return true;
                }
            }

            return false;
        }

        bool IsMedalEdited(Medals medal) {
            if (medal >= Medals::Author) {
                return false;
            }

            bool inverse = this.Type == MapTypes::Stunt;
            int medalTime = GetMedalTime(medal);
            int defaultTime = GetDefaultMedalTime(medal);

            if (!inverse && medalTime < defaultTime) {
                return true;
            }

            if (inverse && medalTime > defaultTime) {
                return true;
            }

            return false;
        }

        bool opEquals(MapInfo@ other) {
            return other !is null && this.MapId == other.MapId;
        }

        string toString() {
            return "\"" + this.Name + "\" by " + this.Username;
        }
    }
}