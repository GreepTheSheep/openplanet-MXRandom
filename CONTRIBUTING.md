# Contributing guide for ManiaExchange Random Map Picker

## How to contribute to the project?

If you're looking to contribute to the plugin, you will have to [fork the repository](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo) to make the changes you want to push to the project. Once you have the needed changes, you can commit them to your fork, then [open a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) to get it reviewed and approved.

Pull requests that use any sort of generative AI will be rejected.

## Requirements

* [Openplanet](https://openplanet.dev/)
* Club access (TM2020 only)

As always, it's also **highly** recommended to read the [Openplanet documentation](https://openplanet.dev/docs/api), as well as its [tutorial / guide](https://openplanet.dev/docs/getting-started).

Lastly, for changes that require using methods / properties from the ManiaPlanet engine, it's recommended to read the respective game's API documentation:

* [Trackmania Next / TM2020](https://next.openplanet.dev/)
* [ManiaPlanet / TM²](https://mp4.openplanet.dev/)

## Running your own version on Openplanet

To test your changes locally, you will have to move the changed files to the Plugins folder in Openplanet. This is usually located at:

- `C:\Users\%username%\OpenplanetNext\Plugins\` for Trackmania Next / 2020
- `C:\Users\%username%\Openplanet4\Plugins\` for ManiaPlanet / TM²

There, you can create a `MXRandom` folder with your files. Make sure `info.toml` is in the root folder (`MXRandom\info.toml`)!

Once you have done that, you will have to run the game in Developer mode. To do this, press F3 to bring up the Openplanet overlay, click Openplanet on the top left, Signature mode, Developer.

## Testing changes to Random Map Together

If you want to contribute to the Random Map Together mode in TM2020, you won't be able to test the changes like in the solo game modes. In Developer mode, you can't play most maps available on TMX in a room (unless you are a trusted developer). Nonetheless, maps created for the [Openplanet School Campaign](https://trackmania.io/#/campaigns/9/35357) are whitelisted and can be played as normal in rooms.

To test your changes, use [this mappack](https://trackmania.exchange/mappackshow/4685) containing some of the whitelisted maps. To do so, enable Custom TMX filters in the run settings, then set `4685` as the Mappack ID in the Filters settings. It is also recommended to disable `Skip duplicated maps`, since the mappack only contains 11 maps.

Make sure the room you have created in your club uses one of the Openplanet School Campaign maps before trying to join it!

You can read more about School mode and whitelisted maps [here](https://openplanet.dev/user/trusted).

## Debugging

To debug issues with the current code or your changes, you can change the logging level in the settings (Settings -> Advanced -> Log Level). Logging messages can be found in the Openplanet log (F3 -> Openplanet -> Log).

You can use the RMC Debug window to see the status of the current run, as well as its properties, played maps, etc. To open it, click "Debug Window" in the Advanced tab in the plugin settings.
