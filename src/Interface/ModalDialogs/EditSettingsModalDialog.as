class EditSettingsModalDialog : ModalDialog {
    RunSettings m_settings;
    RMC::GameMode m_mode;

    EditSettingsModalDialog(RMC::GameMode runMode, RunSettings runSettings) {
        super(Icons::Cogs + " Run settings");
        m_size = vec2(600, 700);
        m_mode = runMode;
        m_settings = runSettings;
    }

    void RenderDialog() override {
        UI::BeginTabBar("RunSettings");

        vec2 region = UI::GetContentRegionAvail();
        float scale = UI::GetScale();

        if (UI::BeginTabItem("General")) {
            UI::BeginChild("GeneralSettings", vec2(0, region.y - (40 * scale)));

            UI::PushFontSize(18);

            UI::PaddedHeaderSeparator("Gamemode settings");

            switch (m_mode) {
                case RMC::GameMode::Survival:
                    UI::SetItemText(Icons::ClockO + " Max timer: ", 250);
                    m_settings.MaxTimer = UI::InputInt("##RMSTimer", m_settings.MaxTimer);
                    UI::SetItemTooltip("The maximum duration of the timer, in minutes.");

                    UI::SetItemText(Icons::Undo + " Restored time: ", 250);
                    m_settings.RMS_TimeBack = UI::InputInt("##RMSTimerBack", m_settings.RMS_TimeBack);
                    UI::SetItemTooltip("The time restored when getting a goal medal, in minutes.");

                    break;
                case RMC::GameMode::Objective:
                    UI::SetItemText(Icons::FlagCheckered + " Goal: ", 250);
                    m_settings.RMO_Goal = Math::Max(1, UI::InputInt("##ObjectiveGoal", m_settings.RMO_Goal));
                    UI::SetItemTooltip("The number of medals set as the goal.");

                    break;
                case RMC::GameMode::Together:
                    UI::SetItemText(Icons::ClockO + " Duration: ", 250);
                    m_settings.MaxTimer = UI::InputInt("##RMTMaxTimer", m_settings.MaxTimer);
                    UI::SetItemTooltip("The duration of the run, in minutes.");

                    UI::SetItemText(Icons::FastForward + " Free skips: ", 250);
                    m_settings.FreeSkips = UI::InputInt("##RMTFreeSkips", m_settings.FreeSkips);
                    UI::SetItemTooltip("Free skips available per run.");

                    break;
                case RMC::GameMode::Challenge:
                default:
                    UI::SetItemText(Icons::ClockO + " Duration: ", 250);
                    m_settings.MaxTimer = UI::InputInt("##RMCMaxTimer", m_settings.MaxTimer);
                    UI::SetItemTooltip("The duration of the run, in minutes.");

                    UI::SetItemText(Icons::FastForward + " Free skips: ", 250);
                    m_settings.FreeSkips = UI::InputInt("##RMCFreeSkips", m_settings.FreeSkips);
                    UI::SetItemTooltip("Free skips available per run.");

                    break;
            }

            UI::PaddedHeaderSeparator("Other settings");

            m_settings.CustomSearchFilters = UI::Checkbox(Icons::ManiaExchange + " " + SHORT_MX + " search filters", m_settings.CustomSearchFilters);
            UI::SetItemTooltip("Use custom " + SHORT_MX + " search filters.\n\nCustomize the filters in the \"Filtering\" tab.");

            UI::SameLine();
            UI::CenterAlign();
            m_settings.SkipDuplicateMaps = UI::Checkbox(Icons::Clipboard + " Skip duplicated maps", m_settings.SkipDuplicateMaps);
            UI::SetItemTooltip("Skip maps that were already played during the run.");

            m_settings.FilterLowEffort = UI::Checkbox(Icons::Filter + " Filter out low effort maps", m_settings.FilterLowEffort);
            UI::SetItemTooltip("Try to detect and skip low effort maps.\n\nE.g., RMC free, randomly generated tracks, maps created for streamers, and more.");

            UI::SameLine();
            UI::CenterAlign();
            m_settings.FilterUntagged = UI::Checkbox(Icons::Tag + " Filter out untagged maps", m_settings.FilterUntagged);
            UI::SetItemTooltip("Try to detect and skip maps missing default filtered tags.\n\nE.g., untagged Kacky / Altered Nadeo maps.");

            m_settings.CalculateMedals = UI::Checkbox(Icons::Calculator + " Calculate default medals", m_settings.CalculateMedals);
            UI::SetItemTooltip("Calculate and use default medal times if the medals were edited to be harder.\n\nEnable \"Display goal times\" in the settings to see the new times.");

#if TMNEXT
            UI::SameLine();
            UI::CenterAlign();
            m_settings.SkipUnbeatenMedals = UI::Checkbox(Icons::ListOl + " Filter out unbeaten goal medals", m_settings.SkipUnbeatenMedals);
            UI::SetItemTooltip("Skip maps where the goal medal is unbeaten.");

            m_settings.SkipUnbeatenMaps = UI::Checkbox(Icons::FlagO + " Filter out unfinished maps", m_settings.SkipUnbeatenMaps);
            UI::SetItemTooltip("Skip maps with no finishes.");

            if (m_mode != RMC::GameMode::Together) {
                UI::SameLine();
                UI::CenterAlign();
                m_settings.InvalidateGhosts = UI::Checkbox(Icons::EyeSlash + " Disallow watching ghosts", m_settings.InvalidateGhosts);
                UI::SetItemTooltip("Watching a ghost will invalidate all further attempts on a map.");

#if DEPENDENCY_MLFEEDRACEDATA
                m_settings.UseNoRespawnTime = UI::Checkbox(Icons::Hourglass + " Use no-respawn time", m_settings.UseNoRespawnTime);
                UI::SetItemTooltip("Count no-respawn time towards goal times.\n\nOnly useful in Race maps.");
#else
                UI::BeginDisabled();
                UI::Checkbox(Icons::Hourglass + " Use no-respawn time", false);
                UI::EndDisabled();

                UI::SetItemTooltip("Count no-respawn time towards goal times.\n\nInstall MLFeed to use this setting.");
#endif
            }
#endif

            UI::PopFontSize();

            UI::EndChild();

            UI::EndTabItem();
        }

        if (UI::BeginTabItem("Filtering")) {
            UI::BeginChild("MapFilters", vec2(0, region.y - (40 * scale)));

            if (!m_settings.CustomSearchFilters) {
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

            RMC::currentRun.UpdateSettings(m_settings);
        }

        UI::PopFontSize();
    }
}
