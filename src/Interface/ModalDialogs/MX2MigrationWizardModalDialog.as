class MX2MigrationWizardModalDialog : ModalDialog
{
    int m_stage = 0;
    int m_migrationStep = 0;
    bool migrationCompleted = false;
    array<int> m_MXIds;
    array<MX::MapInfo@> m_MapsFetched;

    MX2MigrationWizardModalDialog()
    {
        super(MX_COLOR_STR + Icons::Random + " \\$zMX 2.0 Migration Wizard");
        m_size = vec2(Draw::GetWidth() / 3, Draw::GetHeight() / 3);
    }

    void RenderStep1()
    {
        UI::PushFont(g_fontHeader);
        UI::TextWrapped("Thanks for updating " + PLUGIN_NAME +"!");
        UI::PopFont();

        UI::TextWrapped("This wizard will help you migrate your data to ManiaExchange 2.0.");
        UI::NewLine();
        UI::TextWrapped(
            "The new version of the plugin adds support to the new ManiaExchange. "
            "This means that you will need to migrate your data and saves to support it."
        );
        UI::NewLine();

        UI::TextWrapped(
            "The migration process will take a few seconds depending on your recently played maps list and saved runs."
        );

        UI::NewLine();
        UI::Separator();
        UI::NewLine();
        UI::TextWrapped(
            "To start the migration, select the \"Migrate\" button below.\n\n"
            "If you want to skip this process instead, select the \"Skip\" button "
            "(but all your data will be deleted)."
        );
    }

    void RenderStep2()
    {
        int HourGlassValue = Time::Stamp % 3;
        string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));

        UI::PushFont(g_fontHeader);
        if (!migrationCompleted) UI::Text("Please wait...");
        else UI::Text("Data migration complete!");
        UI::PopFont();
        UI::NewLine();

        UI::Text((m_migrationStep > 0 ? "\\$090" + Icons::Check : "\\$f80" + Hourglass) + " \\$zGetting the list of recently played maps" + (m_MXIds.Length == 0 ? "..." : " - " + m_MXIds.Length + " maps found"));
        UI::Text((m_migrationStep > 1 ? "\\$090" + Icons::Check : "\\$f80" + Hourglass) + " \\$zGetting the missing data from the API" + (m_MapsFetched.Length == 0 ? "..." : " - " + m_MapsFetched.Length + "/"+m_MXIds.Length + " maps"));
        UI::Text(migrationCompleted ? "\\$090" + Icons::Check + " \\$zData migration completed!" : "\\$f80" + Hourglass  + " \\$zMigrating data...");

        switch (m_migrationStep) {
            case 0:
                m_MXIds = Migration::GetMX1MapsId();
                if (m_MXIds.Length == 0) m_migrationStep = 2;
                else m_migrationStep++;
                break;
            case 1:
                Migration::CheckMX2MigrationRequest();
                if (Migration::v2_request is null) {
                    if (Migration::v2_maps.Length == 0) {
                        Migration::StartMX2RequestMapsInfo(m_MXIds);
                    } else {
                        m_MapsFetched = Migration::v2_maps;
                        m_migrationStep++;
                    }
                }
                break;
            case 2:
                if (m_MapsFetched.Length > 0 && !migrationCompleted) {
                    Migration::UpdateData();
                }
                migrationCompleted = true;
                break;
        }

        if (migrationCompleted) {
            UI::NewLine();
            UI::Separator();
            UI::NewLine();
            UI::TextWrapped("\\$0f0" + Icons::Check + " \\$zYour data has been successfully migrated to ManiaExchange 2.0.");
        }
        UI::NewLine();
        if (m_MapsFetched.Length > 0 && UI::TreeNode("Saved maps")){
            for (uint i = 0; i < m_MapsFetched.Length; i++){
                UI::Text(m_MapsFetched[i].MapId + ": " + m_MapsFetched[i].Name + " - " + m_MapsFetched[i].Username);
                if (UI::IsItemClicked()) OpenBrowserURL("https://"+MX_URL+"/mapshow/"+m_MapsFetched[i].MapId);
            }
            UI::TreePop();
        }
    }

    bool CanClose() override
    {
        return migrationCompleted;
    }

    void RenderDialog() override
    {
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);
        switch (m_stage) {
            case 0: RenderStep1(); break;
            case 1: RenderStep2(); break;
        }
        UI::EndChild();

        if (m_stage == 0) {
            if (UI::RedButton(Icons::Times + " Skip")) {
                DataManager::InitData();
                Migration::RemoveMX1SaveFiles();
                Close();
            }
            UI::SameLine();
            vec2 currentPos = UI::GetCursorPos();
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - 90 * scale, currentPos.y));
            if (UI::GreenButton("Migrate " + Icons::ArrowRight)) {
                m_stage++;
            }
        }

        if (migrationCompleted && UI::GreenButton(Icons::Check + "Finish")) {
            Close();
        }
    }
}
