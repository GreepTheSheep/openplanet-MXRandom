void RenderInterface() {
	if (!menu_visibility) {
		return;
	}
    UI::SetNextWindowSize(Setting_WindowSize_h, Setting_WindowSize_w);
	if (UI::Begin(MXColor + Icons::Random + " \\$z"+name+"\\$555 (v"+Meta::ExecutingPlugin().get_Version()+" by Greep)", menu_visibility)) {
        RenderHeader();
        RenderBody();
        RenderFooter();
	}
	UI::End();
}

void RenderHeader() {
    if (!isSearching) {
        if (RenderPlayRandomButton()) {
            if (!isTitePackLoaded()) sendNoTitlePackError();
            else
            {
#if TMNEXT
                if (!Permissions::PlayLocalMap())
                {
                    vec4 color = UI::HSV(0, 1, 0.5);
                    UI::ShowNotification(Icons::Times + " Missing permissions!", "You don't have permissions to play other maps than the official campaign.", color, 20000);
                } else {
#endif
                    RandomMapProcess = true;
                    isSearching = !isSearching;
                    QueueTimeStart = Time::get_Stamp();
#if TMNEXT
                }
#endif
            }
        }
    } else {
        if (RenderStopRandomButton()) {
            RandomMapProcess = true;
            isSearching = !isSearching;
        }
    }
    UI::SetCursorPos(vec2(0, 100));
    UI::Separator();
}

bool RenderPlayRandomButton() {
    bool pressed;
    vec2 pos_orig = UI::GetCursorPos();
    UI::SetCursorPos(vec2(UI::GetWindowSize().x/2.5, 50));
    UI::PushStyleColor(UI::Col::Button, vec4(0, 0.443, 0, 0.8));
    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0, 0.443, 0, 1));
    UI::PushStyleColor(UI::Col::ButtonActive, vec4(0, 0.443, 0, 0.6));
    pressed = UI::Button(Icons::Play + " Start searching");
    UI::PopStyleColor(3);
    UI::SetCursorPos(pos_orig);
    return pressed;
}

bool RenderStopRandomButton() {
    bool pressed;
    vec2 pos_orig = UI::GetCursorPos();
    UI::SetCursorPos(vec2(UI::GetWindowSize().x/2.5, 50));
    UI::PushStyleColor(UI::Col::Button, vec4(0.443, 0, 0, 0.8));
    UI::PushStyleColor(UI::Col::ButtonHovered, vec4(0.443, 0, 0, 1));
    UI::PushStyleColor(UI::Col::ButtonActive, vec4(0.443, 0, 0, 0.6));
    pressed = UI::Button(Icons::Times + " Stop searching");
    UI::PopStyleColor(3);
    UI::SetCursorPos(pos_orig);
    return pressed;
}

void RenderBody() {
    UI::Text("Recently played maps:");
    UI::Text("Coming soon!");
}

void RenderFooter() {
    UI::SetCursorPos(vec2(8, UI::GetWindowSize().y-26));
    UI::Separator();
    UI::SetCursorPos(vec2(8, UI::GetWindowSize().y-24));
    if (isSearching) {
        int HourGlassValue = (Time::Stamp / 2) % 3;
        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
        UI::Text(Hourglass + "Searching for a random map... ("+ Time::FormatString("%M:%S", Time::get_Stamp()-QueueTimeStart) +")");
    } else {
        UI::Text("Press " + Icons::Play + " to start searching");
    }
}