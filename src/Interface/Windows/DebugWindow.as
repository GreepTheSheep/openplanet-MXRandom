class DebugWindow : Window {
    int get_Flags() override {
        return UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking;
    }

    string get_Title() override {
        return Icons::Bug + " Debug Window";
    }

    void RenderWindow() override {
        UI::BeginTabBar("DebugBar", UI::TabBarFlags::FittingPolicyResizeDown);

        if (UI::BeginTabItem(Icons::ListUl + " Run")) {
            UI::BeginChild("RunDataChild");
            DebugView::RenderRunData();
            UI::EndChild();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::Map + " Played Maps")) {
            UI::BeginChild("MapsChild");
            DebugView::RenderRunMaps();
            UI::EndChild();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::Cogs + " Settings")) {
            UI::BeginChild("SettingsChild");
            DebugView::RenderRunSettings();
            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndTabBar();
    }
}
