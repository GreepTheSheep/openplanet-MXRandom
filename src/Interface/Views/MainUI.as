namespace MainUIView
{
    void Header()
    {
        vec2 pos_orig = UI::GetCursorPos();
        if (!MX::RandomMapIsLoading) {
            UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.36, 35));
            if (UI::GreenButton(Icons::Play + " Play a random map")) {
                startnew(MX::LoadRandomMap);
            }
        } else {
            UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.42, 35));
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        }
        UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.34, 70));
        if (UI::ColoredButton(Icons::ClockO +" Random Map Challenge", 0.155)) {
            window.isInRMCMode = !window.isInRMCMode;
        }

        UI::SetCursorPos(vec2(0, 100));
        UI::Separator();
    }

    void RecentlyPlayedMapsTab()
    {
        UI::Text("Recently played maps");
    }
}