int oldTimestamp = 0;
int rand = 0;

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
    // On MP4, we need to find if a titlepack is loaded before adding the start/stop button
    if (isTitePackLoaded()) {
        if (!isSearching) {
            if (RenderPlayRandomButton()) {
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
        } else {
            if (RenderStopRandomButton()) {
                RandomMapProcess = true;
                isSearching = !isSearching;
            }
        }
        UI::SetCursorPos(vec2(0, 100));
        UI::Separator();
    }
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
    if (!isTitePackLoaded()) {
        UI::Text("\\$f00"+Icons::Times+" \\$zNo titlepack loaded");
    } else {
        if (isSearching) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + "Searching for a random map... ("+ Time::FormatString("%M:%S", Time::get_Stamp()-QueueTimeStart) +")");
        } else {
            int timestamps = (Time::Stamp / 25) % 2;
            if (oldTimestamp != timestamps) {
                rand = Math::Rand(0,4);
                oldTimestamp = timestamps;
            }
            // int timestamps = Math::Rand(0,4);
            string readyTxt;
            switch (rand) {
                case 0: readyTxt = "Waiting for inputs..."; break;
                case 1: readyTxt = "Click on the " + Icons::Play + " button to start playing maps"; break;
                case 2: readyTxt = "You can checkout the recently played maps list!"; break;
                case 3: readyTxt = "You can participate at Flink's Random Map Challenge at flinkblog.de/RMC"; break;
                case 4: readyTxt = "In the Random Map Challenge, you have to grab the maximum number of gold or author medals in 1 hour!"; break;
            }
            UI::Text("\\$666"+readyTxt);
        }
    }
}