class Window
{
    bool isOpened = true;
    bool isInRMCMode = false;

    int flags = UI::WindowFlags::NoCollapse;

    string GetWindowTitle()
    {
        if (isInRMCMode)
            return MX_COLOR_STR + Icons::Random + " \\$z" + " RMC";
        else
            return MX_COLOR_STR + Icons::Random + " \\$z" + PLUGIN_NAME + " \\$555v"+Meta::ExecutingPlugin().get_Version();
    }

    Window()
    {}

    void Render()
    {
        if (!isOpened) return;

        UI::SetNextWindowSize(500,250);
        if (UI::Begin(GetWindowTitle(), isOpened, flags))
        {
            vec2 pos_orig = UI::GetCursorPos();
            UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.15, 50));
            if (!MX::RandomMapIsLoading) {
                if (UI::GreenButton(Icons::Play + " Play a random map")) {
                    startnew(MX::LoadRandomMap);
                }
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::Text(Hourglass + " Loading...");
            }
            UI::SetCursorPos(vec2(UI::GetWindowSize().x*0.60, 50));
            if (UI::ColoredButton(Icons::ClockO +" Random Map Challenge", 0.155)) {
                isInRMCMode = !isInRMCMode;
            }


            UI::SetCursorPos(vec2(0, 100));
            UI::Separator();
        }
        UI::End();
    }
}
Window window;