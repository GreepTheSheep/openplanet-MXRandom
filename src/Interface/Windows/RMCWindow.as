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
    }
}
