All code for Catch a Brainrot, me and @bigrahim's open source roblox game!<br>
This code contains a bunch of helpful scripts for making roblox games in similar genres or even vastly different genres.<br>
While I cannot speak for bigrahim, I did not use any AI in the creation of this game.<br>
Here is a summary of semi-universal features:<br>
Pathfinding Algorithm<br>
Helpful leaderstats like cash and rebirth<br>
Weather cycling system<br>
Platform Money Collection<br>
Admin Menus<br>
Flying Scripts (only used for admins in our game)<br>
Automatic Gui organizer<br>
and...<br>
✨Full export script that reduces 2.7gb of .lua to a neatly formatted & indexed .txt file that takes up 712 kb, and 85 when g-zipped!✨<br>
note export only works on windows as it uses powershell.<br>
<br>
<br>
Wiki will be updated after the first few updates with info on how to implement every script here.
<br>
## Atmos by elttob weather integration
Use **Atmos** as your look-dev tool and this repo as runtime playback.

### Added runtime scripts
- `ReplicatedStorage/AtmosIntegration.lua`
- `StarterPlayerScripts/WeatherVisualClient.lua`

### Folder expected from Atmos authoring
Create `ReplicatedStorage/AtmosWeatherPresets` with one Folder per weather name:
- `Clear`, `Rain`, `Bloodstorm`, `Candyland`, `Volcanic`, `Galactic`, `YinYang`, `Radioactive`

Inside each weather folder, add optional children (Folder or Configuration) and set Attributes:
1. `Atmosphere`
   - `Density`, `Offset`, `Color`, `Decay`, `Glare`, `Haze`
   - Color attributes can be `Color3` or string: `"R,G,B"`.
2. `Lighting`
   - `Brightness`, `ClockTime`, `FogEnd`, `FogColor`, `Ambient`, `OutdoorAmbient`
3. `Sky`
   - `SkyboxBk`, `SkyboxDn`, `SkyboxFt`, `SkyboxLf`, `SkyboxRt`, `SkyboxUp`
   - Optional: `CelestialBodiesShown`, `StarCount`, `SunAngularSize`, `MoonAngularSize`

Optional on weather folder root:
- `transitionTime`

### Runtime priority
On weather change:
1. Uses `AtmosWeatherPresets/<WeatherName>` if it exists (Atmos-authored).
2. Falls back to `WeatherSystem.ATMOS_PRESETS`.
3. Falls back to `Clear` preset.
