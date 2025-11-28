class CachedImage {
    string m_url;
    UI::Texture@ m_texture;
    int m_responseCode;
    bool m_error = false;
    bool m_notFound = false;
    bool m_unsupportedFormat = false;

    void DownloadFromURLAsync() {
        Log::Debug("Loading texture: " + m_url);
        auto req = API::Get(m_url);

        while (!req.Finished()) {
            yield();
        }

        m_responseCode = req.ResponseCode();

        if (m_responseCode == 200) {
            if (req.Buffer().ReadString(4) == "RIFF") {
                // WEBP is not supported by Openplanet
                auto webpReq = Net::HttpPost("https://map-monitor.xk.io/tmx/convert_webp", m_url);

                while (!webpReq.Finished()) {
                    yield();
                }

                if (webpReq.ResponseCode() == 200) {
                    @m_texture = UI::LoadTexture(webpReq.Buffer());

                    if (m_texture.GetSize().x == 0) {
                        @m_texture = null;
                        m_error = true;
                    }
                } else {
                    Log::Error("WEBP conversion failed. Error " + webpReq.ResponseCode());
                    m_unsupportedFormat = true;
                    m_error = true;
                }
            } else {
                req.Buffer().Seek(0);
                @m_texture = UI::LoadTexture(req.Buffer());
                if (m_texture.GetSize().x == 0) {
                    @m_texture = null;
                    m_error = true;
                }
            }
        } else {
            m_notFound = m_responseCode == 404;
            m_error = true;
        }
    }
}

namespace Images {
    dictionary g_cachedImages;

    CachedImage@ FindExisting(const string &in url) {
        CachedImage@ ret = null;
        g_cachedImages.Get(url, @ret);
        return ret;
    }

    CachedImage@ CachedFromURL(const string &in url) {
        // Return existing image if it already exists
        auto existing = FindExisting(url);
        if (existing !is null) {
            return existing;
        }

        // Create a new cached image object and remember it for future reference
        auto ret = CachedImage();
        ret.m_url = url;
        g_cachedImages.Set(url, @ret);

        // Begin downloading
        startnew(CoroutineFunc(ret.DownloadFromURLAsync));
        return ret;
    }
}