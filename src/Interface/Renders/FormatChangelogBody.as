namespace Render
{
    string FormatChangelogBody(string body)
    {
        // Directs urls
        body = Regex::Replace(body, "(https?:\\/\\/[^\\[ ]*)", "[" + Icons::ExternalLink + " $1]($1)");

        // Issues links
        body = Regex::Replace(body, "\\(?#([0-9]+)\\)?", "[#$1]("+GITHUB_URL+"/issues/$1)");

        return body;
    }
}