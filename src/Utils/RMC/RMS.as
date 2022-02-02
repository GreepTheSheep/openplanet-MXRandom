class RMS : RMC
{
    int Skips = 0;
    Resources::Texture@ SkipTex = Resources::GetTexture("src/Assets/Images/YEPSkip.png");

    void RenderBelowGoalMedal() override
    {
        UI::Image(SkipTex, vec2(50,50));
        UI::SameLine();
        vec2 pos_orig = UI::GetCursorPos();
        UI::SetCursorPos(vec2(pos_orig.x, pos_orig.y+8));
        UI::PushFont(timerFont);
        UI::Text(tostring(Skips));
        UI::PopFont();
        UI::SetCursorPos(pos_orig);
    }
}