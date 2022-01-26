class Window
{
    bool isOpened = false;

    int flags = UI::WindowFlags::NoCollapse;

    Window()
    {}

    void Render()
    {
        if (!isOpened) return;

        UI::SetNextWindowSize(650,450);
        if (UI::Begin(MX_COLOR_STR + Icons::Random + " \\$z" + PLUGIN_NAME + " \\$555v"+Meta::ExecutingPlugin().get_Version(), isOpened, flags))
        {
            if (!MX::RandomMapIsLoading) {
                if (UI::GreenButton(Icons::Play + " Pick a random map")) {
                    startnew(MX::LoadRandomMap);
                }
            } else {
                UI::Text("Loading...");
            }
            UI::SetCursorPos(vec2(0, 100));
            UI::Separator();
        }
        UI::End();
    }
}
Window mainWindow;