; Lil' Manster: three new rows in the Configuration menu for the
; GBA forecast features, right after "Window Pattern":
;
;   Battle Forecast   GBA / Still / Classic
;   Weapon Triangle   GBA / Thracia / Off
;   Unit Level        On / Off
;
; The settings are packed as nybbles into aOptions.wTextSpeed,
; a saved option word Lil' Manster no longer uses (its message
; speed lives in wTerrainWindow). New saves start it at 0, so
; 0 is the default for every setting:
;
;   bits 0-3   forecast: 0 = GBA, 1 = GBA without animation, 2 = classic
;   bits 4-7   arrows:   0 = GBA sprites, 1 = Thracia's arrows, 2 = off
;   bits 8-11  level:    0 = shown in the units window, 1 = hidden
;
; The menu code is data driven by Lil' Manster's options table, so
; this only repoints the tables that have one entry per row (the
; row list itself, the name/choice/icon positions and the highlight
; coordinates) to longer copies, and lets the "restore" (Y) button
; restore the new word. All addresses are Lil' Manster 1.08's.

GUARD_LM_OPTIONS_MENU :?= false
.if (!GUARD_LM_OPTIONS_MENU)
  GUARD_LM_OPTIONS_MENU := true

  LMOptionRows          = 15
  LMOldOptionPointers   = [$CEEC, $CF08, $CF24, $CF40, $CF58, $CF74, $CF8C, $CFAC, $CFC8, $CFE0, $CFF8, $D018]

  ; Getter/saver helpers and every pointer in an option entry are
  ; 16-bit pointers into bank $11, so all of this lives there, in
  ; the empty end of the bank.

  * := $48F000
  .logical $11F000

    aLMOptionsMenuPointers
      .word LMOldOptionPointers
      .word <>aLMOptionForecast
      .word <>aLMOptionArrows
      .word <>aLMOptionLevel
      .word 0

    LMOptionEntry .macro Name, Choices, Subtext, Icon, Positions
      .word $0000
      .word <>\Name
      .word <>\Choices
      .word <>\Subtext
      .word <>rsLMOptionGetter
      .word <>rsLMOptionSaver
      .word \Icon
      .word len(\Positions)
      .for _Position, _Width in \Positions
        .word _Position, _Width
      .endfor
    .endmacro

    .include "OptionsText.inc"

    aLMOptionForecast .LMOptionEntry aLMOptionNameForecast, aLMOptionChoicesForecast, aLMOptionSubForecast, $38A0, aLMOptionChoicesForecastPositions
    aLMOptionArrows   .LMOptionEntry aLMOptionNameArrows, aLMOptionChoicesArrows, aLMOptionSubArrows, $38A0, aLMOptionChoicesArrowsPositions
    aLMOptionLevel    .LMOptionEntry aLMOptionNameLevel, aLMOptionChoicesLevel, aLMOptionSubLevel, $38A4, aLMOptionChoicesLevelPositions

    ; Getter: the menu calls this once per row when it opens.
    ; Copies the word to the working copy, clearing any setting
    ; that's out of range (old saves from other versions).

    rsLMOptionGetter

      .al
      .xl
      .autsiz
      .databank ?

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_FORECAST
      cmp #3
      blt +
        lda #0
      +
      sta @l LM_OPTIONS_TEMP

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_ARROWS
      cmp #3 << 4
      blt +
        lda #0
      +
      ora @l LM_OPTIONS_TEMP
      sta @l LM_OPTIONS_TEMP

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_LEVEL
      cmp #2 << 8
      blt +
        lda #0
      +
      ora @l LM_OPTIONS_TEMP
      sta @l LM_OPTIONS_TEMP
      rts

    ; Saver: called once per row when the menu closes.

    rsLMOptionSaver

      .al
      .xl
      .autsiz
      .databank ?

      lda @l LM_OPTIONS_TEMP
      sta @l LM_OPTIONS_WORD
      rts

    ; Per-row tables, 15 entries instead of 12.
    ; Name and choice positions: column, row.

    aLMOptionNamePositions
      .for _Row in range(LMOptionRows)
        .byte 5, 5 + (_Row * 3)
      .endfor

    aLMOptionChoicePositions
      .for _Row in range(LMOptionRows)
        .byte 16, 5 + (_Row * 3)
      .endfor

    ; Icon tilemap offsets

    aLMOptionIconPositions
      .for _Row in range(LMOptionRows)
        .word $0146 + (_Row * $C0)
      .endfor

    ; Highlight coordinates (BG3 tilemap offsets of each row)

    aLMOptionHighlightCoordinates
      .for _Row in range(LMOptionRows)
        .word $0160 + (_Row * $C0)
      .endfor

    .cerror * > $120000, "Options data overflows bank $11"

  .endlogical

  ; Row list: lda #<>pointers / lda #(bank << 8 | >pointers)
  ; in the routine that copies it to RAM ($85D4EC).

  * := $02D4ED
  .word <>aLMOptionsMenuPointers
  * := $02D4F2
  .word ((`aLMOptionsMenuPointers) << 8) | >aLMOptionsMenuPointers

  ; lda $85D5C3,x (name positions)

  .for _Offset in [$02D672, $02E089, $48CE13, $48D60A, $48D637]
    * := _Offset
    .long aLMOptionNamePositions
  .endfor

  ; lda $85D5DB,x (choice positions)

  * := $02D68C
  .long aLMOptionChoicePositions

  ; lda $85D60B,x (icon positions)

  * := $02D698
  .long aLMOptionIconPositions

  ; lda/adc aHighAndUnHighlightTilesCoordTable,x

  .for _Offset in [$48D5BB, $48D5E0]
    * := _Offset
    .long aLMOptionHighlightCoordinates
  .endfor

  ; "Restore" (Y) redraws all rows from row 0 down: DMA three
  ; more rows' worth of tilemap ($0840 -> $0B40).

  * := $02E2D8
  .word $0840 + (3 * $C0)

  ; "Restore" reloads the working copies from the save file.
  ; Vanilla put the (unused) autocursor word where rows 12-15
  ; live now and the text speed word one word later; swap them.

  * := $02E28F
  .word <>LM_OPTIONS_TEMP
  * := $02E2AB
  .word <>LM_OPTIONS_TEMP + 2

.endif ; GUARD_LM_OPTIONS_MENU
