namespace MX
{
    void FetchMapTags()
    {
        m_mapTags.RemoveRange(0, m_mapTags.Length);
        APIRefreshing = true;
#if MOCK_TAGS
        Json::Value resNet = Json::Parse('[{"ID":1,"Name":"Race","Color":""},{"ID":2,"Name":"FullSpeed","Color":""},{"ID":3,"Name":"Tech","Color":""},{"ID":4,"Name":"RPG","Color":""},{"ID":5,"Name":"LOL","Color":""},{"ID":6,"Name":"Press Forward","Color":""},{"ID":7,"Name":"SpeedTech","Color":""},{"ID":8,"Name":"MultiLap","Color":""},{"ID":9,"Name":"Offroad","Color":"705100"},{"ID":10,"Name":"Trial","Color":""},{"ID":11,"Name":"ZrT","Color":"1a6300"},{"ID":12,"Name":"SpeedFun","Color":""},{"ID":13,"Name":"Competitive","Color":""},{"ID":14,"Name":"Ice","Color":"05767d"},{"ID":15,"Name":"Dirt","Color":"5e2d09"},{"ID":16,"Name":"Stunt","Color":""},{"ID":17,"Name":"Reactor","Color":"d04500"},{"ID":18,"Name":"Platform","Color":""},{"ID":19,"Name":"Slow Motion","Color":"004388"},{"ID":20,"Name":"Bumper","Color":"aa0000"},{"ID":21,"Name":"Fragile","Color":"993366"},{"ID":22,"Name":"Scenery","Color":""},{"ID":23,"Name":"Kacky","Color":""},{"ID":24,"Name":"Endurance","Color":""},{"ID":25,"Name":"Mini","Color":""},{"ID":26,"Name":"Remake","Color":""},{"ID":27,"Name":"Mixed","Color":""},{"ID":28,"Name":"Nascar","Color":""},{"ID":29,"Name":"SpeedDrift","Color":""},{"ID":30,"Name":"Minigame","Color":"7e0e69"},{"ID":31,"Name":"Obstacle","Color":""},{"ID":32,"Name":"Transitional","Color":""},{"ID":33,"Name":"Grass","Color":"06a805"},{"ID":34,"Name":"Backwards","Color":"83aa00"},{"ID":35,"Name":"Freewheel","Color":"f2384e"},{"ID":36,"Name":"Signature","Color":"f1c438"},{"ID":37,"Name":"Royal","Color":"ff0010"},{"ID":38,"Name":"Water","Color":"69dbff"},{"ID":39,"Name":"Plastic","Color":"fffc00"},{"ID":40,"Name":"Arena","Color":""},{"ID":41,"Name":"Freestyle","Color":""},{"ID":42,"Name":"Educational","Color":""}]');
#else
        Json::Value resNet = API::GetAsync("https://"+MX_URL+"/api/tags/gettags");
#endif

        try {
            for (uint i = 0; i < resNet.get_Length(); i++)
            {
                int tagID = resNet[i]["ID"];
                string tagName = resNet[i]["Name"];

                Log::Trace("Loading tag #"+tagID+" - "+tagName);

                m_mapTags.InsertLast(MapTag(resNet[i]));
            }

            print(m_mapTags.get_Length() + " tags loaded");
#if FORCE_API_DOWN
            Log::Warn("Plugin set to force API down, please remove that in production", true);
            APIDown = true;
#else
            APIDown = false;
#endif
            APIRefreshing = false;
        } catch {
            Log::Warn("Error while loading tags");
            Log::Error(MX_NAME + " API is not responding, it might be down.", true);
            APIDown = true;
            APIRefreshing = false;
        }
    }
}