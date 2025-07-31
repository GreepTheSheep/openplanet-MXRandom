class RMSTHelpModalDialog : ModalDialog
{
    UI::Texture@ clubIdTex;
    UI::Texture@ roomIdTex;

    RMSTHelpModalDialog()
    {
        super(Icons::InfoCircle + " \\$zRandom Map Survival Together###RMSTHelp");
        m_size = vec2(Draw::GetWidth(), Draw::GetHeight()) * 0.6f;
        @clubIdTex = UI::LoadTexture("src/Assets/Images/help_clubId.jpg");
        @roomIdTex = UI::LoadTexture("src/Assets/Images/help_roomId.jpg");
    }

    void RenderDialog() override
    {
        float scale = UI::GetScale();
        UI::BeginChild("Content", vec2(0, -32) * scale);
        UI::PushFont(Fonts::Header);
        UI::Text("Random Map Survival Together");
        UI::PopFont();
        UI::Markdown(
            "Random Map Survival Together is a multiplayer survival mode where players work together to survive as long as possible.\n\n" +
            "The game mode requires all players to join the server you have set up. Players have no plugins to install and is compatible with console players.\n\n"
        );
        UI::NewLine();
        UI::Separator();
        UI::PushFont(Fonts::Header);
        UI::Text("Prerequisites for a good functioning of the RMST mode");
        UI::PopFont();
        UI::Markdown(
            "- You need to have a **Club** with at least **Admin** permissions\n" +
            "- You need to have a **Room** in this club\n" +
            "- You need to **join the room** before starting the mode\n" +
            "- All players must **join the same room**\n\n"
        );
        UI::Separator();
        UI::PushFont(Fonts::Header);
        UI::Text("How RMST works");
        UI::PopFont();
        UI::Markdown(
            "**Collaborative Survival:**\n" +
            "- All players share the same timer and work as a team\n" +
            "- When **any player** gets a goal medal, the **entire team** gets +3 minutes\n" +
            "- When **any player** skips a map, the **entire team** loses -1 minute\n" +
            "- The session ends when the shared timer reaches 0\n\n" +
            "**Team Progress Tracking:**\n" +
            "- Team achievements (total medals and skips) are shared\n" +
            "- Individual contributions are tracked for recognition\n" +
            "- MVP is determined by individual goals vs skips ratio\n" +
            "- Real-time team progress updates\n\n"
        );
        UI::Separator();
        UI::PushFont(Fonts::Header);
        UI::Text("How to get Club ID and Room ID");
        UI::PopFont();
        UI::Markdown(
            "**Club ID:**\n" +
            "Go to your club page on the Trackmania website and look at the URL. The Club ID is the number at the end.\n\n"
        );
        if (clubIdTex !is null) {
            UI::Image(clubIdTex, vec2(clubIdTex.GetSize().x, clubIdTex.GetSize().y) * 0.5f * scale);
        }
        UI::NewLine();
        UI::Markdown(
            "**Room ID:**\n" +
            "Go to your room page in the club and look at the URL. The Room ID is the number at the end.\n\n"
        );
        if (roomIdTex !is null) {
            UI::Image(roomIdTex, vec2(roomIdTex.GetSize().x, roomIdTex.GetSize().y) * 0.5f * scale);
        }
        UI::NewLine();
        UI::Separator();
        UI::PushFont(Fonts::Header);
        UI::Text("Tips for a successful RMST session");
        UI::PopFont();
        UI::Markdown(
            "- **True teamwork:** Any team member getting a goal medal helps everyone!\n" +
            "- **Coordinate skips:** Discuss as a team before anyone skips a difficult map\n" +
            "- **Divide and conquer:** Players can focus on different types of maps they're good at\n" +
            "- **Watch the shared timer:** Keep track of team time and plan accordingly\n" +
            "- **Use voice chat:** Communication is crucial for team coordination\n" +
            "- **Celebrate together:** Every goal medal is a team achievement!\n" +
            "- **Support each other:** Help teammates learn difficult sections\n\n"
        );
        UI::EndChild();
        
        if (UI::Button("Close")) {
            m_visible = false;
        }
    }
} 