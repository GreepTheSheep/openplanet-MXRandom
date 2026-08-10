int SortString(const string &in a, const string &in b) {
    const string lowerA = a.ToLower();
    const string lowerB = b.ToLower();

    if (lowerA < lowerB) return -1;
    if (lowerA > lowerB) return 1;
    return 0;
}

string Pluralize(const string &in word, int count, const string &in suffix = "s") {
    if (count == 1) return word;

    return word + suffix;
}

// This is only used to parse category tags to a dictionary
// don't use it if your JSON is not an object containing strings!
dictionary JsonToDict(const Json::Value@ json) {
    if (json.GetType() != Json::Type::Object) {
        Log::Error("Failed to parse JSON to dictionary");
        Log::Debug(Json::Write(json));
        return {};
    }

    dictionary converted = dictionary();
    array<string> keys = json.GetKeys();

    for (uint i = 0; i < keys.Length; i++) {
        const Json::Value@ value = json[keys[i]];

        if (value.GetType() != Json::Type::String) {
            Log::Error("Unexpected value type when converting JSON to dictionary");
            Log::Debug("JSON value: " + tostring(value.GetType()));
            continue;
        }

        converted.Set(keys[i], string(value));
    }

    return converted;
}

string IntArrayToString(array<int> arr) {
    array<string> res;

    for (uint i = 0; i < arr.Length; i++) {
        res.InsertLast(tostring(arr[i]));
    }

    return Text::Join(res, ",");
}

array<int> StringToIntArray(const string &in arrStr) {
    array<int> res = {};
    if (arrStr.Length == 0) return res;

    array<string> values = arrStr.Split(",");

    for (uint i = 0; i < values.Length; i++) {
        int n;

        if (values[i] != "" && Text::TryParseInt(values[i], n)) {
            res.InsertLast(n);
        }
    }

    return res;
}

array<string> SplitAndFilterString(const string &in str, const string &in separator = ",") {
    array<string> res = str.Split(separator);

    for (int i = int(res.Length) - 1; i >= 0; i--) {
        if (res[i] == "") {
            res.RemoveAt(i);
        } else {
            res[i] = res[i].Trim();
        }
    }

    return res;
}
