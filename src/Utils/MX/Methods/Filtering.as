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

            if (Regex::Contains(name, "(^|[^a-z])RM[CST]($|[^a-z])", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map contains the word RMC, RMS, or RMT.");
                return true;
            }

            if (map.AwardCount < 10 && Regex::Contains(name, "(Scrapie|granady|Ssano|Wirtual)|(\\blars\\b)", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely for a streamer and low effort.");
                return true;
            }

            if (map.AwardCount < 5) {
                if (Regex::Contains(name, "Generator|Generated|Random map|\\b(RMM|RMG)\\b", Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map is most likely randomly generated.");
                    return true;
                }

                if (Regex::Contains(name, "(^|[^a-z])(awful|pain|lunatic|sorry|annoying|shit|trash|garbage|impossible|AI)($|[^a-z])", Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map is most likely low effort.");
                    return true;
                }

                if (Regex::Contains(name, "#?0*(2[6-9]|[3-9]\\d|\\d{3,})[^0-9]?$", Regex::Flags::CaseInsensitive)) {
                    Log::Warn("Map is most likely from a long low effort series.");
                    return true;
                }
            }
        }

        return false;
    }

    bool IsMapUntagged(MX::MapInfo@ map) {
#if TMNEXT
        if (map.Username != "Ubisoft Nadeo" && !map.HasTag("Altered Nadeo")) {
            if (Regex::Contains(map.Name, "^(Icy |Yeet )?(Summer|Fall|Winter|Spring) 202\\d (- )?\\d{1,2}", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            } else if (
                map.AwardCount <= 5
                && map.HasTag("Remake")
                && Regex::Contains(map.Name, "((Summer|Fall|Winter|Spring) 202\\d (- )?\\d{1,2})|\\b[a-e]0[1-5]\\b|Training (- )?[0-2]?\\d", Regex::Flags::CaseInsensitive)
            ) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            }
        }
#endif

        if (map.AwardCount < 5) {
            if (!map.HasTag("Kacky") && map.Name.ToLower().Contains("kacky")) {
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
}
