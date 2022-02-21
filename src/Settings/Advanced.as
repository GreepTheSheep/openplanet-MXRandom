namespace PluginSettings
{
    [SettingsTab name="Advanced"]
    void RenderAdvancedSettings()
    {
        if (UI::Button("Show v2 Migration Wizard"))
        {
            Renderables::Add(DataMigrationWizardModalDialog());
        }
    }
}