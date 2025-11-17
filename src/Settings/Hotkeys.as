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
        if (UI::BeginCombo("Quick map hotkey", GetKeyName(S_QuickMapKey))) {
            for (int i = 0; i <= 254; i++) {
                VirtualKey key = VirtualKey(i);
                string keyName = GetKeyName(key);
                bool taken = key != S_QuickMapKey && IsKeyUsed(key);

                if (keyName == "") {
                    continue;
                }

                UI::BeginDisabled(taken);

                if (UI::Selectable(keyName, S_QuickMapKey == key)) {
                    S_QuickMapKey = key;
                }

                if (taken) {
                    UI::SetItemTooltip("Key already used for a different setting!");
                }

                UI::EndDisabled();

            }

            UI::EndCombo();
        }

        UI::SetNextItemWidth(225);
        if (UI::BeginCombo("Show/Hide window hotkey", GetKeyName(S_WindowToggle))) {
            for (int i = 0; i <= 254; i++) {
                VirtualKey key = VirtualKey(i);
                string keyName = GetKeyName(key);
                bool taken = key != S_WindowToggle && IsKeyUsed(key);

                if (keyName == "") {
                    continue;
                }

                UI::BeginDisabled(taken);

                if (UI::Selectable(keyName, S_WindowToggle == key)) {
                    S_WindowToggle = key;
                }

                if (taken) {
                    UI::SetItemTooltip("Key already used for a different setting!");
                }

                UI::EndDisabled();
            }

            UI::EndCombo();
        }
    }

    string GetKeyName(VirtualKey key) {
        if (key == VirtualKey(0)) {
            return "None";
        }

        const string name = tostring(key);

        if (name == tostring(int(key))) {
            return "";
        }

        return name;
    }

    bool IsKeyUsed(VirtualKey key) {
        if (key == VirtualKey(0)) {
            return false;
        }

        array<VirtualKey> usedKeys = {
            S_QuickMapKey,
            S_WindowToggle
        };

        return usedKeys.Find(key) > -1;
    }
}
