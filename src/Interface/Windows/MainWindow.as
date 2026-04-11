class MainWindow : Window {
    string get_Title() override {
        return MX_COLOR_STR + Icons::Random + " \\$z" + PLUGIN_NAME + " \\$555v" + PLUGIN_VERSION;
    }

    void RenderWindow() override {
        MainUIView::Header();

        UI::Separator();

        UI::BeginTabBar("MainUITabBar", UI::TabBarFlags::FittingPolicyResizeDown);

        if (UI::BeginTabItem(Icons::ListUl + " Recently Played Maps")) {
            UI::BeginChild("RecentlyPlayedChild");
            MainUIView::RecentlyPlayedMapsTab();
            UI::EndChild();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::Cogs + " Settings")) {
            PluginSettings::Render();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::InfoCircle + " About")) {
            UI::BeginTabBar("MainUISettingsTabBar", UI::TabBarFlags::FittingPolicyResizeDown);

            if (UI::BeginTabItem(Icons::InfoCircle + " About")) {
                UI::BeginChild("AboutChild");
                RenderAboutTab();
                UI::EndChild();
                UI::EndTabItem();
            }

            if (UI::BeginTabItem(Icons::Tags + " Changelogs")) {
                UI::BeginChild("ChangelogsChild");
                MainUIView::ChangelogTabs();
                UI::EndChild();
                UI::EndTabItem();
            }

            UI::EndTabBar();
            UI::EndTabItem();
        }
        UI::EndTabBar();
    }
}
