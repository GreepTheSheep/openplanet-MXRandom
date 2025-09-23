int SortString(const string &in a, const string &in b) {
    const string lowerA = a.ToLower();
    const string lowerB = b.ToLower();

    if (lowerA < lowerB) return -1;
    if (lowerA > lowerB) return 1;
    return 0;
}
