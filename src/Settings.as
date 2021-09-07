enum MapLength
{
    Anything = -1,
    _15seconds = 0,
    _30seconds = 1,
    _45seconds = 2,
    _1minutes = 3,
    _1minutes_15seconds = 4,
    _1minutes_30seconds = 5,
    _1minutes_45seconds = 6,
    _2minutes = 7,
    _2minutes_30seconds = 8,
    _3minutes = 9,
    _3minutes_30seconds = 10,
    _4minutes = 11,
    _4minutes_30seconds = 12,
    _5minutes = 13,
    Long = 14,
}

[Setting name="Map length" category="Searching"]
MapLength Setting_MapLength = MapLength::Anything;

enum MapType
{
    Anything = 0,
    Race = 1,
	Fullspeed = 2,
	Tech = 3,
	RPG = 4,
	LOL = 5,
	Press_Forward = 6,
	Speedtech = 7,
	Multilap = 8,
	Offroad = 9,
	Trial = 10
}

[Setting name="Map type" category="Searching"]
MapType Setting_MapType = MapType::Anything;

[Setting name="Minimal mode" category="Menu" description="In minimal mode, the window only shows a 'Start searching' button and nothing else. It also always shows even if the Openplanet overlay is closed"]
bool Setting_Window_Minimal = false;

[Setting name="Window default height" category="Menu" description="The default height of the window (does not affect in minimal mode)"]
int Setting_WindowSize_h = 450;