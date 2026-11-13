const vec2 THUMBNAIL_SIZE = vec2(300);
const vec2 PADDING_SIZE   = vec2(10);
const int TITLE_SIZE      = 22;
const int TEXT_SIZE       = 18;
const int LINE_SPACING    = 4;

const vec4 TEXT_GREY  = vec4(.85, .85, .85, 1);
const vec4 TEXT_WHITE = vec4(1);
const vec4 BG_GREY    = vec4(.13, .13, .13, 1);
const vec4 BG_BLACK   = vec4(0, 0, 0, .85);
const vec4 LINE_GREEN = vec4(.6, 1, .6, 1);

class PicksModalDialog : ModalDialog {
    MX::MapInfo@ picked;
    array<MX::MapInfo@> options;
    bool HasPicked;

    PicksModalDialog(array<MX::MapInfo@> maps) {
        super("Choose a map##PickMaps");
        options = maps;
        float width = (THUMBNAIL_SIZE.x * maps.Length) + 50;
        m_size = vec2(width, 400);
        startnew(CoroutineFunc(PadLoop));
    }

    void PadLoop() {
        if (!CanPickMap()) {
            return;
        }

        while (!HasPicked) {
            yield();

            if (!PluginSettings::RMC_PadNavigationPicks) {
                sleep(500);
                continue;
            }

            int index = picked is null ? int(options.Length / 2) : options.Find(picked);

            // Shouldn't happen, but doesn't hurt
            if (index == -1) {
                sleep(100);
                continue;
            }

            CInputScriptPad@ pad = TM::GetActivePad();

            if (pad is null) {
                sleep(100);
                continue;
            }

            for (uint i = 0; i < pad.ButtonEvents.Length; i++) {
                switch (pad.ButtonEvents[i]) {
                    case CInputScriptPad::EButton::A:
                        if (picked is null) {
                            @picked = options[index];
                        } else {
                            HasPicked = true;
                            return;
                        }

                        break;

                    case CInputScriptPad::EButton::Left:
                    case CInputScriptPad::EButton::LeftStick_Left:
                    case CInputScriptPad::EButton::RightStick_Left:
                        if (index > 0) {
                            @picked = options[index - 1];
                        }

                        break;

                    case CInputScriptPad::EButton::Right:
                    case CInputScriptPad::EButton::LeftStick_Right:
                    case CInputScriptPad::EButton::RightStick_Right:
                        if (index < int(options.Length - 1)) {
                            @picked = options[index + 1];
                        }

                        break;

                    default:
                        break;
                }
            }
        }
    }

    bool CanClose() override {
        return false;
    }

    bool CanPickMap() {
        return true;
    }
    
    bool get_HasStarted() {
        return false;
    }

    vec2  get_CardSize()    { return THUMBNAIL_SIZE * UI::GetScale(); }
    vec2  get_PreviewSize() { return CardSize - vec2(0, CardSize.y * 0.8); }
    float get_WrapSize()    { return CardSize.x - (Padding.x * 2); }
    vec2  get_Padding()     { return PADDING_SIZE * UI::GetScale(); }
    float get_TitleSize()   { return TITLE_SIZE * UI::GetScale(); }
    float get_TextSize()    { return TEXT_SIZE * UI::GetScale(); }
    float get_LineSpacing() { return LINE_SPACING * UI::GetScale(); }

    void RenderDialog() override {
        auto dl = UI::GetWindowDrawList();

        if (UI::BeginTable("MapGrid", options.Length, UI::TableFlags::SizingStretchSame)) {
            RenderMapGrid();
            UI::EndTable();
        }

        UI::VPadding(int(LineSpacing));

        UI::PushFontSize(28);

        RenderFooter();

        UI::PopFontSize();

        if (HasPicked) {
            Close();
        }
    }

    void RenderMapGrid() {
        for (uint i = 0; i < options.Length; i++) {
            UI::TableNextColumn();
            RenderMapCard(options[i]);
        }
    }

    void RenderFooter() {
        UI::BeginDisabled(picked is null);

        if (UI::CenteredButton("Confirm", 0.33f)) {
            HasPicked = true;
        }

        UI::EndDisabled();
    }

