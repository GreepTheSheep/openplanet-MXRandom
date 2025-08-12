namespace PluginSettings {
    void Render() {
        UI::BeginTabBar("RMCSettingsTab", UI::TabBarFlags::FittingPolicyResizeDown);
        if (UI::BeginTabItem(Icons::Cogs + " Random Map Challenge"))
        {
            PluginSettings::RenderRMCSettingTab();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::Filter + " Filters")) {
            PluginSettings::RenderSearchingSettingTab();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::KeyboardO + " Hotkeys")) {
            PluginSettings::RenderHotkeySettingTab();
            UI::EndTabItem();
        }

        if (UI::BeginTabItem(Icons::Wrench + " Advanced")) {
            PluginSettings::RenderAdvancedSettings();
            UI::EndTabItem();
        }

        UI::EndTabBar();
    }
}
