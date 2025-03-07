class Date
{
    int year;
    int month;
    int day;

    Date(const int &in _year, const int &in _month, const int &in _day) {
        year = _year;
        month = _month;
        day = _day;
    }

    bool isBefore(const Date@ &in date) {
        return year < date.year || (year == date.year && (month < date.month || (month == date.month && day <= date.day)));
    }

    bool isAfter(const Date@ &in date) {
        return !isBefore(date);
    }

    string ToString() {
        return year + "-" + Text::Format("%.02d", month) + "-" + Text::Format("%.02d", day);
    }
}

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
