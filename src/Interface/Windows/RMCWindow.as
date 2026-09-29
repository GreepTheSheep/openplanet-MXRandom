class RMCWindow : Window {
    int get_Flags() override {
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking | UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize;

        if (RMC::ShowTimer) {
            flags |= UI::WindowFlags::NoTitleBar;
        }

        return flags;
    }

    string get_Title() override {
        return MX_COLOR_STR + Icons::ClockO + "\\$z RMC";
    }

    void RenderWindow() override {
        if (RMC::ShowTimer) {
            RMC::RenderCurrentRun();
        } else {
            RMC::RenderMenu();
        }

        AlignWindow();
    }

    void AlignWindow() {
        if (PluginSettings::RMC_Y_Alignment != Y_Alignment::None || PluginSettings::RMC_X_Alignment != X_Alignment::None) {
            vec2 pos = UI::GetWindowPos();
            vec2 screen = Display::GetSize();
            vec2 window = UI::GetWindowSize();

            if (PluginSettings::RMC_X_Alignment != X_Alignment::None) {
                pos.x = (screen.x - window.x) * int(PluginSettings::RMC_X_Alignment - 1);
            }

            if (PluginSettings::RMC_Y_Alignment != Y_Alignment::None) {
                pos.y = (screen.y - window.y) * int(PluginSettings::RMC_Y_Alignment - 1);
            }

            UI::SetWindowPos(pos);
        }
    }
}
