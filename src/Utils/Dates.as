class Date
{
    int timestamp;
    Time::Info info;

    Date(const string &in time, const string &in format) {
        timestamp = Time::ParseFormatString(format, time);
        info = Time::Parse(timestamp);
    }

    Date(const int &in stamp) {
        timestamp = stamp;
        info = Time::Parse(stamp);
    }

    bool isBefore(const Date@ &in date) const {
        return this < date;
    }

    bool isAfter(const Date@ &in date) const {
        return this > date;
    }

    string ToString() const {
        return Time::FormatString("%F", timestamp);
    }

    int opCmp(const Date@ &in other) const {
        if (this.timestamp < other.timestamp) {
            return -1;
        } else if (this.timestamp > other.timestamp) {
            return 1;
        }

        return 0;
    }
}

namespace Date {
    int TimestampFromObject(Json::Value@ obj) {
        string year = tostring(int(obj["Year"]));
        string month = Text::Format("%02d", int(obj["Month"]));
        string day = Text::Format("%02d", int(obj["Day"]));
        string hour = Text::Format("%02d", int(obj["Hour"]));
        string minute = Text::Format("%02d", int(obj["Minute"]));
        string second = Text::Format("%02d", int(obj["Second"]));
        
        string date = year + "-" + month + "-" + day + " " + hour + ":" + minute + ":" + second;
        return Time::ParseFormatString('%F %T', date);
    }

    // check if date complies with ISO 8601
    bool IsValid(const string &in date) {
        try {
            return Time::ParseFormatString("%F", date) > 0;
        } catch {
            return false;
        }
    }
}
