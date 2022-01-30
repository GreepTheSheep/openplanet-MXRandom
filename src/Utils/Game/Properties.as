namespace TM
{
    enum GameEditions
    {
        NEXT,
        MP4
    }

#if TMNEXT
    GameEditions GameEdition = GameEditions::NEXT;
    string CurrentTitlePack = cast<CGameManiaPlanet>(GetApp()).LoadedManiaTitle.TitleId;
#elif MP4
    GameEditions GameEdition = GameEditions::MP4;
    string CurrentTitlePack = cast<CGameManiaPlanet>(GetApp()).LoadedManiaTitle.TitleId.SubStr(0, cast<CGameManiaPlanet>(GetApp()).LoadedManiaTitle.TitleId.IndexOf("@"));
#endif

    string loadMapURL;
}