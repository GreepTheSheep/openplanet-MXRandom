namespace UI {
    float scale = UI::GetScale();

    // Padding

    void VPadding(int y) {
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
        UI::Dummy(vec2(0, y * scale));
        UI::PopStyleVar();
    }

    void HPadding(int x) {
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
        UI::SameLine();
        UI::Dummy(vec2(x * scale, 0));
        UI::SameLine();
        UI::PopStyleVar();
    }

    // Alignment

    void AlignTextToImage(const string &in text, UI::Font@ font) {
        vec2 pos_orig = UI::GetCursorPos();

        float textHeight = Draw::MeasureString(text, font, font.FontSize).y + 6; // MeasureString is a little off
        float difference = ((PluginSettings::RMC_ImageSize * 2 * scale) - textHeight) * 0.5;

        UI::SetCursorPos(pos_orig + vec2(0, difference));

        UI::PushFont(font);
        UI::Text(text);
        UI::PopFont();
    }
}
