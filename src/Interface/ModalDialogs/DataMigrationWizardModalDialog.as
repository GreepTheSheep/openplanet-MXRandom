class DataMigrationWizardModalDialog : ModalDialog
{
    int m_stage = 0;
    int m_migrationStep = 0;
    bool migrationCompleted = false;
    array<int> m_MXIdsFromRecently;
    array<MX::MapInfo@> m_MapsFetched;

    DataMigrationWizardModalDialog()
    {
        super(MX_COLOR_STR + Icons::Random + " \\$zData Migration Wizard");
        m_size = vec2(Draw::GetWidth()/2, Draw::GetHeight()/2);
    }

    void RenderStep1()
    {
        UI::PushFont(g_fontHeader);
        UI::TextWrapped("Thanks for updating " + PLUGIN_NAME +"!");
        UI::PopFont();

        UI::TextWrapped("This wizard will help you migrate your data from the version 1 to the version 2 of the plugin.");
        UI::TextWrapped(
            "The new version of the plugin has a new data format. "
            "This means that you will need to migrate your data to the new format."
        );
        UI::NewLine();

        UI::TextWrapped(
            "The different data of this migration are essentially "
            "the list of maps that you have recently played "
            "(map name, map author, map style, awards)"
        );

        UI::TextWrapped(
            "The migration process will take a few seconds depending of your current recently played maps list."
        );

        UI::NewLine();
        UI::TextWrapped(
            "To start over, select the \"Migrate\" button below.\n"
            "If you want to skip this wizard, select the \"Skip\" button (but all your lastest data will be put aside and will be not used)."
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

        UI::Text((m_migrationStep > 0 ? "\\$090" + Icons::Check : "\\$f80" + Hourglass) + " \\$zGetting the list of recently played maps" + (m_MXIdsFromRecently.Length == 0 ? "..." : " - " + m_MXIdsFromRecently.Length + " maps found"));
        UI::Text((m_migrationStep > 1 ? "\\$090" + Icons::Check : "\\$f80" + Hourglass) + " \\$zGetting the missing data from the server" + (m_MapsFetched.Length == 0 ? "..." : " - " + m_MapsFetched.Length + "/"+m_MXIdsFromRecently.Length + " maps"));
        UI::Text(migrationCompleted ? "\\$090" + Icons::Check + " \\$zData saved to the file! \\$444" + DATA_JSON_LOCATION : "\\$f80" + Hourglass  + " \\$zSaving the data to the new file...");

        switch (m_migrationStep) {
            case 0:
                m_MXIdsFromRecently = Migration::GetLastestPlayedMapsMXId();
                if (m_MXIdsFromRecently.Length == 0) m_migrationStep = 2;
                else {
                    if (m_MXIdsFromRecently.Length > 50) m_MXIdsFromRecently.Resize(50);
                    m_migrationStep++;
                }
                break;
            case 1:
                Migration::CheckMXRequest();
                if (Migration::n_request is null && Migration::RecentlyPlayed.Length == 0)
                    Migration::StartRequestMapsInfo(m_MXIdsFromRecently);

                if (Migration::n_request is null && Migration::RecentlyPlayed.Length > 0) {
                    m_MapsFetched = Migration::RecentlyPlayed;
                    m_migrationStep++;
                }
                break;
            case 2:
                if (m_MapsFetched.Length > 0 && !migrationCompleted) {
                    Migration::SaveToDataFile();
                }
                migrationCompleted = true;
                break;
        }

        if (migrationCompleted)
        {
            UI::Separator();
            UI::NewLine();
            UI::TextWrapped("\\$0f0" + Icons::Check + " \\$zYour data has been successfully migrated to the new format.");
            UI::TextWrapped("Thanks for using " + PLUGIN_NAME + "!");
        }
        UI::NewLine();
        if (m_MapsFetched.Length > 0 && UI::TreeNode("Saved maps")){
            for (uint i = 0; i < m_MapsFetched.Length; i++){
                UI::Text(m_MapsFetched[i].TrackID + ": " + m_MapsFetched[i].Name + " - " + m_MapsFetched[i].Username);
                if (UI::IsItemClicked()) OpenBrowserURL("https://"+MX_URL+"/maps/"+m_MapsFetched[i].TrackID);
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
        UI::BeginChild("Content", vec2(0, -32));
		switch (m_stage) {
			case 0: RenderStep1(); break;
			case 1: RenderStep2(); break;
		}
		UI::EndChild();

        if (m_stage == 0) {
            if (UI::RedButton(Icons::Times + " Skip")) {
                Close();
            }
            UI::SameLine();
            vec2 currentPos = UI::GetCursorPos();
            UI::SetCursorPos(vec2(UI::GetWindowSize().x - 90, currentPos.y));
            if (UI::GreenButton("Migrate " + Icons::ArrowRight)) {
                m_stage++;
            }
        }
        if (migrationCompleted) {
            if (UI::GreenButton(Icons::Check + "Finish")) {
                Close();
            }
        }
    }
}