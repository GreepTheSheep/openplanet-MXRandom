namespace MX
{
    array<MapTag@> m_mapTags;
    Net::HttpRequest@ req;

    int mapToLoad = -1;

    bool APIDown = false;
    bool APIRefreshing = false;

    bool RandomMapIsLoading = false;
}