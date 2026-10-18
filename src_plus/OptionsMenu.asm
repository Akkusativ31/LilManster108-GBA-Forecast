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

  LMOptionRows          = 16
  LMOldOptionPointers   = [$CEEC, $CF08, $CF24, $CF40, $CF58, <>aLMOptionGameSpeed, $CF8C, $CFAC, $CFC8, $CFE0, $CFF8, $D018]

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
      .word <>aLMOptionPrep
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
    ; Lil' Manster's Game Speed row with three choices:
    ; Normal, Fast (fast walking) and Faster (fast walking and
    ; no phase banner, Lil' Manster's old Fast).
    ; Same name, getter, saver and icon as Lil' Manster's entry.

    aLMOptionGameSpeed
      .word $0000
      .word $D1A0
      .word <>aLMOptionChoicesSpeed
      .word <>aLMOptionSubSpeed
      .word $D381
      .word $D3B0
      .word $38AA
      .word len(aLMOptionChoicesSpeedPositions)
      .for _Position, _Width in aLMOptionChoicesSpeedPositions
        .word _Position, _Width
      .endfor

    aLMOptionPrep     .LMOptionEntry aLMOptionNamePrep, aLMOptionChoicesPrep, aLMOptionSubPrep, $38A0, aLMOptionChoicesPrepPositions

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

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_PREP
      cmp #3 << 12
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

    ; With 16 rows the window color settings reach the BG3 tilemap
    ; rows the subtitle window used (60-63). The subtitle moves into
    ; the top window's rows 1-2 instead: BG3 gets its own scroll HDMA
    ; table that shows rows 0, 4, 4, 3 for the top window (an empty
    ; frame) and rows 0-3 for the bottom one. BG2 keeps the old one.

    LMOptionsBG3HDMA = $7EFFE4

    aLMOptionsBG3HDMATemplate
      .byte 8
      .word 0
      .byte 8
      .word 24
      .byte 8
      .word 16
      .byte 8
      .word 0
      .byte 80
      .word 0
      .byte 80
      .word 0
      .byte 32
      .word 320
      .byte 0
    LMOptionsBG3HDMASize = * - aLMOptionsBG3HDMATemplate

    rlLMOptionsHDMAInit

      .al
      .xl
      .autsiz
      .databank ?

      jsl $80B340 ; copy the shared table (replaced call)

      php
      rep #$30
      phx
      ldx #LMOptionsBG3HDMASize - 2
      -
        lda @l aLMOptionsBG3HDMATemplate,x
        sta @l LMOptionsBG3HDMA,x
        dex
        dex
        bpl -
      plx
      plp
      rtl

    rlLMOptionsScrollUpdate

      .al
      .xl
      .autsiz
      .databank $7E

      lda @l $7EA9C8
      sta @l $7EA9BF
      sta @l $7EA9C2
      sta @l LMOptionsBG3HDMA + 13
      sta @l LMOptionsBG3HDMA + 16
      rtl

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

  ; Phase banner: Lil' Manster skips it when the speed nybble
  ; is non-zero; skip it only for Faster (2), Fast (1) keeps it.

  * := $48DF5E
  .word $0020

  * := $02E2D8
  .word $0840 + (4 * $C0)

  ; Subtitle window moved to BG3 rows 0-3 (see rlLMOptionsHDMAInit).

  * := $02D9EB
  .long LMOptionsBG3HDMA      ; BG3VOFS HDMA table
  * := $02D97E
  jsl rlLMOptionsHDMAInit
  * := $02CE9A
  jsl rlLMOptionsScrollUpdate
  nop
  nop
  nop
  nop
  nop
  * := $02D850
  .long $7EE77C               ; bottom window tilemap info: row 0
  * := $02DC6C
  .word $E77C + ((32 + 1) * 2) ; subtitle clear: row 1
  * := $02DCB8
  .long $7EE77C + (32 * 2)    ; subtitle DMA source: row 1
  * := $02DCBE
  .word $5000 + 32            ; subtitle DMA destination: row 1

  ; The row pointer list ($7EA95F, 16 words) needs 17 words for 16
  ; rows and its 0 end marker, but the row selections follow right
  ; after it: move the list to $7EFFBA (free while the menu is up).

  LMOptionPointersRAM = $FFBA

  .for _Offset in [$02D518, $02D530, $02D638, $02DA25, $02DC63, $02E2C8, $48CE21, $48D445, $48D483]
    * := _Offset + 1
    .word LMOptionPointersRAM
  .endfor

  ; "Restore" reloads the working copies from the save file.
  ; Vanilla put the (unused) autocursor word where rows 12-15
  ; live now and the text speed word one word later; swap them.

  * := $02E28F
  .word <>LM_OPTIONS_TEMP
  * := $02E2AB
  .word <>LM_OPTIONS_TEMP + 2

.endif ; GUARD_LM_OPTIONS_MENU
