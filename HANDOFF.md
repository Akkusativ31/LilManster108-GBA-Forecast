# Handoff (dev branch)

Notes for continuing work on the Plus patch in a new session. `main` is the
released state (v34). This `dev` branch adds unfinished work.

## Setup

1. Clone this repo, check out `dev`.
2. The user attaches a Lil' Manster 1.08 ROM (CRC32 2039D71B). Put it in
   `src_plus/` as `LM108.sfc`. Never commit it.
3. VoltEdge goes in the repo root (next to src_plus) as `VoltEdge/`, at commit 357ae87:
   `git clone https://github.com/ZaneAvernathy/VoltEdge && git -C VoltEdge checkout 357ae87`
4. Build (64tass from the package manager):
   ```
   cd src_plus
   64tass -f -o out.sfc ForecastInstaller.asm -Wno-portable
   python3 fix_checksum.py out.sfc
   python3 ../tools/make_ips.py LM108.sfc out.sfc LilManster108_GBAForecast_Plus.ips
   ```
5. Options texts are generated: `python3 tools/gen_options_text.py src_plus/OptionsText.inc`
   (uses tools/menutext.py + tools/codes108.json; fix the paths at the top of
   the script, they still point to /root/work).

Testing tool: `tools/emu.py` (headless libretro frontend, needs a snes9x
libretro core). Options must come before the script tokens. Tokens: `w<N>`,
buttons like `A`, `DOWN*2+14`, `hold:A`, `poke:ADDR=VAL` (hex), `shot:file.png`,
`watch:N:addr,...`, `ramlog:N:file`, `frames:N:STEP:file`.

## Status

Done and released (v34): GBA forecast port, Battle Forecast / Weapon
Triangle / Unit Level / Prep Use rows, Game Speed Normal / Fast / Faster,
prep item use with turn penalty, 16-row options menu (description box moved
into BG3 rows 0-3, see OptionsMenu.asm).

Open:

1. **Animations: Player** (`src_plus/EnemyPhaseAnims.asm`): done and tested
   on the first map. Fourth choice on the Animations row: map battles on
   non-player phases, except when a non-player combatant is a named
   character. Hooks at $98ED7B and $11D687. "Named" = portrait byte ($2F in
   the character table at $869A2D) below $91; $91 and up are shared generic
   faces (generics all have portraits, so the old >= $F9 check was wrong).
   Tested: menu row fits and saves 0-3; enemy phase vs generic = map battle;
   enemy phase vs named = animated; player phase = animated; On/Off unchanged.
   `$00D7 = $DC33` while an animated battle runs (handy for checks).
Fixed (dev): **Prep Use penalty on staff/magic users who used nothing.**
   The "used items" count lives in bits 0-1 of $3D, but the enemy AI fills
   bits 0-4 with item flags every enemy phase ($8DB548: bit 1 = has a staff,
   bit 0 = item trait $08, bits 2-4 = certain staves). Flags left from the
   last enemy phase of a chapter were read as prep items on the next
   turn 1 (and locked those units in Deploy). Now bits 0-1 are cleared in
   the next-chapter routine ($83FB23 hook). Saves made at a chapter start
   with an older build still carry the stale flags (use Prep Use: No
   Penalty for that chapter).
   Debug tip: a snes9x libretro core built from source with a write
   watch in getset.h (S9xSetByte/S9xSetWord) found this quickly; the
   distro core (1.61) can't load current RetroArch states.

2. **Faster map battles** (animations off): not started. A normal map battle
   has long idle stretches with the battle box shown. The map battle proc is
   "OA" at $84B0B0 (proc code at $84B0D3, uses $159C as a step counter);
   the HP bar procs are at $84CFF8. Look for PROC_YIELD / sleep values in its
   proc code and shorten them.
3. **End-turn prompt** (optional, not started): ask "End turn?" when all
   player units have moved. The options menu is full (16 rows is the max).

Dropped: speeding up animated battles. Tried timers, extra object updates and
skipping waits; at best ~15-30% faster and occasional one-frame garbage
(CPU overrun when sound or graphics loading lines up). Not worth it.

## Working rules agreed with the user

- Keep token use low: build, small RAM checks, at most a single screenshot
  when something is visual. The user tests in-game and sends RetroArch
  savestates when something breaks (RZIP: zlib chunks wrapping a RASTATE
  file; the "MEM " chunk is the libretro state).
- No map spoilers. Simple, plain release texts.
- New features must not make the game easier or take away Thracia's feel.
- Releases: Claude can push to the repo but can't create GitHub releases;
  give the user the zip and the steps.
