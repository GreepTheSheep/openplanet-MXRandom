namespace Render
{
    string FormatChangelogBody(string _body)
    {
        // Directs urls
        _body = Regex::Replace(_body, "(https?:\\/\\/[^\\[ ]*)", "[" + Icons::ExternalLink + " $1]($1)");

        // Issues links
        _body = Regex::Replace(_body, "\\(?#([0-9]+)\\)?", "[#$1]("+GITHUB_URL+"/issues/$1)");

        return _body;
    }
}