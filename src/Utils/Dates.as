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
}