class RunSettingsModalDialog : ModalDialog {
    RunSettingsModalDialog() {
        super(Icons::Cogs + " Run settings");
        m_size = vec2(600, 800);
    }

    void RenderDialog() override {
        UI::BeginTabBar("RunSettings");

        vec2 region = UI::GetContentRegionAvail();
        float scale = UI::GetScale();

        if (UI::BeginTabItem("General")) {
            UI::BeginChild("GeneralSettings", vec2(0, region.y - (40 * scale)));

            if (UI::OrangeButton("Reset to default")) {
                PluginSettings::ResetRMCSettings();
            }

            UI::PaddedHeaderSeparator("General settings");

            UI::PushFontSize(18);

            UI::SetItemText(Icons::Gamepad + " Mode: ", 250);
            if (UI::BeginCombo("##GamemodeSelect", tostring(PluginSettings::SelectedGameMode).Replace("_", " "))) {
#if TMNEXT
                for (uint i = 0; i <= RMC::GameMode::Together; i++) {
#else
                for (uint i = 0; i <= RMC::GameMode::Objective; i++) {
#endif
                    UI::PushID("GamemodeButton" + i);

                    if (UI::Selectable(tostring(RMC::GameMode(i)).Replace("_", " "), PluginSettings::SelectedGameMode == RMC::GameMode(i))) {
                        PluginSettings::SelectedGameMode = RMC::GameMode(i);
                    }

                    UI::PopID();
                }

                UI::EndCombo();
            }

            UI::SetItemText(Icons::ThLarge + " Category: ", 250);
            if (UI::BeginCombo("##CategorySelect", tostring(PluginSettings::SelectedCategory).Replace("_", " "))) {
                for (uint i = 0; i <= RMC::Category::Custom; i++) {
                    UI::PushID("CategoryButton" + i);

                    if (UI::Selectable(tostring(RMC::Category(i)).Replace("_", " "), PluginSettings::SelectedCategory == RMC::Category(i))) {
                        PluginSettings::SelectedCategory = RMC::Category(i);
                    }

                    UI::SetItemTooltip(RMC::CategoryDescriptions[i]);

                    UI::PopID();
                }

                UI::EndCombo();
            }

            UI::SetItemText(Icons::Kenney::Badge + " Goal medal: ", 250);
            if (UI::BeginCombo("##GoalMedal", tostring(PluginSettings::GoalMedal))) {
                for (uint i = 0; i < Medals::Last; i++) {
                    if (UI::Selectable(tostring(Medals(i)), PluginSettings::GoalMedal == Medals(i))) {
                        PluginSettings::GoalMedal = Medals(i);
                    }
                }

                UI::EndCombo();
            }

            bool canCustomize = PluginSettings::SelectedCategory == RMC::Category::Custom || PluginSettings::SelectedGameMode == RMC::GameMode::Objective;

            if (!canCustomize) {
                UI::NewLine();
                Controls::FrameInfo(Icons::InfoCircle + " Select the Custom category to edit the following settings");
            }

            UI::PaddedHeaderSeparator("Gamemode settings");

            UI::BeginDisabled(!canCustomize);

            switch (PluginSettings::SelectedGameMode) {
                case RMC::GameMode::Survival:
                    UI::SetItemText(Icons::ClockO + " Max timer: ", 250);
                    PluginSettings::RMS_MaxTimer = UI::InputInt("##RMSTimer", PluginSettings::RMS_MaxTimer);
                    UI::SetItemTooltip("The maximum duration of the timer, in minutes.");

                    UI::SetItemText(Icons::Undo + " Restored time: ", 250);
                    PluginSettings::RMS_TimeBack = UI::InputInt("##RMSTimerBack", PluginSettings::RMS_TimeBack);
                    UI::SetItemTooltip("The time restored when getting a goal medal, in minutes.");

                    break;
                case RMC::GameMode::Objective:
                    UI::SetItemText(Icons::FlagCheckered + " Goal: ", 250);
                    PluginSettings::RMO_Goal = Math::Max(1, UI::InputInt("##ObjectiveGoal", PluginSettings::RMO_Goal));
                    UI::SetItemTooltip("The number of medals set as the goal.");

                    break;
                case RMC::GameMode::Together:
                    UI::SetItemText(Icons::ClockO + " Duration: ", 250);
                    PluginSettings::RMT_MaxTimer = UI::InputInt("##RMTMaxTimer", PluginSettings::RMT_MaxTimer);
                    UI::SetItemTooltip("The duration of the run, in minutes.");

                    UI::SetItemText(Icons::FastForward + " Free skips: ", 250);
                    PluginSettings::RMT_FreeSkips = UI::InputInt("##RMTFreeSkips", PluginSettings::RMT_FreeSkips);
                    UI::SetItemTooltip("Free skips available per run.");

                    break;
                case RMC::GameMode::Challenge:
                default:
                    UI::SetItemText(Icons::ClockO + " Duration: ", 250);
                    PluginSettings::RMC_MaxTimer = UI::InputInt("##RMCMaxTimer", PluginSettings::RMC_MaxTimer);
                    UI::SetItemTooltip("The duration of the run, in minutes.");

                    UI::SetItemText(Icons::FastForward + " Free skips: ", 250);
                    PluginSettings::RMC_FreeSkips = UI::InputInt("##RMCFreeSkips", PluginSettings::RMC_FreeSkips);
                    UI::SetItemTooltip("Free skips available per run.");

                    break;
            }

            UI::EndDisabled();

            if (PluginSettings::SelectedCategory != RMC::Category::Custom && PluginSettings::SelectedGameMode == RMC::GameMode::Objective) {
                UI::NewLine();
                Controls::FrameInfo(Icons::InfoCircle + " Select the Custom category to edit the following settings ");
            }

            UI::PaddedHeaderSeparator("Other settings");

            UI::BeginDisabled(PluginSettings::SelectedCategory != RMC::Category::Custom);

            PluginSettings::CustomSearchFilters = UI::Checkbox(Icons::ManiaExchange + " " + SHORT_MX + " search filters", PluginSettings::CustomSearchFilters);
            UI::SetItemTooltip("Use custom " + SHORT_MX + " search filters.\n\nCustomize the filters in the \"Filtering\" tab.");

            UI::SameLine();
            UI::CenterAlign();
            PluginSettings::SkipDuplicateMaps = UI::Checkbox(Icons::Clipboard + " Skip duplicated maps", PluginSettings::SkipDuplicateMaps);
            UI::SetItemTooltip("Skip maps that were already played during the run.");

            PluginSettings::FilterLowEffort = UI::Checkbox(Icons::Filter + " Filter out low effort maps", PluginSettings::FilterLowEffort);
            UI::SetItemTooltip("Try to detect and skip low effort maps.\n\nE.g., RMC free, randomly generated tracks, maps created for streamers, and more.");

            UI::SameLine();
            UI::CenterAlign();
            PluginSettings::FilterUntagged = UI::Checkbox(Icons::Tag + " Filter out untagged maps", PluginSettings::FilterUntagged);
            UI::SetItemTooltip("Try to detect and skip maps missing default filtered tags.\n\nE.g., untagged Kacky / Altered Nadeo maps.");

            PluginSettings::CalculateMedals = UI::Checkbox(Icons::Calculator + " Calculate default medals", PluginSettings::CalculateMedals);
            UI::SetItemTooltip("Calculate and use default medal times if the medals were edited to be harder.\n\nEnable \"Display goal times\" in the settings to see the new times.");

#if TMNEXT
            UI::SameLine();
            UI::CenterAlign();
            PluginSettings::SkipUnbeatenMedals = UI::Checkbox(Icons::ListOl + " Filter out unbeaten goal medals", PluginSettings::SkipUnbeatenMedals);
            UI::SetItemTooltip("Skip maps where the goal medal is unbeaten.");

            PluginSettings::SkipUnbeatenMaps = UI::Checkbox(Icons::FlagO + " Filter out unfinished maps", PluginSettings::SkipUnbeatenMaps);
            UI::SetItemTooltip("Skip maps with no finishes.");

            if (PluginSettings::SelectedGameMode != RMC::GameMode::Together) {
                UI::SameLine();
                UI::CenterAlign();
                PluginSettings::InvalidateGhosts = UI::Checkbox(Icons::EyeSlash + " Disallow watching ghosts", PluginSettings::InvalidateGhosts);
                UI::SetItemTooltip("Watching a ghost will invalidate all further attempts on a map.");

#if DEPENDENCY_MLFEEDRACEDATA
                PluginSettings::UseNoRespawnTime = UI::Checkbox(Icons::Hourglass + " Use no-respawn time", PluginSettings::UseNoRespawnTime);
                UI::SetItemTooltip("Count no-respawn time towards goal times.\n\nOnly useful in Race maps.");
#else
                UI::BeginDisabled();
                UI::Checkbox(Icons::Hourglass + " Use no-respawn time", false);
                UI::EndDisabled();

                UI::SetItemTooltip("Count no-respawn time towards goal times.\n\nInstall MLFeed to use this setting.");
#endif
            }
#endif

            UI::EndDisabled();

            UI::PopFontSize();

            UI::EndChild();

            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Filtering")) {
            UI::BeginChild("MapFilters", vec2(0, region.y - (40 * scale)));

            if (!PluginSettings::CustomSearchFilters) {
                Controls::FrameWarning(Icons::ExclamationTriangle + " " + SHORT_MX + " Search Filters setting is disabled, filters will be ignored");
            }

            PluginSettings::RenderSearchingSettingTab();

            UI::EndChild();
            UI::EndTabItem();
        }

        UI::EndTabBar();

        UI::PushFontSize(18);

        vec2 button = UI::MeasureButton("Close");
        float itemSpacing = UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x;
        UI::NewLine();
        UI::HPadding(int(region.x - button.x - itemSpacing));

        if (UI::Button("Close")) {
            Close();
        }

        UI::PopFontSize();
    }
}
