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

SQLite::Database@ cursedTimeDB = SQLite::Database(":memory:");
int64 DateFromStrTime(const string &in inTime) {
    auto st = cursedTimeDB.Prepare("SELECT unixepoch(?) as x");
    st.Bind(1, inTime);
    st.Execute();
    st.NextRow();
    st.NextRow();
    return st.GetColumnInt64("x");
}