namespace PluginSettings {
    [Setting hidden]
    VirtualKey S_QuickMapKey = VirtualKey(0);

    [SettingsTab name="Hotkeys" order="3" icon="KeyboardO"]
    void RenderHotkeySettingTab() {
        if (UI::OrangeButton("Reset to default")) {
            S_QuickMapKey = VirtualKey(0);
        }

        UI::SetNextItemWidth(225);
        if (UI::BeginCombo("Quick map hotkey", S_QuickMapKey == VirtualKey(0) ? "None" : tostring(S_QuickMapKey))) {
            for (int i = 0; i <= 254; i++) {
                if (tostring(VirtualKey(i)) == tostring(i)) {
                    continue;
                }

                if (UI::Selectable(tostring(VirtualKey(i)), S_QuickMapKey == VirtualKey(i))) {
                    S_QuickMapKey = VirtualKey(i);
                }
            }

            UI::EndCombo();
        }
    }
}
