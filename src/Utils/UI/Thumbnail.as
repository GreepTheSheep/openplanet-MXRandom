namespace UI {
    void MXThumbnailTooltip(CachedImage@ img, float resize = 0.25) {
        if (UI::BeginItemTooltip()) {
            float width = Draw::GetWidth() * resize;

            if (img.m_texture !is null) {
                vec2 thumbSize = img.m_texture.GetSize();
                UI::Image(img.m_texture, vec2(
                    width,
                    thumbSize.y / (thumbSize.x / width)
                ));

                UI::EndTooltip();
                return;
            }

            if (!img.m_error) {
                UI::Text(Icons::AnimatedHourglass + " Loading Thumbnail...");
            } else if (img.m_unsupportedFormat) {
                UI::Text(Icons::FileImageO + "\\$z Unsupported file format WEBP");
            } else if (img.m_notFound) {
                UI::Text("\\$fc0" + Icons::ExclamationTriangle + "\\$z Thumbnail not found");
            } else {
                UI::Text("\\$f00" + Icons::Times + "\\$z Error while loading thumbnail");
            }

            UI::EndTooltip();
        }
    }

    void MXMapThumbnailTooltip(const int &in mapId, const int &in position = 1, float resize = 0.25) {
        if (UI::IsItemHovered(UI::HoveredFlags::DelayShort | UI::HoveredFlags::NoSharedDelay)) {
            CachedImage@ mapThumb = Images::CachedFromURL(MX_URL + "/mapimage/" + mapId + "/" + position + "?hq=true");
            MXThumbnailTooltip(mapThumb, resize);
        }
    }
}
