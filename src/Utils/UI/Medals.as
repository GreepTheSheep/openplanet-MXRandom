namespace UI {
    // From Better TOTD by Xertrov https://github.com/XertroV/tm-better-totd
    const string BRONZE_ICON   = "\\$964" + Icons::Circle + " \\$z";
    const string SILVER_ICON   = "\\$899" + Icons::Circle + " \\$z";
    const string GOLD_ICON     = "\\$db4" + Icons::Circle + " \\$z";
    const string AT_ICON       = "\\$071" + Icons::Circle + " \\$z";

    const string WR_ICON       = "\\$C91" + Icons::Trophy + " \\$z";

    string GetMedalIcon(Medals medal) {
        switch (medal) {
#if TMNEXT
            case Medals::WR:
                return WR_ICON;
#endif
            case Medals::Author:
                return AT_ICON;
            case Medals::Gold:
                return GOLD_ICON;
            case Medals::Silver:
                return SILVER_ICON;
            case Medals::Bronze:
                return BRONZE_ICON;
            default:
                return "";
        }
    }

    string FormatTime(int time, MapTypes mapType) {
        switch (mapType) {
            case MapTypes::Stunt:
                if (time < 1) return "-";

                return tostring(time) + " pts";
            case MapTypes::Platform:
                if (time < 0) return "-";

                return tostring(time) + " respawns";
            case MapTypes::Race:
            default:
                if (time < 1) {
                    return "-:--.---";
                }

                return Time::Format(time);
        }
    }
}