    void RenderMapCard(MX::MapInfo@ map) {
        vec2 pos = UI::GetCursorScreenPos();
        auto dl = UI::GetWindowDrawList();

        if (map.Thumbnail !is null && map.Thumbnail.m_texture !is null) {
            UI::Image(map.Thumbnail.m_texture, CardSize);
        } else {
            UI::Dummy(CardSize);

            string message = Icons::AnimatedHourglass + " Loading...";

            if (map.Thumbnail !is null && map.Thumbnail.m_error) {
                message = Icons::Times + " Error";
            }

            vec2 messageSize = UI::MeasureString(message, null, TextSize, WrapSize);
            vec2 textCardPos = (CardSize - messageSize) / 2;
            vec2 textPosition = pos + textCardPos;
            dl.AddText(textPosition, TEXT_GREY, message, null, TextSize, WrapSize);
        }

        if (UI::IsItemHovered()) {
            if (CanPickMap()) {
                UI::SetMouseCursor(UI::MouseCursor::Hand);

                if (UI::IsMouseDoubleClicked()) {
                    @picked = map;
                    HasPicked = true;
                } else if (UI::IsItemClicked()) {
                    @picked = map;
                } else if (map == picked && UI::IsItemClicked(UI::MouseButton::Right)) {
                    @picked = null;
                }
            }

            RenderCardOverlay(dl, pos, map);
        } else {
            RenderCardPreview(dl, pos, map);
        }

        if (map == picked) {
            dl.AddRect(vec4(pos, CardSize), LINE_GREEN, 0, 4);
        }
    }

    void RenderCardOverlay(UI::DrawList@ dl, vec2 position, MX::MapInfo@ map) {
        dl.AddRectFilled(vec4(position, CardSize), BG_BLACK);

        vec2 textPosition = position + Padding;

        dl.AddText(textPosition, TEXT_WHITE, map.Name, null, TitleSize, WrapSize);
        vec2 nameSize = UI::MeasureString(map.Name, null, TitleSize, WrapSize);
        textPosition.y += (nameSize.y + LineSpacing);

        array<string> lines = {
            "by " + map.Username,
            "AT: " + UI::FormatTime(map.AuthorTime, map.Type),
            "Uploaded: " + Time::FormatString("%F", map.UpdatedAtTimestamp),
            "Tags: " + map.TagsText
        };

#if TMNEXT
        if (map.Type == MapTypes::Race || map.Type == MapTypes::Stunt) {
            if ((map.AuthorBeaten || map.OnlineWRTime > -1) && map.OnlineRecordCount == 0) {
                lines.InsertLast("Finishes: Unknown");
            } else {
                lines.InsertLast("Finishes: " + map.OnlineRecordCount);
            }

            if (map.OnlineWRTime > -1) {
                lines.InsertLast("WR: " + UI::FormatTime(map.OnlineWRTime, map.Type) + " by " + map.OnlineWRName);
            } else if (map.AuthorBeaten || map.OnlineRecordCount > 0) {
                lines.InsertLast("WR: Unknown");
            }
        }
#else
        if (TM::CurrentTitlePack() == "TMAll") {
            lines.InsertLast("Environment: " + map.EnvironmentName);
            lines.InsertLast("Vehicle: " + map.Vehicle);
        }
#endif

        for (uint i = 0; i < lines.Length; i++) {
            dl.AddText(textPosition, TEXT_GREY, lines[i], null, TextSize, WrapSize);
            vec2 lineSize = UI::MeasureString(lines[i], null, TextSize, WrapSize);
            textPosition.y += (lineSize.y + LineSpacing);
        }
    }

    void RenderCardPreview(UI::DrawList@ dl, vec2 position, MX::MapInfo@ map) {
        vec2 startPos = position + CardSize - PreviewSize;
        dl.AddRectFilled(vec4(startPos, PreviewSize), BG_BLACK);

        vec2 textPosition = startPos + Padding;

        dl.AddText(textPosition, TEXT_WHITE, UI::TextEllipsis(map.Name, WrapSize, TitleSize), null, TitleSize, WrapSize);

        textPosition.y += (TitleSize + LineSpacing);
        dl.AddText(textPosition, TEXT_GREY, "by " + map.Username, null, TextSize, WrapSize);
    }
}
