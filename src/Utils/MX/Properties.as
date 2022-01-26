namespace MX
{
    array<MapTag@> m_mapTags;
    Net::HttpRequest@ req;

    int mapToLoad = -1;

    bool APIDown = true;
    bool APIRefreshing = false;

    bool RandomMapIsLoading = false;
}