namespace PluginSettings {
    [Setting hidden]
    VirtualKey S_QuickMapKey = VirtualKey(0);

    [Setting hidden]
    VirtualKey S_WindowToggle = VirtualKey(0);

    [SettingsTab name="Hotkeys" order="3" icon="KeyboardO"]
    void RenderHotkeySettingTab() {
        if (UI::OrangeButton("Reset to default")) {
            S_QuickMapKey = VirtualKey(0);
            S_WindowToggle = VirtualKey(0);
        }

        UI::SetNextItemWidth(225);
        if (UI::BeginCombo("Quick map hotkey", S_QuickMapKey == VirtualKey(0) ? "None" : tostring(S_QuickMapKey))) {
            for (int i = 0; i <= 254; i++) {
                if (tostring(VirtualKey(i)) == tostring(i)) {
                    continue;
                }

                UI::BeginDisabled(S_WindowToggle == VirtualKey(i));

                if (UI::Selectable(tostring(VirtualKey(i)), S_QuickMapKey == VirtualKey(i))) {
                    S_QuickMapKey = VirtualKey(i);
                }

                if (S_WindowToggle == VirtualKey(i)) {
                    UI::SetItemTooltip("Key already used for a different setting!");
                }

                UI::EndDisabled();

            }

            UI::EndCombo();
        }

        UI::SetNextItemWidth(225);
        if (UI::BeginCombo("Show/Hide window hotkey", S_WindowToggle == VirtualKey(0) ? "None" : tostring(S_WindowToggle))) {
            for (int i = 0; i <= 254; i++) {
                if (tostring(VirtualKey(i)) == tostring(i)) {
                    continue;
                }

                UI::BeginDisabled(S_QuickMapKey == VirtualKey(i));

                if (UI::Selectable(tostring(VirtualKey(i)), S_WindowToggle == VirtualKey(i))) {
                    S_WindowToggle = VirtualKey(i);
                }

                if (S_QuickMapKey == VirtualKey(i)) {
                    UI::SetItemTooltip("Key already used for a different setting!");
                }

                UI::EndDisabled();
            }

            UI::EndCombo();
        }
    }
}
