namespace MX {
    bool IsMapLowEffort(MX::MapInfo@ map) {
        if (map.AwardCount > 15) {
            return false;
        }

        if (Regex::Contains(map.Name, "(^|[^a-z])RM[CST]($|[^a-z])", Regex::Flags::CaseInsensitive)) {
            Log::Warn("Map contains the word RMC, RMS, or RMT.");
            return true;
        }

        if (map.AwardCount < 10 && Regex::Contains(map.Name, "(Scrapie|granady|Ssano|Wirtual)|(\\blars\\b)", Regex::Flags::CaseInsensitive)) {
            Log::Warn("Map is most likely for a streamer and low effort.");
            return true;
        }

        if (map.AwardCount < 5) {
            if (Regex::Contains(map.Name, "Generator|Generated|Random map|\\b(RMM|RMG)\\b", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely randomly generated.");
                return true;
            }

            if (Regex::Contains(map.Name, "\\b(shit|trash|garbage|impossible|AI)\\b", Regex::Flags::CaseInsensitive)) {
                Log::Warn("Map is most likely low effort.");
                return true;
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
                && Regex::Contains(map.Name, "(Summer|Fall|Winter|Spring) 202\\d (- )?\\d{1,2}", Regex::Flags::CaseInsensitive)
            ) {
                Log::Warn("Map is most likely untagged Altered Nadeo.");
                return true;
            }
        }
#endif

        if (map.AwardCount < 5 && !map.HasTag("Kacky") && map.Name.ToLower().Contains("kacky")) {
            Log::Warn("Map is most likely untagged Kacky.");
            return true;
        }

        return false;
    }
}
