int SortString(const string &in a, const string &in b) {
    const string lowerA = a.ToLower();
    const string lowerB = b.ToLower();

    if (lowerA < lowerB) return -1;
    if (lowerA > lowerB) return 1;
    return 0;
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
