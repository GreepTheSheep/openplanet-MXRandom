# ManiaExchange Randomizer
## Takes randomly a map from MX and plays it

[![Version](https://img.shields.io/badge/dynamic/json?color=pink&label=Version&query=version&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)](https://openplanet.dev/plugin/mxrandom)
[![Total Downloads](https://img.shields.io/badge/dynamic/json?color=green&label=Downloads&query=downloads&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)](https://openplanet.dev/plugin/mxrandom)
![Tags 1](https://img.shields.io/badge/dynamic/json?color=darkgreen&label=Game&query=games%5B0%5D&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)
![Tags 2](https://img.shields.io/badge/dynamic/json?color=blue&label=Game&query=games%5B1%5D&url=https%3A%2F%2Fopenplanet.dev%2Fapi%2Fplugin%2F124)
---
## Usage:

Select "MX Randomizer" on the "Plugins" pannel.

Select "Random Map Challenge" for the RMC timer.

## Exports

### RMC
- `MXRandom::IsRMCRunning()` - Returns true if RMC is running.
- `MXRandom::IsRMCPaused()` - Returns true if RMC is paused.
- `MXRandom::RMCDefinedGoalMedal()` - Returns the user-defined medal number setting for the RMC goal. (See "RMC Goal Medals" table below)
- `MXRandom::RMCDefinedGoalMedalName()` - Returns the user-defined medal name setting for the RMC goal. (See "RMC Goal Medals" table below)
- `MXRandom::RMCGotGoalMedalOnCurrentMap()` - Returns true if the current map has a goal medal.
- `MXRandom::RMCGotBelowMedalOnCurrentMap()` - Returns true if the current map has a medal below the user-defined goal medal.
- `MXRandom::RMCGoalMedalCount()` - Returns the number of goal medals on a current RMC run.
- `MXRandom::RMCActualGameMode()` - Returns the actual game mode of the current RMC run. (See "Game Modes" table below)
- `MXRandom::CustomParameters` - Returns true if the player is using custom searching parameters.

### Utils
- `MXRandom::LoadRandomMap()` - Loads a random map from (T)MX.
- `MXRandom::GetRandomMapUrlAsync()` [ASYNC] - Get a random map URL from (T)MX and retuns its download URL.


### RMC Goal Medals

| Identifier | Medal  |
|------------|--------|
| 0          | Bronze |
| 1          | Silver |
| 2          | Gold   |
| 3          | Author |

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
