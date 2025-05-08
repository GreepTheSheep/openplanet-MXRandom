namespace Fonts {
    UI::Font@ Header;
    UI::Font@ HeaderSub;
    UI::Font@ TimerFont;
    UI::Font@ MidBold;

    void Load() {
        @Header = UI::LoadFont("DroidSans-Bold.ttf", 22, -1, -1, true, true, true);
        @HeaderSub = UI::LoadFont("DroidSans.ttf", 20, -1, -1, true, true, true);
        @TimerFont = UI::LoadFont("src/Assets/Fonts/digital-7.mono.ttf", 20);
        @MidBold = UI::LoadFont("DroidSans-Bold.ttf", 18);
    }
}
