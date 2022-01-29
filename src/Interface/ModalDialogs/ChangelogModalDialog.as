class ChangelogModalDialog : ModalDialog
{
    Net::HttpRequest@ m_request;
    string m_changelogBody;
    bool m_requestError = false;

    ChangelogModalDialog()
    {
        super(MX_COLOR_STR + Icons::Random + " "+PLUGIN_NAME+" \\$zwas updated to version "+MX_COLOR_STR+ PLUGIN_VERSION + "\\$z!");
        StartChangelogRequest();
        m_size = vec2(Draw::GetWidth()/2, Draw::GetHeight()/2);
    }

    void RenderChangelogContent()
    {
        if (m_request !is null) {
            int HourGlassValue = Time::Stamp % 3;
            string Hourglass = (HourGlassValue == 0 ? Icons::HourglassStart : (HourGlassValue == 1 ? Icons::HourglassHalf : Icons::HourglassEnd));
            UI::Text(Hourglass + " Loading...");
        } else {
            if (m_requestError) {
                UI::Text("Error loading changelog!");
                if (UI::Button("Retry")) {
                    StartChangelogRequest();
                }
            } else {
                UI::Markdown(Render::FormatChangelogBody(m_changelogBody));
            }
        }
    }

    void StartChangelogRequest()
    {
        string url = "https://api.github.com/repos/"+GITHUB_REPO_FULLNAME+"/releases/latest";

        Log::Trace("Changelog::SendRequest : " + url);
        @m_request = API::Get(url);
    }

    void CheckChangelogRequest()
    {
        // If there's a request, check if it has finished
        if (m_request !is null && m_request.Finished()) {
            // Parse the response
            string res = m_request.String();
            Log::Trace("Changelog::CheckRequest : " + res);
            auto json = Json::Parse(res);
            @m_request = null;

            if (json.GetType() != Json::Type::Object) {
                print("Changelog::CheckRequest : Error parsing response");
                m_requestError = true;
                return;
            }

            // Handle the response
            m_changelogBody = json["body"];
        }
    }

    void RenderDialog() override
    {
        CheckChangelogRequest();
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

        RenderChangelogContent();
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