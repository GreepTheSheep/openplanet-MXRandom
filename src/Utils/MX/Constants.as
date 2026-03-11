namespace MX {
    enum Difficulties {
        Beginner,
        Intermediate,
        Advanced,
        Expert,
        Lunatic,
        Impossible
    };

    enum Environments {
#if TMNEXT
        Stadium = 1,
        Red_Island,
        Green_Coast,
        Blue_Bay,
        White_Shore,
#else
        Canyon = 1,
        Stadium,
        Valley,
        Lagoon,
        Desert,
        Snow,
        Rally,
        Coast,
        Bay,
        Island,
#endif
        Last
    };
}
