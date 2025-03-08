#if TMNEXT
class PBTime {
    string name;
    string wsid;
    uint time;
    string timeStr;

#if DEPENDENCY_MLFEEDRACEDATA
    PBTime(MLFeed::PlayerCpInfo_V4@ _player) {
        wsid = _player.WebServicesUserId;
        name = _player.Name;
        time = Math::Max(_player.bestTime, 0);
        timeStr = time <= 0 ? "???" : Time::Format(time);
    }
#endif

    int opCmp(PBTime@ other) const {
        if (time == 0) {
            return (other.time == 0 ? 0 : 1); // one or both PB unset
        }
        if (other.time == 0 || time < other.time) return -1;
        if (time == other.time) return 0;
        return 1;
    }
}
#endif