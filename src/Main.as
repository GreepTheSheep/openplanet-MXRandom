UI::Font@ g_fontHeader;
UI::Font@ g_fontHeaderSub;

void RenderMenu()
{
    if(UI::BeginMenu(MX_COLOR_STR+Icons::Random+" \\$z"+SHORT_MX+" Randomizer" + (MX::APIDown ? " \\$f00"+Icons::Server : ""))){
        if (MX::APIDown && !IS_DEV_MODE) {
            if (!MX::APIRefreshing) {
                UI::Text("\\$fc0"+Icons::ExclamationTriangle+" \\$z"+MX_NAME + " is not responding. It might be down.");
                if (UI::Button("Retry")) {
                    startnew(MX::FetchMapTags);
                }
            } else {
                int HourGlassValue = Time::Stamp % 3;
                string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
                UI::TextDisabled(Hourglass + " Loading...");
            }
        } else {
            if (TM::CurrentTitlePack() == "") {
                UI::TextDisabled("You must select a title pack first.");
            } else {
#if TMNEXT
                if (Permissions::PlayLocalMap()) {
#endif
                    if (UI::MenuItem(Icons::Play + " Quick map")) {
                        startnew(MX::LoadRandomMap);
                    }
                    UI::SetPreviousTooltip("This will load and play instantly a random map from "+MX_NAME+".");

                    if(UI::MenuItem(MX_COLOR_STR+Icons::Random+" \\$zRandomizer Menu", "", window.isOpened)) {
                        window.isOpened = !window.isOpened;
                    }
                    UI::Separator();
                    if(UI::MenuItem(MX_COLOR_STR+Icons::ClockO+" \\$zRandom Map Challenge", "", window.isInRMCMode)) {
                        if (window.isInRMCMode) window.isInRMCMode = false;
                        else
                        {
                            if (!window.isOpened) window.isOpened = true;
                            window.isInRMCMode = true;
                        }
                    }
#if TMNEXT
                } else {
                    UI::Text(Icons::TimesCircle + " You have not the permissions to play local maps");
                }
#endif
            }
        }
        UI::EndMenu();
    }
}

void RenderInterface()
{
    if (!window.isInRMCMode) window.Render();
}

void Render()
{
    if (window.isInRMCMode) window.Render();
    Renderables::Render();
}

void Main()
{
#if TMNEXT
    if (!OpenplanetHasPaidPermissions()) {
        Log::Error("You need Club / Standard access to use this plugin!", true);
        return;
    }

    startnew(RMCLeaderAPI::Login);
#endif

    @g_fontHeader = UI::LoadFont("DroidSans-Bold.ttf", 22);
    @g_fontHeaderSub = UI::LoadFont("DroidSans.ttf", 20);

    DataManager::EnsureSaveFileFolderPresent();

    Meta::PluginCoroutine@ tagLoad = startnew(MX::FetchMapTags);
    await(tagLoad);

    if (DataJson.GetType() == Json::Type::Null) {
        if (DataJsonFromDataFolder.GetType() != Json::Type::Null) {
            DataManager::InitData(false);
            DataJson = DataJsonFromDataFolder;
            DataManager::SaveData();
            IO::Delete(DATA_JSON_LOCATION_DATADIR);
        } else if (DataJsonOldVersion.GetType() == Json::Type::Null) {
            DataManager::InitData();
            UI::ShowNotification("\\$afa" + Icons::InfoCircle + " Thanks for installing "+PLUGIN_NAME+"!","No data file was detected, that means it's your first install. Welcome!", 15000);
        } else {
            if (Versioning::IsVersion1(DataJsonOldVersion["version"])) {
                Log::Trace("Data JSON old version is "+Json::Write(DataJsonOldVersion["version"])+", showing migration wizard");
                Renderables::Add(DataMigrationWizardModalDialog());
            }
        }

        // Migration is not needed
        Migration::MigratedToMX2 = true;
    } else {
        DataManager::CheckData();

        if (!Migration::MigratedToMX2) {
            Migration::MigrateMX1Settings();
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
    RMC::FetchConfig();
    RMC::InitModes();
#if DEPENDENCY_NADEOSERVICES
    MXNadeoServicesGlobal::LoadNadeoLiveServices();
#endif
}
