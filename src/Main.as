MainWindow mainMenu;
RMCWindow rmcMenu;
DebugWindow debugMenu;

void RenderMenu() {
#if TMNEXT
    if (!hasPermissions) return;
#endif
    if (UI::BeginMenu(MX_COLOR_STR + Icons::Random + " \\$z" + SHORT_MX + " Randomizer" + (MX::APIDown ? " \\$f00" + Icons::Server : ""))) {
        if (MX::APIDown && !IS_DEV_MODE) {
            if (!MX::APIRefreshing) {
                UI::Text("\\$fc0" + Icons::ExclamationTriangle + " \\$z" + MX_NAME + " is not responding. It might be down.");
                if (UI::Button("Retry")) {
                    startnew(MX::FetchMapTags);
                }
            } else {
                UI::TextDisabled(Icons::AnimatedHourglass + " Loading...");
            }
        } else {
            if (TM::CurrentTitlePack() == "") {
                UI::TextDisabled("You must select a title pack first.");
            } else {
#if TMNEXT
                if (Permissions::PlayLocalMap()) {
#endif
                    if (UI::MenuItem(Icons::Play + " Quick map")) {
                        startnew(MX::LoadRandomMap, false);
                    }
                    UI::SetItemTooltip("This will open a random map from " + MX_NAME + ".");

                    if (UI::MenuItem(Icons::Play + " Quick map (with filters)")) {
                        startnew(MX::LoadRandomMap, true);
                    }
                    UI::SetItemTooltip("This will open a random map from " + MX_NAME + " based on the filters applied in the settings.");

                    if (UI::MenuItem(MX_COLOR_STR + Icons::Random + " \\$zMain Menu", "", mainMenu.IsOpened)) {
                        mainMenu.Toggle();
                    }
                    UI::Separator();
                    if (UI::MenuItem(MX_COLOR_STR + Icons::ClockO + " \\$zRandom Map Challenge", "", rmcMenu.IsOpened)) {
                        rmcMenu.Toggle();
                    }
#if TMNEXT
                } else {
                    UI::Text(Icons::TimesCircle + " You don't have the permissions to play local maps");
                }
#endif
            }
        }
        UI::EndMenu();
    }
}

void RenderInterface() {
#if TMNEXT
    if (!hasPermissions) return;
#endif
    mainMenu.Render();
    debugMenu.Render();
}

void Render() {
#if TMNEXT
    if (!hasPermissions) return;
#endif
    rmcMenu.Render();
    Renderables::Render();
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
#if TMNEXT
    if (!hasPermissions) return UI::InputBlocking::DoNothing;
#endif

    if (PluginSettings::ListeningForKey) {
        PluginSettings::AssignHotkey(key);
        return UI::InputBlocking::Block;
    }

    if (key == PluginSettings::S_QuickMapKey && ShouldLoadRandomMap()) {
        startnew(MX::LoadRandomMap, false);
        return UI::InputBlocking::Block;
    } 
    
    if (key == PluginSettings::S_WindowToggle) {
        rmcMenu.Toggle();
        return UI::InputBlocking::Block;
    }

    return UI::InputBlocking::DoNothing;
}

bool ShouldLoadRandomMap() {
    if (MX::APIDown || MX::RandomMapIsLoading) {
        return false;
    }

    if (RMC::currentRun.IsRunning || RMC::currentRun.IsStarting) {
        return false;
    }

    if (UI::WantCaptureKeyboard()) {
        return false;
    }

    if (TM::IsInServer()) {
        return false;
    }

    return true;
}

void Main() {
#if TMNEXT
    if (!hasPermissions) {
        Log::Error("You need Club / Standard access to use this plugin!", true);
        return;
    }

    startnew(RMCLeaderAPI::FetchAccountId);
#endif

    Fonts::Load();

    DataManager::EnsureSaveFileFolderPresent();
    DataManager::ConvertSaves();

    await(startnew(MX::FetchMapTags));

#if TMNEXT
    startnew(MX::GetImpossibleMaps);
#endif

    if (DataJson.GetType() == Json::Type::Null) {
        if (DataJsonFromDataFolder.GetType() != Json::Type::Null) {
            DataManager::InitData(false);
            DataJson = DataJsonFromDataFolder;
            DataManager::SaveData();
            IO::Delete(DATA_JSON_LOCATION_DATADIR);
        } else if (DataJsonOldVersion.GetType() == Json::Type::Null) {
            DataManager::InitData();
            UI::ShowNotification("\\$afa" + Icons::InfoCircle + " Thanks for installing " + PLUGIN_NAME + "!","No data file was detected, that means it's your first install. Welcome!", 15000);
        } else {
            if (Versioning::IsVersion1(DataJsonOldVersion["version"])) {
                Log::Trace("Data JSON old version is " + Json::Write(DataJsonOldVersion["version"]) + ", showing migration wizard");
                Renderables::Add(DataMigrationWizardModalDialog());
            }
        }

        // Migration is not needed
        Migration::MigratedToMX2 = true;
    } else {
        DataManager::CheckData();

        if (!Migration::MigratedToMX2) {
            Migration::MigrateMX1Settings();

            if (DataManager::IsDataMX2()) {
                // Setting didn't save after migrating, we can ignore
                Migration::MigratedToMX2 = true;
            } else {
                MX2MigrationWizardModalDialog migrationDialog = MX2MigrationWizardModalDialog();
                Renderables::Add(migrationDialog);

                while (!migrationDialog.migrationCompleted && !Migration::v2_requestError) {
                    yield();
                }

                if (migrationDialog.migrationCompleted) {
                    Migration::MigratedToMX2 = true;
                }
            }
        }
    }
    RMC::FetchConfig();
#if DEPENDENCY_NADEOSERVICES
    MXNadeoServicesGlobal::LoadNadeoLiveServices();
#endif
}
