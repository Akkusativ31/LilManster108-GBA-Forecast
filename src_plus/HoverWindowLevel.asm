
; Lil' Manster: show the unit's level in the map hover window.

; The window grows from 11x5 to 11x6 tiles and gets an
; "LV 12" row under "HP 8/22", in the same italic label
; and digit tiles the HP row uses. Everything else (name,
; weapon icon, HP/status row) stays where it was.

; The addresses below are Lil' Manster 1.08's.

GUARD_LM_HOVER_LEVEL :?= false
.if (!GUARD_LM_HOVER_LEVEL)
  GUARD_LM_HOVER_LEVEL := true

  .weak
    rlLMDrawEquippedItemPreview :?= address($98F14C)
    aLMDigitPairs               :?= address($87E26B) ; per value: ones, tens
    aLMBurstWindowTilemapTable  :?= address($84A37E) ; 6 short pointers into bank $98
    aLMBurstWindowFrameBank     :?= $98
    aLMBurstWindowPositionTable :?= address($84A1F7) ; per style: x, y offsets
  .endweak

  LMHoverWindowSize = (11, 6)

  LMHoverTilemap .function Index
    _Column := (int(Index) % 2) * LMHoverWindowSize[0]
    _Row    := (int(Index) / 2) * LMHoverWindowSize[1]
  .endf ((_Row * 32) + _Column) * size(word)

  ; The level row is optional (Configuration > Unit Level), so
  ; each spot that depends on the window's height checks the
  ; option instead of being patched to a constant.

  ; rsGetBurstWindowStyle: a unit within this many pixels of
  ; the top of the screen gets the window below it. The
  ; taller window would otherwise reach screen row 3, where
  ; the top strip (terrain box area) draws its outline as a
  ; thick dark bar. 64 -> 80 keeps windows at row 5 or lower.
  ; Replaces lda $0D / cmp #$0040 / beq + / bcs $84A1B1.

  * := $02219F
  .logical mapped($02219F)
    jsl rlLMHoverWindowCheckTop
    bcs mapped($0221B1)
    nop
    nop
    nop
  .endlogical

  ; rsGetBurstWindowPosition: Y offset from aBurstWindowPositionTable.
  ; Windows above the unit start one row higher with the
  ; level row so they still end in the same place.

  * := $0221EB
  .logical mapped($0221EB)
    jsl rlLMHoverWindowGetY
    rts
    .fill mapped($0221F7) - *, $EA
  .endlogical

  ; rsDrawBurstWindowTilemap: pick the 11x5 or 11x6 frames.

  * := $022346
  .logical mapped($022346)
    jsl rlLMHoverWindowDrawFrame
    rts
  .endlogical

  ; rlUpdateBurstWindow: the call to rlDrawEquippedItemPreview
  ; after the window is drawn. Draw the level first.

  * := $022168
  .logical mapped($022168)
    jsl rlLMBurstWindowDrawLevel
  .endlogical

  .section GBABattleForecastWindowSection

    rlLMHoverWindowCheckTop

      .al
      .autsiz
      .databank ?

      ; Carry set if the unit (pixel row in $0D) is far
      ; enough down for the window to go above it.

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_LEVEL
      bne +

        lda $0D
        cmp #(5 * 16) + 1
        rtl

      +
      lda $0D
      cmp #(4 * 16) + 1
      rtl

      .databank 0

    rlLMHoverWindowGetY

      .al
      .autsiz
      .databank `wBurstWindowPositionYTile

      ; X: style * 4. Same as vanilla, minus one row for
      ; the three styles above the unit when showing the level.

      lda @l wBurstWindowOriginYTile
      clc
      adc @l aLMBurstWindowPositionTable+2,x
      pha

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_LEVEL
      bne +

        cpx #3 * 4
        bcs +

          pla
          dec a
          pha

      +
      pla
      sta @l wBurstWindowPositionYTile
      rtl

      .databank 0

    rlLMHoverWindowDrawFrame

      .al
      .xl
      .autsiz
      .databank ?

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_LEVEL
      bne _Short

        lda #(`aLMHoverWindowTilemaps) << 8
        sta lR18+size(byte)
        lda @l wBurstWindowStyle
        asl a
        tax
        lda @l _TallFrames,x
        sta lR18
        lda #LMHoverWindowSize[1]
        bra _Draw

      _Short

        lda #aLMBurstWindowFrameBank << 8
        sta lR18+size(byte)
        lda @l wBurstWindowStyle
        asl a
        tax
        lda @l aLMBurstWindowTilemapTable,x
        sta lR18
        lda #LMHoverWindowSize[1] - 1

      _Draw

      sta wR1

      ; Same as vanilla: BG1 tilemap buffer at $7EC77C

      lda @l wBurstWindowPositionYTile
      asl a
      asl a
      asl a
      asl a
      asl a
      clc
      adc @l wBurstWindowPositionXTile
      asl a
      clc
      adc #$C77C
      sta lR19

      lda #LMHoverWindowSize[0]
      sta wR0

      lda #$2400
      sta @l $7E0DE7 ; base tile/palette for the frame

      jsl rlDrawTilemapPackedRect
      rtl

      _TallFrames
        .for _Style in range(6)
          .word <>aLMHoverWindowTilemaps + LMHoverTilemap(_Style)
        .endfor

      .databank 0

    rlLMBurstWindowDrawLevel

      .autsiz
      .databank ?

      lda @l LM_OPTIONS_WORD
      and #LM_OPTION_LEVEL
      beq +

        jml rlLMDrawEquippedItemPreview

      +

      php
      phb

      sep #$20

      lda #`aBG3TilemapBuffer
      pha

      rep #$30

      plb

      .databank `aBG3TilemapBuffer

      ; Row 4 of the window, one tile in: right below
      ; the "HP" label.

      lda wBurstWindowPositionYTile
      clc
      adc #4
      asl a
      asl a
      asl a
      asl a
      asl a
      clc
      adc wBurstWindowPositionXTile
      inc a
      asl a
      clc
      adc #<>aBG3TilemapBuffer
      tay

      ; Italic "LV" (same style and palette as "HP")

      lda #$3B1E
      sta $0000,b,y
      lda #$3B1F
      sta $0002,b,y

      ; Two digits under the current HP, blank leading zero,
      ; same as the game does for HP.

      lda aBurstWindowCharacterBuffer.Level,b
      and #$00FF
      asl a
      tax

      lda @l aLMDigitPairs+1,x
      and #$00FF
      bne +

        lda #$01DF
        bra ++

      +
      clc
      adc #$3290

      +
      sta $0004,b,y

      lda @l aLMDigitPairs,x
      and #$00FF
      clc
      adc #$3290
      sta $0006,b,y

      plb
      plp

      jml rlLMDrawEquippedItemPreview

      .databank 0

    aLMHoverWindowTilemaps .binary "HoverStyles6.bin"

  .endsection GBABattleForecastWindowSection

.endif ; GUARD_LM_HOVER_LEVEL
