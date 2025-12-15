namespace PluginSettings {
    [Setting hidden]
    VirtualKey S_QuickMapKey = VirtualKey(0);

    [Setting hidden]
    VirtualKey S_QuickMapFiltersKey = VirtualKey(0);

    [Setting hidden]
    VirtualKey S_WindowToggle = VirtualKey(0);

    bool DetectingQuickMapKey = false;
    bool DetectingQuickMapFiltersKey = false;
    bool DetectingWindowKey = false;

    bool get_ListeningForKey() {
        return DetectingQuickMapKey || DetectingQuickMapFiltersKey || DetectingWindowKey;
    }

    void StopListeningForKey() {
        DetectingQuickMapKey = false;
        DetectingQuickMapFiltersKey = false;
        DetectingWindowKey = false;
    }

    [SettingsTab name="Hotkeys" order="3" icon="KeyboardO"]
    void RenderHotkeySettingTab() {
        if (UI::OrangeButton("Reset to default")) {
            S_QuickMapKey = VirtualKey(0);
            S_QuickMapFiltersKey = VirtualKey(0);
            S_WindowToggle = VirtualKey(0);
            StopListeningForKey();
        }

        RenderHotkeyCombo("Quick map hotkey", S_QuickMapKey);

        UI::SameLine();

        UI::BeginDisabled(ListeningForKey);

        if (DetectingQuickMapKey) {
            UI::Text("Press a key");
        } else if (UI::GreyButton("Detect##QuickMap")) {
            DetectingQuickMapKey = true;
        }

        UI::EndDisabled();

        RenderHotkeyCombo("Quick map (with filters) hotkey", S_QuickMapFiltersKey);

        UI::SameLine();

        UI::BeginDisabled(ListeningForKey);

        if (DetectingQuickMapFiltersKey) {
            UI::Text("Press a key");
        } else if (UI::GreyButton("Detect##QuickMapFilters")) {
            DetectingQuickMapFiltersKey = true;
        }

        UI::EndDisabled();

        RenderHotkeyCombo("Show/Hide RMC window hotkey", S_WindowToggle);

        UI::SameLine();

        UI::BeginDisabled(ListeningForKey);

        if (DetectingWindowKey) {
            UI::Text("Press a key");
        } else if (UI::GreyButton("Detect##Window")) {
            DetectingWindowKey = true;
        }

        UI::EndDisabled();
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
            S_QuickMapFiltersKey,
            S_WindowToggle
        };

        return usedKeys.Find(key) > -1;
    }

    void RemoveHotkey(VirtualKey key) {
        if (!IsKeyUsed(key)) {
            return;
        }

        if (S_QuickMapKey == key) {
            S_QuickMapKey = VirtualKey(0);
        }

        if (S_QuickMapFiltersKey == key) {
            S_QuickMapFiltersKey = VirtualKey(0);
        }

        if (S_WindowToggle == key) {
            S_WindowToggle = VirtualKey(0);
        }
    }

    void AssignHotkey(VirtualKey key) {
        if (!ListeningForKey) {
            return;
        }

        RemoveHotkey(key);

        if (DetectingQuickMapKey) {
            S_QuickMapKey = key;
        } else if (DetectingQuickMapFiltersKey) {
            S_QuickMapFiltersKey = key;
        } else if (DetectingWindowKey) {
            S_WindowToggle = key;
        }

        StopListeningForKey();
    }

    void RenderHotkeyCombo(const string &in label, VirtualKey currentKey) {
        UI::SetNextItemWidth(175);

        if (UI::BeginCombo(label, GetKeyName(currentKey))) {
            for (int i = 0; i <= 254; i++) {
                VirtualKey key = VirtualKey(i);
                string keyName = GetKeyName(key);
                bool taken = key != currentKey && IsKeyUsed(key);

                if (keyName == "") {
                    continue;
                }

                UI::BeginDisabled(taken);

                if (UI::Selectable(keyName, currentKey == key)) {
                    AssignHotkey(key);
                }

                if (taken) {
                    UI::SetItemTooltip("Key already used for a different setting!");
                }

                UI::EndDisabled();
            }

            UI::EndCombo();
        }
    }
}
