# ManiaExchange Randomizer

## Takes randomly a map from MX and plays it

[![Version](https://img.shields.io/badge/dynamic/json?color=pink&label=Version&query=version&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)](https://openplanet.dev/plugin/mxrandom)
[![Total Downloads](https://img.shields.io/badge/dynamic/json?color=green&label=Downloads&query=downloads&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)](https://openplanet.dev/plugin/mxrandom)
![Tags 1](https://img.shields.io/badge/dynamic/json?color=darkgreen&label=Game&query=games%5B0%5D&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)
![Tags 2](https://img.shields.io/badge/dynamic/json?color=blue&label=Game&query=games%5B1%5D&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)

## Usage:

Select "MX Randomizer" in the "Plugins" tab of the Openplanet overlay.

Select "Random Map Challenge" to play one of the following game modes:
* Random Map Challenge (RMC)
* Random Map Survival (RMS)
* Random Map Objective (RMO)
* Random Map Together (RMT) (TM2020 only, requires [MLFeed](https://openplanet.dev/plugin/mlfeedracedata) and [MLHook](https://openplanet.dev/plugin/mlhook))
* Random Map Challenge Chaos (TM2020 only, requires [Chaos Mode](https://openplanet.dev/plugin/chaosmode))
* Random Map Survival Chaos (TM2020 only, requires [Chaos Mode](https://openplanet.dev/plugin/chaosmode))

## Exports

### RMC
- `bool MXRandom::IsRMCRunning()` - Returns true if RMC is running.
- `bool MXRandom::IsRMCPaused()` - Returns true if RMC is paused.
- `int MXRandom::RMCDefinedGoalMedal()` - Returns the user-defined medal number setting for the RMC goal. (See [Goal Medals table](#rmc-goal-medals))
- `string MXRandom::RMCDefinedGoalMedalName()` - Returns the user-defined medal name setting for the RMC goal. (See [Goal Medals table](#rmc-goal-medals))
- `bool MXRandom::RMCGotGoalMedalOnCurrentMap()` - Returns true if the current map has a goal medal.
- `bool MXRandom::RMCGotBelowMedalOnCurrentMap()` - Returns true if the current map has a medal below the user-defined goal medal.
- `int MXRandom::RMCGoalMedalCount()` - Returns the number of goal medals on a current RMC run.
- `int MXRandom::RMCActualGameMode()` - Returns the actual game mode of the current RMC run. (See [Game Modes table](#game-modes))

### Searching parameters
- `bool MXRandom::CustomParameters` - Returns true if the player is using custom searching parameters.

### Utilities
- `void MXRandom::LoadRandomMap(bool customParameters = false)` - Loads a random map from MX.
- `string MXRandom::GetRandomMapUrlAsync(bool customParameters = false)` [ASYNC] - Get a random map URL from MX and retuns its download URL.
- `Json::Value@ MXRandom::GetRandomMapInfoAsync(bool customParameters = false)` [ASYNC] - Get a random map URL from MX and retuns a JSON object with the fields listed in [MapInfo.as](.\src\Utils\MX\Entities\MapInfo.as).

The parameter `customParameters` decides if the plugin should use the custom searching parameters selected by the user when fetching a map from MX. Defaults to `false`.

### RMC Goal Medals

| Identifier | Medal  |
|------------|--------|
| 0          | Bronze |
| 1          | Silver |
| 2          | Gold   |
| 3          | Author |
| 4          | World Record (TM2020 only) |

### Game Modes

Game modes are in a enumurated list.

| Identifier | Mode             |
|------------|------------------|
| 0          | Challenge        |
| 1          | Survival         |
| 2          | ChallengeChaos   |
| 3          | SurvivalChaos    |
| 4          | Objective        |
| 5          | Together         |
