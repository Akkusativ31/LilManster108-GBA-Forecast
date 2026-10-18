# Fire Emblem: Thracia 776 (FE5) - GBA Battle Forecast for Lil' Manster 1.08
This is Zane Avernathy's GBA-style Fire Emblem Thracia 776 battle forecast, ported to Lil' Manster 1.08, with optional QoL Features.
<img width="1881" height="1440" alt="image" src="https://github.com/user-attachments/assets/a0f97e86-f715-4f16-97d9-3bcfeaa4262a" />



DISCLAIMER: At first I only made this for personal use, I found Zane's forecast and was bummed nobody ported it to Lil Manster. I made this with the help of an AI (Claude). It wrote the code based on Zane's forecast, and I tested it by playing and in an emulator. The graphics are Thracia's own, plus small arrow sprites. No AI image tools were used. 

I know AI is a hot and controversial topic in the Rom Hacking scene. I only released this because I thought someone else could have wanted something similiar. I understand if you disregard this project because of its use of AI.

I tested for glitches and crashes, played one whole chapter and tested tons of scenarios and I found zero crashes or visual glitches.

All the credit should go to ZaneAvernathy and Miacidae. If Zane or Miacidae does not like that their code is being used in an AI project, I would take it down on their request.

## Versions

- **GBA Forecast**: just the forecast, ported over. Nothing else is changed.
- **GBA Forecast Plus**: the same forecast with some extras. You can turn each one on or off in the Configuration menu (after "Window Pattern").

<img width="1881" height="1440" alt="image" src="https://github.com/user-attachments/assets/98e88906-2d0f-4881-857d-1b6e64562d9b" />

## Plus options

- **Battle Forecast**: GBA / Still / Classic
  - GBA has the floating x2/x4 like FE8, and the weapon icon flashes when it's effective
  - Still is the same without the animations
  - Classic is the normal Lil' Manster forecast
- **Weapon Triangle**: GBA arrows / Thracia arrows / Off
- **Unit Level**: shows the level in the units window (On / Off)
- **Game Speed** (Lil' Manster's own option) gets a third choice: Normal / Fast / Walk
  - Fast: units walk fast and the "Player Phase" / "Enemy Phase" banner is skipped
  - Walk: units walk fast but the banner still shows

<img width="1881" height="1440" alt="image" src="https://github.com/user-attachments/assets/3dd35d05-07db-4ef4-91bd-dd51def38b7e" />

None of these options change gameplay. Old saves work.

## Items in the preparations (Plus)

Plus also lets you use some items in the preparations Items menu, because it always bugged me that you can't. "Discard" is now called "Use".

- Rings and skill manuals work the same as on the map, with the same sound and a short message ("Strength +3", "Vantage learned")
- The Master Seal plays the normal promotion scene once when you leave the Items screen, so if you save in the preparations you don't have to watch it again when you retry
- Only deployed units can use items, and a unit that used one stays deployed for that chapter
- For one turn per item used (up to 3) that unit can move, trade and wait but not attack, rescue, talk or visit, like it used the item on the map
- Everything else (keys, vulneraries, scrolls...) can't be used there, you can still discard it like before
- **Prep Use** (Configuration menu): On / Off / No Penalty
  - On: the rules above
  - Off: no item use in the preparations (the button still says "Use" but it only discards)
  - No Penalty: use items without the turn penalty, and you can take the unit out again

## How to use

- Apply the patch to a Lil' Manster 1.08 ROM (CRC32 2039D71B), not the original Japanese ROM
- Download: https://github.com/Akkusativ31/LilManster108-GBA-Forecast/releases/latest

## Credits

- Zane Avernathy: GBA forecast, VoltEdge, FE5 disassembly
- Miacis, Ultimage and the Lil' Manster / Project Exile teams: Lil' Manster
- Optiroc: SuperFamiconv
- 64tass
- https://github.com/Miacidae/Lil-Manster-Public
- https://github.com/ZaneAvernathy/FE5-GBABattleForecast

If you find bugs, let me know!
