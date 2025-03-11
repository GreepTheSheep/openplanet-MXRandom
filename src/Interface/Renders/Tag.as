namespace Render
{
    const vec4 TAG_COLOR      = vec4( 66/255.0f,  66/255.0f,  66/255.0f, 1);
    const vec2 TAG_PADDING    = vec2(8, 4);
    const float TAG_ROUNDING  = 4;

    vec4 DrawTag(const vec4 &in rect, const string &in text, const vec4 &in color = TAG_COLOR)
    {
        auto dl = UI::GetWindowDrawList();
        dl.AddRectFilled(rect, color, TAG_ROUNDING);
        dl.AddText(vec2(rect.x, rect.y) + TAG_PADDING, vec4(1, 1, 1, 1), text);
        return rect;
    }

    vec4 DrawTag(const vec2 &in pos, const string &in text, const vec4 &in color = TAG_COLOR)
    {
        vec2 textSize = Draw::MeasureString(text);
        vec2 tagSize = textSize + TAG_PADDING * 2;
        return DrawTag(vec4(pos.x, pos.y, tagSize.x, tagSize.y), text, color);
    }

    void Tag(const string &in text, const vec4 &in color = TAG_COLOR)
    {
        vec2 textSize = Draw::MeasureString(text);
        UI::Dummy(textSize + TAG_PADDING * 2);
        DrawTag(UI::GetItemRect(), text, color);
    }

    void MapTag(MX::MapTag@ tag)
    {
        vec4 color;

        if (Text::TryParseHexColor(tag.Color, color)) {
            Render::Tag(tag.Name, color);
        } else {
            Render::Tag(tag.Name);
        }
    }
}