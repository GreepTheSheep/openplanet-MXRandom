class RMC
{
    bool Running = false;
    bool IsPaused = false;
    int StartTime = -1;
    int EndTime = -1;
    int GoalMedalCount = 0;
    int BelowMedalCount = 0;

    Resources::Font@ timerFont = Resources::GetFont("src/Assets/Fonts/digital-7.mono.ttf", 20);
    Resources::Texture@ AuthorTex = Resources::GetTexture("src/Assets/Images/Author.png");
    Resources::Texture@ GoldTex = Resources::GetTexture("src/Assets/Images/Gold.png");
    Resources::Texture@ SilverTex = Resources::GetTexture("src/Assets/Images/Silver.png");
    Resources::Texture@ BronzeTex = Resources::GetTexture("src/Assets/Images/Bronze.png");

    void Render()
    {

    }

    void RenderGoalMedal()
    {
        if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[3]) UI::Image(AuthorTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[2]) UI::Image(GoldTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[1]) UI::Image(SilverTex, vec2(50,50));
        else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[0]) UI::Image(BronzeTex, vec2(50,50));
        else UI::Text(PluginSettings::RMC_GoalMedal);
        UI::SameLine();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(timerFont);
        UI::Text(tostring(GoalMedalCount));
        UI::PopFont();
        UI::SetCursorPos(pos_orig);
    }

    void RenderBelowGoalMedal()
    {
        if (PluginSettings::RMC_GoalMedal != PluginSettings::Medals[0])
        {
            if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[3]) UI::Image(GoldTex, vec2(50,50));
            else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[2]) UI::Image(SilverTex, vec2(50,50));
            else if (PluginSettings::RMC_GoalMedal == PluginSettings::Medals[1]) UI::Image(BronzeTex, vec2(50,50));
            else UI::Text(PluginSettings::RMC_GoalMedal);
            UI::SameLine();
            vec2 pos_orig = UI::GetCursorPos();
            UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
            UI::PushFont(timerFont);
            UI::Text(tostring(BelowMedalCount));
            UI::PopFont();
            UI::SetCursorPos(pos_orig);
        }
    }
}