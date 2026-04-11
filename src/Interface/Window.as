abstract class Window {
    protected bool m_opened = false;

    bool get_IsOpened() { return m_opened; }
    void set_IsOpened(bool i) { m_opened = i; }

    void Open() { IsOpened = true; }
    void Close() { IsOpened = false; }
    void Toggle() { IsOpened = !IsOpened; }

    int get_Flags() { return UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking; }
    string get_Title() { return ""; }

    void Render() {
        if (!this.IsOpened) {
            return;
        }

        if (PluginSettings::HideWithGameUI && !UI::IsGameUIVisible()) {
            return;
        }

        if (PluginSettings::HideWithOP && !UI::IsOverlayShown()) {
            return;
        }

        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
        UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
        UI::SetNextWindowSize(600, 400, UI::Cond::FirstUseEver);

        if (UI::Begin(this.Title, this.IsOpened, this.Flags)) {
            RenderWindow();
        }

        UI::End();
        UI::PopStyleVar(4);
    }

    void RenderWindow() {}
}
