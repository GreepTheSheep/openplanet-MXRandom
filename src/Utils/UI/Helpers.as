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

    void CenterAlign(float elementWidth)
    {
        UI::SetCursorPos(vec2((UI::GetWindowSize().x - elementWidth) * 0.5, UI::GetCursorPos().y));
    }

    void CenteredText(const string &in text, bool disabled = false)
    {
        UI::AlignTextToFramePadding();
        float textWidth = Draw::MeasureString(text).x;
        UI::CenterAlign(textWidth);

        if (disabled) UI::TextDisabled(text);
        else UI::Text(text);
    }

    bool CenteredButton(const string &in text)
    {
        float textWidth = Draw::MeasureString(text).x;
        float padding = UI::GetStyleVarVec2(UI::StyleVar::FramePadding).x;
        float buttonWidth = textWidth + padding;

        UI::CenterAlign(buttonWidth);
        return UI::Button(text);
    }

    bool CenteredButton(const string &in text, float color)
    {
        float textWidth = Draw::MeasureString(text).x;
        float padding = UI::GetStyleVarVec2(UI::StyleVar::FramePadding).x;
        float buttonWidth = textWidth + padding;

        UI::CenterAlign(buttonWidth);
        return UI::ButtonColored(text, color);
    }

    void AlignTextToImage(const string &in text, UI::Font@ font) {
        float textHeight = Draw::MeasureString(text, font, font.FontSize).y + 6; // MeasureString is a little off
        float difference = ((PluginSettings::RMC_ImageSize * 2 * scale) - textHeight) * 0.5;

        UI::SetCursorPos(UI::GetCursorPos() + vec2(0, difference));

        UI::PushFont(font);
        UI::Text(text);
        UI::PopFont();
    }
}
