namespace TM
{
    enum GameEditions
    {
        NEXT,
        MP4
    }

#if TMNEXT
    GameEditions GameEdition = GameEditions::NEXT;
#elif MP4
    GameEditions GameEdition = GameEditions::MP4;
#endif
}