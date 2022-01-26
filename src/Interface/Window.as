class Window
{
    bool isOpened = false;

    int flags = UI::WindowFlags::NoCollapse;

    Window()
    {}

    void Render()
    {
        if (!isOpened) return;

        UI::SetNextWindowSize(800,500);
        if (UI::Begin(Icons::Random + PLUGIN_NAME, isOpened, flags))
        {
            UI::Text("Hello World!");
        }
        UI::End();
    }
}
Window window;