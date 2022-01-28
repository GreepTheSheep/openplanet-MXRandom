class ChangelogModalDialog : ModalDialog
{
    ChangelogModalDialog()
    {
        super(MX_COLOR_STR + Icons::Random + " "+PLUGIN_NAME+" \\$zwas updated to version "+MX_COLOR_STR+ PLUGIN_VERSION + "\\$z!");
        m_size = vec2(Draw::GetWidth()/2, Draw::GetHeight()/2);
    }

    void RenderContent()
    {
        UI::Text("Changelog not available yet.");
    }

    void RenderDialog() override
    {
        UI::BeginChild("Content", vec2(0, -32));

        UI::Text(MX_COLOR_STR + Icons::Random);
        UI::SameLine();
        UI::PushFont(g_fontHeader);
        UI::Text(PLUGIN_NAME+" \\$zwas updated to version "+MX_COLOR_STR+ PLUGIN_VERSION + "\\$z!");
        UI::PopFont();
        UI::Separator();
        UI::PushFont(g_fontHeaderSub);
        UI::Text("What's new in this version:");
        UI::PopFont();
        UI::NewLine();

        RenderContent();
		UI::EndChild();
        PluginSettings::dontShowChangeLog = UI::Checkbox("Don't show again", PluginSettings::dontShowChangeLog);
        UI::SameLine();
        vec2 currentPos = UI::GetCursorPos();
        UI::SetCursorPos(vec2(UI::GetWindowSize().x - 77, currentPos.y));
        if (UI::GreenButton("Close " + Icons::Times)) {
            Close();
        }
    }
}