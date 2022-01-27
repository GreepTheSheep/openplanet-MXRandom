namespace UI
{
    void SetPreviousTooltip(const string &in text)
    {
        if (UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::Text(text);
            UI::EndTooltip();
        }
    }
}