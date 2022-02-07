namespace MX
{
    array<MapTag@> m_mapTags;
    Net::HttpRequest@ req;

    int mapToLoad = -1;

#if FORCE_API_DOWN
    bool APIDown = true;
#else
    bool APIDown = false;
#endif
    bool APIRefreshing = false;

    bool RandomMapIsLoading = false;
}