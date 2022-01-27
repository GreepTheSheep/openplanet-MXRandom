class DataMigrationWizardModalDialog : ModalDialog
{
    int m_stage = 0;

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
            "The migration process will take a few minutes depending of your current recently played maps list."
        );

        UI::NewLine();
        UI::TextWrapped(
            "To start over, select the \"Migrate\" button below.\n"
            "If you want to skip this wizard, select the \"Skip\" button (but all your lastest data will be put aside and will be not used)."
        );
    }

    void RenderStep2()
    {
        UI::Text("TODO HERE");

        m_stage++;
    }

    void RenderStep3()
    {
        UI::PushFont(g_fontHeader);
        UI::TextWrapped("Data migration complete!");
        UI::PopFont();

        UI::TextWrapped("Your data has been successfully migrated to the new format.");
        UI::TextWrapped("Thanks for using " + PLUGIN_NAME + "!");
    }

    bool CanClose() override
    {
        return false;
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -32));
		switch (m_stage) {
			case 0: RenderStep1(); break;
			case 1: RenderStep2(); break;
			case 2: RenderStep3(); break;
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
        if (m_stage == 2) {
            if (UI::GreenButton(Icons::Check + "Finish")) {
                Close();
            }
        }
    }
}