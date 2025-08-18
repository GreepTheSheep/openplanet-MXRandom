class SettingsModalDialog : ModalDialog {
    SettingsModalDialog() {
        super(MX_COLOR_STR + Icons::Cog + " \\$zSettings");
        m_size = vec2(Draw::GetWidth() / 2, 600);
    }

    void RenderDialog() override {
        PluginSettings::Render();
    }
}
