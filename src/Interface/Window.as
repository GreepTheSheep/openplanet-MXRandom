class Window
{
    bool isOpened = true;
    bool isInRMCMode = false;

    int GetFlags()
    {
        int flags = UI::WindowFlags::NoCollapse | UI::WindowFlags::NoDocking;
        if (isInRMCMode) flags |=  UI::WindowFlags::NoResize | UI::WindowFlags::AlwaysAutoResize;
        return flags;
    }

    string GetWindowTitle()
    {
        if (isInRMCMode)
            return MX_COLOR_STR + Icons::Random + " \\$z" + " RMC";
        else
            return MX_COLOR_STR + Icons::Random + " \\$z" + PLUGIN_NAME + " \\$555v"+PLUGIN_VERSION;
    }

    void Render()
    {
        if (!isOpened)
        {
            isInRMCMode = false;
            return;
        }

        UI::SetNextWindowSize(600,400);
        if (UI::Begin(GetWindowTitle(), isOpened, GetFlags()))
        {
            if (!isInRMCMode)
            {
                MainUIView::Header();
                UI::BeginTabBar("MainUITabBar", UI::TabBarFlags::FittingPolicyResizeDown);
                if (UI::BeginTabItem(Icons::ListUl + " Recently Played Maps"))
                {
                    UI::BeginChild("RecentlyPlayedChild");
                    MainUIView::RecentlyPlayedMapsTab();
                    UI::EndChild();
                    UI::EndTabItem();
                }

                if (UI::BeginTabItem(Icons::Cogs + " Settings"))
                {
                    UI::BeginTabBar("MainUISettingsTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
                    if (UI::BeginTabItem(Icons::Cog + " Searching"))
                    {
                        UI::BeginChild("SearchingChild");
                        PluginSettings::RenderSearchingSettingTab();
                        UI::EndChild();
                        UI::EndTabItem();
                    }
                    if (UI::BeginTabItem(Icons::Cog + " Menu"))
                    {
                        UI::BeginChild("MenuChild");
                        PluginSettings::RenderMenuSettings();
                        UI::EndChild();
                        UI::EndTabItem();
                    }
                    UI::EndTabBar();
                    UI::EndTabItem();
                }

                if (UI::BeginTabItem(Icons::InfoCircle + " About"))
                {
                    UI::BeginTabBar("MainUISettingsTabBar", UI::TabBarFlags::FittingPolicyResizeDown);
                    if (UI::BeginTabItem(Icons::InfoCircle + " About"))
                    {
                        UI::BeginChild("AboutChild");
                        RenderAboutTab();
                        UI::EndChild();
                        UI::EndTabItem();
                    }
                    if (UI::BeginTabItem(Icons::Tags + " Changelogs"))
                    {
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
            else
            {
                if (UI::ColoredButton("Go back", 0.155))
                {
                    isInRMCMode = false;
                }
            }
        }
        UI::End();
    }
}
Window window;