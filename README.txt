GBA-Style Battle Forecast for Lil' Manster 1.08

Two patches, pick one. Both go on a Lil' Manster 1.08 ROM,
NOT on the original Japanese game.

  Lil' Manster 1.08 ROM: CRC32 2039D71B

LilManster108_GBAForecast.ips
  Zane Avernathy's GBA forecast ported to Lil' Manster.
  Nothing else changed.
  Patched ROM: CRC32 A7E3EF44

LilManster108_GBAForecast_Plus.ips
  The same forecast with extras, all switchable in the
  Configuration menu (new rows after "Window Pattern"):
    Battle Forecast: GBA / Still / Classic
    Weapon Triangle: GBA / Thracia / Off
    Unit Level:      On / Off
  Extras: floating x2/x4, weapon triangle arrows,
  effective weapon flash, level in the units window.
  Also: rings and skill manuals can be used in the
  preparations Items menu by deployed units ("Discard" is
  renamed "Use": pick the item > Use; discarding works as
  before). Same rules, results and sounds as on the map,
  with a short message ("Strength +3", "Vantage learned").
  The Master Seal works too: pick Use, and when you leave
  the Items screen the normal promotion scene plays on the
  preparations map, once. The unit is promoted right then,
  so saving in the preparations keeps it. Picking the seal
  again before you leave lets you cancel it.
  A unit that used something stays deployed for that chapter.
  Patched ROM: CRC32 AAF337D7

Existing saves work with both.

Source code is in src_port and src_plus.

Credits
  Zane Avernathy - GBA-styled FE5 forecast, VoltEdge, FE5 disassembly
  Miacis, Ultimage, the Lil' Manster and Project Exile teams - Lil' Manster
  Optiroc - SuperFamiconv
  64tass

The code for the port and the extras was written with an AI
(Claude) and tested in an emulator and by playing.
