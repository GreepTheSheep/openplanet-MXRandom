class Window {
    bool isOpened = false;
    bool isInRMCMode = false;

    int GetFlags() {
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking;

        if (isInRMCMode) {
            flags |=  UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize;
            if (RMC::ShowTimer) flags |= UI::WindowFlags::NoTitleBar;
        }

        return flags;
    }

    string GetWindowTitle() {
        if (isInRMCMode) {
            return MX_COLOR_STR + Icons::ClockO + " \\$z" + " RMC";
        }

        return MX_COLOR_STR + Icons::Random + " \\$z" + PLUGIN_NAME + " \\$555v" + PLUGIN_VERSION;
    }

    void Render() {
        if (!isOpened) {
            isInRMCMode = false;
            return;
        }

        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(10, 10));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 10.0);
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(10, 6));
        UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(.5, .5));
        UI::SetNextWindowSize(600, 400, UI::Cond::FirstUseEver);

        if (UI::Begin(GetWindowTitle(), isOpened, GetFlags())) {
            if (!isInRMCMode) {
                MainUIView::Header();
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
            } else {
                if (!RMC::ShowTimer) RMC::RenderRMCMenu();
                else RMC::RenderRMCTimer();
            }
        }

        UI::End();
        UI::PopStyleVar(4);
    }
}

Window window;