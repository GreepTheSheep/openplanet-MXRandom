namespace UI {
    // Padding

    void VPadding(int y) {
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
        UI::Dummy(vec2(0, y * UI::GetScale()));
        UI::PopStyleVar();
    }

    void HPadding(int x) {
        UI::PushStyleVar(UI::StyleVar::ItemSpacing, vec2(0, 0));
        UI::SameLine();
        UI::Dummy(vec2(x * UI::GetScale(), 0));
        UI::SameLine();
        UI::PopStyleVar();
    }

    void PaddedSeparator(const string &in text) {
        UI::VPadding(5);
        UI::SeparatorText(text);
        UI::VPadding(5);
    }

    void PaddedHeaderSeparator(const string &in text) {
        UI::PushFont(Fonts::MidBold);
        UI::PaddedSeparator(text);
        UI::PopFont();
    }

    // Alignment

    void CenterAlign() {
        vec2 region = UI::GetWindowSize();
        vec2 position = UI::GetCursorPos();
        UI::SetCursorPos(vec2(region.x / 2, position.y));
    }

    void CenterAlign(float elementWidth) {
        UI::SetCursorPos(vec2((UI::GetWindowSize().x - elementWidth) * 0.5, UI::GetCursorPos().y));
    }

    void CenteredText(const string &in text, bool disabled = false) {
        UI::AlignTextToFramePadding();
        float textWidth = Draw::MeasureString(text).x;
        UI::CenterAlign(textWidth);

        if (disabled) UI::TextDisabled(text);
        else UI::Text(text);
    }

    bool CenteredButton(const string &in text) {
        vec2 button = MeasureButton(text);
        UI::CenterAlign(button.x);

        return UI::Button(text);
    }

    bool CenteredButton(const string &in text, float color) {
        vec2 button = MeasureButton(text);
        UI::CenterAlign(button.x);

        return UI::ButtonColored(text, color);
    }

    void AlignTextToImage(const string &in text, UI::Font@ font) {
        float textHeight = Draw::MeasureString(text, font, font.FontSize).y + 6; // MeasureString is a little off
        float difference = ((PluginSettings::RMC_ImageSize * 2 * UI::GetScale()) - textHeight) * 0.5;

        UI::SetCursorPos(UI::GetCursorPos() + vec2(0, difference));

        UI::PushFont(font);
        UI::Text(text);
        UI::PopFont();
    }

    void SetItemText(const string &in text, int width = 300, bool centered = false) {
        if (centered) {
            SetCenteredItemText(text, width);
        } else {
            UI::AlignTextToFramePadding();
            UI::Text(text);
            UI::SameLine();

            float itemWidth = Math::Max(-1, width - Draw::MeasureString(text).x);
            UI::SetNextItemWidth(itemWidth);
        }
    }

    void SetCenteredItemText(const string &in text, int width = 300) {
        UI::SameLine();
        UI::CenterAlign();
        SetItemText(text, width);
    }

    // Buttons

    vec2 MeasureButton(const string &in label) {
        vec2 text = Draw::MeasureString(label);
        vec2 padding = UI::GetStyleVarVec2(UI::StyleVar::FramePadding);

        return text + padding * 2;
    }

    bool FlexButton(const string &in label) {
        float buttonWidth = MeasureButton(label).x;
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;

        if (buttonWidth + itemSpacing > UI::GetContentRegionAvail().x) {
            return UI::Button(label);
        }

        return UI::Button(label, vec2(-1, 0));
    }

    bool ResetButton() {
        UI::SameLine();
        UI::Text(Icons::Times);
        if (UI::IsItemHovered()) UI::SetMouseCursor(UI::MouseCursor::Hand);
        UI::SetItemTooltip("Reset field");

        return UI::IsItemClicked();
    }

    // Tooltip

    void SettingDescription(const string &in text) {
        UI::SameLine();
        UI::TextDisabled(Icons::QuestionCircle);

        if (UI::BeginItemTooltip()) {
            UI::PushTextWrapPos(500);
            UI::TextWrapped(text);
            UI::PopTextWrapPos();

            UI::EndTooltip();
        }
    }

    // Text

    // Original code from the plugin Ultimate Medals (https://openplanet.dev/plugin/ultimatemedals)
    // Copyright by Phlarx and Miss
    // Fort modified it in 2025

    const uint timeOffsetStart = 1000;
    const uint timeOffsetEnd = 2000;
    const uint scrollSpeed = 20;
    uint scrollingTimeStart = 0;
    uint scrollingTimeEnd = 0;

    void ScrollingText(const string &in text) {
        vec2 size = Draw::MeasureString(text);
        vec2 region = UI::GetContentRegionAvail().x; 

        if (size.x < region.x) {
            UI::Text(text);
            return;
        }

        auto dl = UI::GetWindowDrawList();
        vec2 cursorPos = UI::GetCursorScreenPos();

        // Create a dummy for the text
        UI::Dummy(vec2(region.x, size.y));

        // If the text is hovered, reset now
        if (UI::IsItemHovered()) {
            scrollingTimeStart = Time::Now;
            scrollingTimeEnd = 0;
        }

        vec2 textPos = vec2(0, 0);

        // Move the text forwards after the start time has passed
        uint timeOffset = Time::Now - scrollingTimeStart;

        if (timeOffset > timeOffsetStart) {
            uint moveTimeOffset = timeOffset - timeOffsetStart;
            textPos.x = -(moveTimeOffset / scrollSpeed);
        }

        // Stop moving when we've reached the end
        if (textPos.x < -(size.x - region.x)) {
            textPos.x = -(size.x - region.x);

            // Begin waiting for the end time
            if (scrollingTimeEnd == 0) {
                scrollingTimeEnd = Time::Now;
            }
        }

        // Go back to the starting position after the end time has passed
        if (scrollingTimeEnd > 0) {
            uint endTimeOffset = Time::Now - scrollingTimeEnd;

            if (endTimeOffset > timeOffsetEnd) {
                scrollingTimeStart = Time::Now;
                scrollingTimeEnd = 0;
            }
        }

        vec4 rectBox = vec4(cursorPos.x, cursorPos.y, region.x, size.y);
        dl.PushClipRect(rectBox, true);
        dl.AddText(cursorPos + textPos, vec4(1, 1, 1, 1), text);
        dl.PopClipRect();
    }

    // Other

    UI::Texture@ PredatorTexture = UI::LoadTexture("src/Assets/Images/Predator.png");
    UI::Texture@ LevlupTexture = UI::LoadTexture("src/Assets/Images/Levlup.png");

    const array<UI::Texture@> sponsorsTextures = { PredatorTexture, LevlupTexture };
    uint textureIndex = 0;
    int lastUpdate = Time::Stamp;
    const int sponsorDuration = 30;
    const int endDate = Time::ParseFormatString("%FT%T", '2025-10-31T22:59:59');

    void RotatingSponsor() {
        if (Time::Stamp > endDate) {
            // Competition is over
            return;
        }

        if (Time::Stamp > lastUpdate + sponsorDuration) {
            lastUpdate = Time::Stamp;

            if (textureIndex == sponsorsTextures.Length - 1) {
                textureIndex = 0;
            } else {
                textureIndex++;
            }
        }

        UI::CenterAlign(75 * UI::GetScale());
        UI::Image(sponsorsTextures[textureIndex], vec2(75 * UI::GetScale()));

        if (UI::IsItemClicked()) {
            OpenBrowserURL("https://flinkblog.de/RMC/breaktherecord");
        }

        if (UI::BeginItemTooltip()) {
            UI::PushTextWrapPos(500);
            UI::TextWrapped("Join the RMC Break the Record competition!\n\nFrom 25/10 to 31/10, you can participate by playing RMC and win prizes \\$FD0" + Icons::Trophy + "\\$z\n\nClick the logo to learn how to participate.");
            UI::PopTextWrapPos();
            UI::EndTooltip();
        }
    }
}
