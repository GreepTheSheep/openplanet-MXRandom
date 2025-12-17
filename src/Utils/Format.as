namespace Format {
    const int regexFlags = Regex::Flags::ECMAScript | Regex::Flags::CaseInsensitive;

    string GbxText(const string &in name) {
        // remove BOMs and newlines
        string text = Regex::Replace(name, "[\u200B-\u200F\uFEFF\\n]", "");

        array<string> formatCodes = Regex::Search(text, "^(\\$([0-9a-f]{1,3}|[gimnostuwz<>]|[hlp](\\[[^\\]]+\\])?) *)+", regexFlags);

        if (!formatCodes.IsEmpty()) {
            text = text.Replace(formatCodes[0], formatCodes[0].Replace(" ", ""));
        }

        return text.Trim();
    }
}
