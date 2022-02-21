class RMCSettingsModalDialog : ModalDialog
{
    RMCSettingsModalDialog()
    {
        super(MX_COLOR_STR + Icons::Cog + " \\$zRMC Settings");
        m_size = vec2(Draw::GetWidth()/2, Draw::GetHeight()/2);
    }

    void RenderDialog() override
    {
        PluginSettings::RenderRMCSettingTab();
    }
}