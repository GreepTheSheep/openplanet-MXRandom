namespace MX {
    bool IsMapLowEffort(MX::MapInfo@ map) {
        if (map.AwardCount > 15) {
            return false;
        }

        array<string> names = { map.Name };

        string cleanName = Text::StripFormatCodes(map.GbxMapName);

        if (map.Name != cleanName) {
            names.InsertLast(cleanName);
        }

        for (uint i = 0; i < names.Length; i++) {
            string name = names[i];

            if (Regex::Contains(name, "(^|[^a-z])RM[CST]($|[^a-z])|RM[CST] ?free|free ?RM[CST]|RMCF", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map contains the word RMC, RMS, or RMT.");
                return true;
            }

            // Snowo was suggested by chybrydra
            // Everios was okay with filtering yeet max-up
            if (Regex::Contains(name, "(snowo map for snowo haters|Everios96 \\[Yeet\\])", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is from a low-effort series.");
                return true;
            }

            if (map.AwardCount < 10 && Regex::Contains(name, "(Scrapie|granady|Ssano|Wirtual)|(\\blars\\b)", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely for a streamer and low effort.");
                return true;
            }

            if (map.AwardCount < 5) {
                if (Regex::Contains(name, "Generator|Generated|Random map|BPM - Random|\\b(RMM|RMG|R?TGE|RTG)\\b", Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map is most likely randomly generated.");
                    return true;
                }

                if (Regex::Contains(name, "(^|[^a-z])(awful|pain|ruin(ed|ing?)|worst|lunatic|hell|sorry|killer|cancer|annoying|dumb|stupid|shit(e|ty)?|trash|garbage|impossible|AI|GPT)($|[^a-z])", Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map is most likely low effort.");
                    return true;
                }

                // Disabled for now
                if (false && Regex::Contains(name, "#?0*(2[6-9]|[3-9]\\d|\\d{3,})[^0-9]?$", Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map is most likely from a long low effort series.");
                    return true;
                }
            }
        }

        return false;
    }

    bool IsMapUntagged(MX::MapInfo@ map) {
#if TMNEXT
        if (map.Username != "Ubisoft Nadeo" && map.Username != "BigBang1112" && !map.HasTag("Altered Nadeo")) {
            // Seasonal campaign map
            if (
                Regex::Contains(map.Name, "(Summer|Fall|Winter|Spring) 202\\d[ -]+\\d{1,2}", Regex::Flags::CaseInsensitive)
                && !Regex::Contains(map.Name, "(Community|Project)", Regex::Flags::CaseInsensitive)
            ) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            } 

            // Training campaign
            if (Regex::Contains(map.Name, "Training (- )?[0-2]?\\d", Regex::Flags::CaseInsensitive) && !map.Name.Contains("Better")) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            }

            // TMNF / TM2
            if (
                Regex::Contains(map.Name, "\\b[a-e]-?(0[1-9]|1[0-5])(\\b|[- ](Acrobatic|Race|Obstacle|Endurance|Speed))", Regex::Flags::CaseInsensitive)
                && !map.Name.ToLower().Contains("a08")
            ) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            }

            // ESWC
            if (map.Username != "MrFunreal" && map.Username != "Schwabsi" && Regex::Contains(map.Name, "ESWC.*?[A-I][ -][1-9]", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            }

            // Common Altered Nadeo alterations
            if (Regex::Contains(map.Name, "(1[ -]?(UP|DOWN|BACK))|Max[ -]Up|CP1 (is )?End|CPLess|hidden fin|series combined", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            }

            // Alterations usually between parentheses or brackets, like "(Underwater)" or "[Snowcar]", or after a hyphen, like "- Reversed"
            if (Regex::Contains(map.Name, "(\\(|\\[|- )(((car)?(Snow|Rally|Desert)( ?car)?)|UW|Underwater|Yeet|Reverse)", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            }
        }
#endif

        if (map.AwardCount < 5) {
            if (!map.HasTag("Kacky") && Regex::Contains(map.Name, "kacky|uber ?bug|\\buber\\b|wtf of what", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely untagged Kacky.");
                return true;
            }

            if (!map.HasTag("Trial") && Regex::Contains(map.Name, "(^|[^a-z])Trial($|[^a-z])", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely untagged Trial.");
                return true;
            }
        }

        return false;
    }

    bool IsMapImpossible(MX::MapInfo@ map) {
        if (Regex::Contains(map.Name, "((24|48|64|128|255) ?x|template|console base)", Regex::Flags::CaseInsensitive)) {
            Log::Warn("Map is most likely a base / template map.");
            return true;
        }

        if (Regex::Contains(map.Name, "base( map)?\\b", Regex::Flags::CaseInsensitive) && map.AuthorTime < 15000) {
            Log::Warn("Map is most likely a base / template map.");
            return true;
        }

        if (map.Type != MapTypes::Platform && map.AuthorTime < 50) {
            Log::Warn("Map is shorter than 50ms, it's most likely impossible.");
            return true;
        }

        return impossibleMaps.Find(map) > -1;
    }
}
