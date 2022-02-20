class RMS : RMC
{
    int Skips = 0;
    Resources::Texture@ SkipTex = Resources::GetTexture("src/Assets/Images/YEPSkip.png");

    int TimeLimit() override { return PluginSettings::RMC_SurvivalMaxTime * 60 * 1000; }

    void RenderBelowGoalMedal() override
    {
        UI::Image(SkipTex, vec2(50,50));
        UI::SameLine();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(TimerFont);
        UI::Text(tostring(Skips));
        UI::PopFont();
        UI::SetCursorPos(pos_orig);
    }
}