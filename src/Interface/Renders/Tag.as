namespace Render
{
    const vec4 TAG_COLOR = vec4( 66/255.0f,  66/255.0f,  66/255.0f, 1);

    void MapTag(MX::MapTag@ tag)
    {
        vec4 color;

        if (Text::TryParseHexColor(tag.Color, color)) {
            Controls::Tag("\\$s" + tag.Name, color);
        } else {
            Controls::Tag("\\$s" + tag.Name, TAG_COLOR);
        }
    }
}