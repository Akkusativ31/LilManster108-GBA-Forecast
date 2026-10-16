
.cpu "65816"

.weak
  WARNINGS :?= "None"
.endweak

GUARD_GBA_FORECAST :?= false
.if (GUARD_GBA_FORECAST && (WARNINGS == "Strict"))

  .warn "File included more than once."

.elsif (!GUARD_GBA_FORECAST)

  ; Definitions

    .include "../VoltEdge/VoltEdge.h"
    .include "SJIS.h"
    .include "LMOptions.h"

    .weak

      ; Configuration

        ; Edit these depending on your use.

        ; Set this to true if using this as a standalone installer,
        ; or set it to false if part of a larger buildfile.
        ; If set to false, you'll have to have
        ; .dsection GBABattleForecastWindowSection
        ; somewhere in your buildfile.
        USE_GBA_FORECAST_FREESPACE :?= true

        ; If using as a standalone installer, set this to where you
        ; want things to be written to.
        ; Lil' Manster: $1FB704 holds Lil' Manster's menu text table,
        ; so use the untouched free space after it in bank $BF
        ; ($1FC742-$1FFFFF is empty in Lil' Manster 1.08).
        GBA_FORECAST_FREESPACE     :?= $1FC800

        ; If using as a standalone installer, set this to be
        ; the path to your clean FE5 ROM.
        ; Lil' Manster: this is the already-patched 1.08 ROM.
        BASEROM :?= "LM108.sfc"

        ; Set this to be the address of some (byte) value
        ; that will be set to use the GBA-styled forecast.
        ; If left as `None`, the GBA-styled forecast will
        ; always be used. It's up to you to set/unset the
        ; value yourself.
        GBA_FORECAST_STYLE_VARIABLE :?= LM_OPTIONS_WORD

        ; This is the value of GBA_FORECAST_STYLE_VARIABLE
        ; that will be checked for to display the GBA-styled
        ; forecast. If left as `None`, any nonzero value will
        ; display the GBA-styled forecast.
        GBA_FORECAST_STYLE_VALUE := None


        ; A translation would probably want to change
        ; these. Be sure to change the encoding where the
        ; text for these is laid down, too.

        ; Lil' Manster replaces the menu text renderer with a
        ; pre-rendered font where each 2-byte code draws one
        ; 8x16 tile holding two 4px-wide letters. These codes
        ; were read out of the Lil' Manster 1.08 ROM's own text
        ; table, so they only use glyphs that already exist there.
        ; They may differ in other Lil' Manster versions.

        .enc "LilManster"
          .edef "\n",  [$00, $00]
          .edef "{H}", [$82, $67] ; wide H (same as vanilla)
          .edef "{P}", [$82, $6F] ; wide P (same as vanilla)
          .edef "{-}", [$81, $5B] ; long dash (same as vanilla)
          .edef "(M",  [$2C, $00] ; wide M
          .edef "t ",  [$28, $00]
          .edef "Hi",  [$27, $00]
          .edef "Cr",  [$50, $00]
          .edef "it",  [$51, $00]

        GBABattleForecastLabelText  := "{H}{P}\n"
        GBABattleForecastLabelText ..= "(Mt \n"
        GBABattleForecastLabelText ..= "Hit \n"
        GBABattleForecastLabelText ..= "Crit\n"
        GBABattleForecastLabelText ..= "\n"

        GBABattleForecastDashText := "{-}{-}\n"

        ; The following values can be edited, but
        ; be careful not to break anything.

        ; In tiles

        UNIT_NAME_WIDTH = 7
        ITEM_NAME_WIDTH = 8

        GBA_FORECAST_SIZE      = (13, 19)
        GBA_FORECAST_POSITIONS = [(1, 1), (19, 1)] ; Left, right windows
        GBA_FORECAST_CENTER    = [(4, 3), (4, 10)] ; Start position, size

        ; These are relative to the top left of the window.

        GBA_FORECAST_UNIT_NAME_POSITION = (4, 1)

        GBA_FORECAST_TARGET_NAME_POSITION        = (1, 13)
        GBA_FORECAST_TARGET_WEAPON_NAME_POSITION = (1, 15)

        GBA_FORECAST_LABEL_POSITION = (5, 4)

        GBA_FORECAST_UNIT_STAT_POSITION   = (10, 4)
        GBA_FORECAST_TARGET_STAT_POSITION = ( 2, 4)

        GBA_FORECAST_UNIT_WEAPON_POSITION   = (1,  1)
        GBA_FORECAST_TARGET_WEAPON_POSITION = (9, 13)

        ; In pixels

        GBA_FORECAST_UNIT_MULTIPLIER_POSITION   = (78, 62)
        GBA_FORECAST_TARGET_MULTIPLIER_POSITION = (14, 62)

        ; Derived values, don't touch.

        GBA_FORECAST_LEFT  = GBA_FORECAST_POSITIONS[0]
        GBA_FORECAST_RIGHT = GBA_FORECAST_POSITIONS[1]

        GBA_FORECAST_CENTER_POSITION = GBA_FORECAST_CENTER[0]
        GBA_FORECAST_CENTER_SIZE     = GBA_FORECAST_CENTER[1]

        GBA_FORECAST_LEFT_CENTER_POSITION  = GBA_FORECAST_LEFT + GBA_FORECAST_CENTER_POSITION
        GBA_FORECAST_RIGHT_CENTER_POSITION = GBA_FORECAST_RIGHT + GBA_FORECAST_CENTER_POSITION

        GBA_FORECAST_LEFT_LABEL_POSITION  = GBA_FORECAST_LEFT + GBA_FORECAST_LABEL_POSITION
        GBA_FORECAST_RIGHT_LABEL_POSITION = GBA_FORECAST_RIGHT + GBA_FORECAST_LABEL_POSITION

        ; This is a lot of work to get 64tass to interleave these two
        ; tilemaps. If your forecast is wider than 16 tiles then this
        ; won't be used, and it'll end up inserting each tilemap
        ; separately, which will take up a lot more space.

        .if (GBA_FORECAST_SIZE[0] < 16)

          BattleForecastBG1TilemapRaw := binary("BG1.bin")
          BattleForecastBG3TilemapRaw := binary("BG3.bin")

          BFTilemapRows := []

          BFRawRowSize := 32 * size(word)
          BFRowSize    := GBA_FORECAST_SIZE[0] * size(word)

          BFPadding := x"0000" x (32 - (GBA_FORECAST_SIZE[0] * 2))

          .for _Offset in range(0, BFRawRowSize * GBA_FORECAST_SIZE[1], BFRawRowSize)
            _BG1Row := BattleForecastBG1TilemapRaw[_Offset:_Offset+BFRowSize]
            _BG3Row := BattleForecastBG3TilemapRaw[_Offset:_Offset+BFRowSize]

            BFTilemapRows ..= [_BG1Row .. _BG3Row .. BFPadding]

          .endfor

        .endif

      ; Resources

        ; RAM stuff that hasn't been named in VoltEdge yet

        aUnknown7E4E6B :?= address($7E4E6B)
        aTargetList    :?= address($7EA7AF)
        aUnknown7F8614 :?= address($7F8614)

        ; Vanilla forecast stuff

        rlGetBattleForecastBGTiles        :?= address($81BF00)
        rlSetBattleForecastWindowShading  :?= address($81BF0E)
        rlBuildBattleForecastWindow       :?= address($81BF33)
        procBattleForecast                :?= address($878900)
        rlProcBattleForecastOnCycle3      :?= address($87895C)
        rlKillBattleForecast              :?= address($8789C5)

        ; Vanilla functions

        rlPushToOAMBuffer                   :?= address($808881)
        rlDMAByStruct                       :?= address($80AE2E)
        rlDMAByPointer                      :?= address($80AEF9)
        rlFillTilemapByWord                 :?= address($80E89F)
        rlEnableBG1Sync                     :?= address($81B1FA)
        rlEnableBG3Sync                     :?= address($81B212)
        rlProcEngineCreateProc              :?= address($829BF1)
        rlProcEngineFindProc                :?= address($829CEC)
        rlProcEngineFreeProc                :?= address($829D11)
        rlGetItemNamePointer                :?= address($83931A)
        rlGetCharacterNamePointer           :?= address($839334)
        rlCopyItemDataToBuffer              :?= address($83B00D)
        rlCheckIfWeaponEffective            :?= address($8397AB)
        rlGetWindowSideByXCoordinate        :?= address($83CB09)
        rlActionStructPlayerCombatSelection :?= address($83CF40)
        rlDMABurstWindowTiles               :?= address($84A17D)
        rlDrawTilemapPackedRect             :?= address($84A3FF)
        rlDrawNumberAsMenuText              :?= address($858859)
        rlDrawMultilineMenuText             :?= address($8588E4)
        rlDrawMenuText                      :?= address($87E728)
        rlGetMenuTextWidth                  :?= address($87E873)

        ; Misc. resources

        aDefaultTilemapInfo    :?= address($83C0F6)

        IconSheet              :?= address($F28000)

        aPlayerForecastPalette :?= address($F4FF24)
        aEnemyForecastPalette  :?= address($F4FF32)
        aNPCForecastPalette    :?= address($F4FF44)

        ; Stuff without good names

        rlUnknown8591F0           :?= address($8591F0)
        rlUnknown859219           :?= address($859219)
        rlUnknown859205           :?= address($859205)
        rlUnknown85946B           :?= address($85946B)
        rlUnknown8594C9           :?= address($8594C9)

        rlUnknown87D4DD           :?= address($87D4DD)
        rlUnknown87D6FC           :?= address($87D6FC)

    .endweak

  ; Fixed-location inclusions

    ; If standalone installer
    .if (USE_GBA_FORECAST_FREESPACE)

      .include "BaseROM.asm"

    .endif ; USE_GBA_FORECAST_FREESPACE

    * := $038932
    .logical mapped($038932)

      rlProcBattleForecastOnCycle ; 87/8932

        .al
        .autsiz
        .databank ?

        jsl rlProcBattleForecastOnCycleReplacement
        rtl

        .checkfit mapped($03893F)

        .databank 0

    .endlogical

    * := $03893F
    .logical mapped($03893F)

      rlProcBattleForecastOnCycle2 ; 87/893F

        .al
        .autsiz
        .databank ?

        jsl rlProcBattleForecastOnCycle2Replacement
        rtl

        .checkfit mapped($03895C)

        .databank 0

    .endlogical

    * := $038980
    .logical mapped($038980)

      rlProcBattleForecastRebuild ; 87/8980

        .al
        .autsiz
        .databank ?

        jsl rlProcBattleForecastRebuildReplacement
        rtl

        .checkfit mapped($0389B2)

        .databank 0

    .endlogical

    * := $0389B2
    .logical mapped($0389B2)

      rlQueueKillBattleForecast ; 87/89B2

        .autsiz
        .databank ?

        jsl rlQueueKillBattleForecastReplacement
        rtl

        .checkfit mapped($0389C5)

        .databank 0

    .endlogical

  ; Freespace inclusions

    .section GBABattleForecastWindowSection

      rlProcBattleForecastOnCycleReplacement

        .al
        .autsiz
        .databank ?

        phx

        .if (GBA_FORECAST_STYLE_VARIABLE != None)

          lda @l GBA_FORECAST_STYLE_VARIABLE
          and #LM_OPTION_FORECAST
          cmp #LM_FORECAST_CLASSIC

          .if (GBA_FORECAST_STYLE_VALUE != None)

            cmp #GBA_FORECAST_STYLE_VALUE
            beq _GBAForecast

          .else

            bne _GBAForecast

          .endif

            ; Otherwise use vanilla forecast

            jsl rlGetBattleForecastBGTiles
            bra +

        _GBAForecast

        .endif

        jsl rlDMAByStruct

        .structDMAToVRAM g4bppGBABattleForecastTiles, size(g4bppGBABattleForecastTiles), VMAIN_Setting(true), $4000

        +

        plx

        lda #<>rlProcBattleForecastOnCycle2
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcBattleForecastOnCycle2Replacement

        .al
        .autsiz
        .databank ?

        php
        phb

        sep #$20

        lda #`aBG1TilemapBuffer
        pha

        rep #$20

        plb

        .databank `aBG1TilemapBuffer

        phx

        jsl rlProcBattleForecastRebuildReplacement

        .if (GBA_FORECAST_STYLE_VARIABLE != None)

          lda @l GBA_FORECAST_STYLE_VARIABLE
          and #LM_OPTION_FORECAST
          cmp #LM_FORECAST_CLASSIC

          .if (GBA_FORECAST_STYLE_VALUE != None)

            cmp #GBA_FORECAST_STYLE_VALUE
            beq _GBAForecast

          .else

            bne _GBAForecast

          .endif

            ; Otherwise use vanilla forecast

            jsl rlSetBattleForecastWindowShading
            bra +

        _GBAForecast

        .endif

        jsl rlUnknown8591F0

        lda #GBA_FORECAST_CENTER_SIZE[0]
        sta wR0
        lda #GBA_FORECAST_CENTER_SIZE[1]
        sta wR1
        jsl rlUnknown859219

        jsl rlUnknown859205

        lda #GBA_FORECAST_CENTER_SIZE[0] * 8
        sta wR1
        lda #GBA_FORECAST_CENTER_SIZE[1] * 8
        sta wR2
        jsl rlUnknown85946B

        +

        plx

        lda #<>rlProcBattleForecastOnCycle3
        sta aProcSystem.aHeaderOnCycle,b,x

        plb
        plp
        rtl

        .databank 0

      rlProcBattleForecastRebuildReplacement

        .al
        .autsiz
        .databank ?

        phx

        lda aProcSystem.aBody7,b,x
        tax

        lda aTargetList,x
        and #$00FF
        sta wR1

        lda #<>aSelectedCharacterBuffer
        sta wR0

        lda wStaffInventoryOffset
        sta wR17

        jsl rlActionStructPlayerCombatSelection

        plx

        lda aActionStructUnit2.Coordinates
        and #$00FF

        jsl rlGetWindowSideByXCoordinate

        dec a
        dec a
        and #$0002
        tax

        .if (GBA_FORECAST_STYLE_VARIABLE != None)

          lda @l GBA_FORECAST_STYLE_VARIABLE
          and #LM_OPTION_FORECAST
          cmp #LM_FORECAST_CLASSIC

          .if (GBA_FORECAST_STYLE_VALUE != None)

            cmp #GBA_FORECAST_STYLE_VALUE
            beq _GBAForecast

          .else

            bne _GBAForecast

          .endif

            ; Otherwise use vanilla forecast

            jsl rlBuildBattleForecastWindow
            bra +

        _GBAForecast

        .endif

        jsl rlBuildGBABattleForecast

        +

        rtl

        .databank 0

      rlQueueKillBattleForecastReplacement

        .autsiz
        .databank ?

        ; Holdovers from vanilla

        lda #<>rlKillBattleForecast
        sta aProcSystem.aHeaderOnCycle,b,x

        jsl rlDMABurstWindowTiles

        sep #$20

        lda #T_Setting(false, true, false, false, true)
        sta bBufferTM

        rep #$20

        ; The following part is for the GBA-styled forecast.
        ; Having them run even without the style in use doesn't hurt
        ; so I'm not going to bother with any conditional stuff.

        ; Find our icon procs and kill them.

        _ProcList  := [procGBABattleForecastUnitIcon]
        _ProcList ..= [procGBABattleForecastTargetIcon]
        _ProcList ..= [procGBABattleForecastMultipliers]

        .for _Proc in _ProcList

          lda #(`_Proc)<<8
          sta lR44+size(byte)
          lda #<>_Proc
          sta lR44
          jsl rlProcEngineFindProc
          bcc +

            jsl rlProcEngineFreeProc

          +

        .endfor

        rtl

        .databank 0

      rlBuildGBABattleForecast

        .al
        .xl
        .autsiz
        .databank ?

        ; Inputs:
        ; X: 0 for left, 2 for right side

        php
        phb

        sep #$20

        lda #`aBG1TilemapBuffer
        pha

        rep #$20

        plb

        .databank `aBG1TilemapBuffer

        stx wR17

        ; Clear tilemaps

        lda #<>aBG1TilemapBuffer
        sta wR0
        lda #TilemapEntry(15 + (47 * 16), 0, false, false, false)
        jsl rlFillTilemapByWord

        lda #<>aBG3TilemapBuffer
        sta wR0
        lda #TilemapEntry(15 + (29 * 16), 0, false, false, false)
        jsl rlFillTilemapByWord

        ; Populate the window

        jsr rsGBABattleForecastBuildTilemap
        jsr rsGBABattleForecastCopyAllegiancePalettes
        jsr rsGBABattleForecastColorWindowCenter
        jsr rsGBABattleForecastDrawUnitText
        jsr rsGBABattleForecastDrawLabels
        jsr rsGBABattleForecastDrawNumbers

        ; Lil' Manster: Thracia-style triangle arrows, if chosen
        ; in the options.

        lda @l LM_OPTIONS_WORD
        and #LM_OPTION_ARROWS
        cmp #LM_ARROWS_THRACIA
        bne _LMNoThraciaArrows

          jsr rsLMForecastDrawThraciaArrows

        _LMNoThraciaArrows

        phx

        ; There's going to be a lot of proc stuff ahead,
        ; so I'm going to write a macro.

        _CallWithProc .segment RoutinePointer, ProcPointer
          lda #(`\ProcPointer)<<8
          sta lR44+size(byte)
          lda #<>\ProcPointer
          sta lR44
          jsl \RoutinePointer
        .endsegment

        ; Set horizontal shading boundaries

        ; Side

        lda wR17
        sta aProcSystem.wInput0,b

        _CallWithProc rlProcEngineCreateProc, procGBABattleForecastCenterShadingBounds

        ; Weapon icons

        ldx wR17
        lda aGBABattleForecastSideTable,x
        sta aProcSystem.wInput0,b

        ; Lil' Manster: the last value is what the proc's
        ; aBody2 starts as. The original left wInput2 as whatever
        ; an earlier proc put there, so the unit icon proc often
        ; thought its icon was "already copied" and never uploaded
        ; it, showing leftover tiles from the hover window instead.
        ; Unit icon: 0 = not copied yet. Target icon: $FF = no
        ; icon cached (icon 0 is a real icon).

        _WeaponIconProcs  := [(aActionStructUnit1.EquippedItemID2, procGBABattleForecastUnitIcon, rlGBAForecastUnitIconUpdateEffective, $00)]
        _WeaponIconProcs ..= [(aActionStructUnit2.EquippedItemID2, procGBABattleForecastTargetIcon, rlProcGBABattleForecastTargetIconOnCycle2, $FF)]

        .for _Item, _Proc, _Updater, _Body2 in _WeaponIconProcs

          lda _Item
          and #$00FF
          sta aProcSystem.wInput1,b

          lda #_Body2
          sta aProcSystem.wInput2,b

          ; Check if proc already exists, updating
          ; existing procs rather than creating new ones.

          _CallWithProc rlProcEngineFindProc, _Proc
          bcc +

            ; Update

            lda aProcSystem.wInput0,b
            sta aProcSystem.aBody0,b,x

            lda aProcSystem.wInput1,b
            sta aProcSystem.aBody1,b,x

            .if (_Updater != None)

              jsl _Updater

            .endif

            bra ++

          +

            _CallWithProc rlProcEngineCreateProc, _Proc

          +

        .endfor

        ; Attack multiplier

        ; These are the units' base number of attacks.

        stz aProcSystem.wInput1,b
        stz aProcSystem.wInput2,b

        sep #$20

        _MultiplierUnits  := [(aActionStructUnit1, aProcSystem.wInput1)]
        _MultiplierUnits ..= [(aActionStructUnit2, aProcSystem.wInput2)]

        .for _Unit, _Input in _MultiplierUnits

          ; Check if unit has a weapon.

          lda _Unit.EquippedItemID2
          beq +

            lda #1
            sta _Input,b

            ; Double if the weapon is brave.

            lda _Unit.Skills3
            bit #Skill3Brave
            beq +

              asl _Input,b

          +

        .endfor

        ; Check if anyone is doubling.

        ; abs(Unit_AS - Target_AS)

        lda aActionStructUnit1.BattleAttackSpeed
        sec
        sbc aActionStructUnit2.BattleAttackSpeed
        bpl +

          eor #-1
          inc a

        +

        cmp #4
        blt _MultiplierContinue

          ; Determine who is doubling.

          lda aActionStructUnit1.BattleAttackSpeed
          cmp aActionStructUnit2.BattleAttackSpeed
          blt _TargetDoubles

            ; Else unit doubles.

            asl aProcSystem.wInput1,b
            bra _MultiplierContinue

          _TargetDoubles

            asl aProcSystem.wInput2,b

        _MultiplierContinue

        rep #$20

        ; If the multiplier proc already exists,
        ; just update the numbers.

        _CallWithProc rlProcEngineFindProc, procGBABattleForecastMultipliers
        bcc +

          lda aProcSystem.wInput0,b
          sta aProcSystem.aBody0,b,x

          lda aProcSystem.wInput1,b
          sta aProcSystem.aBody1,b,x

          lda aProcSystem.wInput2,b
          sta aProcSystem.aBody2,b,x

          jsl rlProcGBABattleForecastMultipliersOnCycle3

          bra ++

        +

          _CallWithProc rlProcEngineCreateProc, procGBABattleForecastMultipliers

        +

        plx

        ; Sync background tilemaps

        jsl rlEnableBG1Sync
        jsl rlEnableBG3Sync

        plb
        plp
        rtl

        .databank 0

      rsLMForecastDrawThraciaArrows

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        ; Lil' Manster: the up/down arrows from Thracia's weapon
        ; info window (menu font, blue text palette), beside
        ; each weapon icon. FE5 gives the unit with the
        ; advantage +5 hit (WeaponTriangleBonus); the other one
        ; gets the down arrow.

        ; Inputs:
        ; wR17: side

        _UnitTop   = ((GBA_FORECAST_UNIT_WEAPON_POSITION[0] + 2) + (GBA_FORECAST_UNIT_WEAPON_POSITION[1] * 32)) * size(word)
        _UnitBot   = _UnitTop + (32 * size(word))
        ; The target's icon sits one tile from the right border,
        ; so its arrow goes on the left of the icon instead,
        ; between the name and the icon (mirroring the unit's).

        _TargetTop = ((GBA_FORECAST_TARGET_WEAPON_POSITION[0] - 1) + (GBA_FORECAST_TARGET_WEAPON_POSITION[1] * 32)) * size(word)
        _TargetBot = _TargetTop + (32 * size(word))

        _UpTop     = TilemapEntry($304, 2, true, false, false)
        _UpBot     = TilemapEntry($314, 2, true, false, false)
        _DownTop   = TilemapEntry($314, 2, true, false, true)
        _DownBot   = TilemapEntry($304, 2, true, false, true)

        ldx wR17
        lda _Base,x
        tax

        sep #$20
        lda aActionStructUnit1.WeaponTriangleBonus
        bne _UnitUp

        lda aActionStructUnit2.WeaponTriangleBonus
        bne _UnitDown

        rep #$20
        rts

        _UnitUp

          rep #$20
          lda #_UpTop
          sta _UnitTop,b,x
          lda #_UpBot
          sta _UnitBot,b,x
          lda #_DownTop
          sta _TargetTop,b,x
          lda #_DownBot
          sta _TargetBot,b,x
          rts

        _UnitDown

          rep #$20
          lda #_DownTop
          sta _UnitTop,b,x
          lda #_DownBot
          sta _UnitBot,b,x
          lda #_UpTop
          sta _TargetTop,b,x
          lda #_UpBot
          sta _TargetBot,b,x
          rts

        _Base
          .word <>aBG3TilemapBuffer + ((GBA_FORECAST_LEFT[0] + (GBA_FORECAST_LEFT[1] * 32)) * size(word))
          .word <>aBG3TilemapBuffer + ((GBA_FORECAST_RIGHT[0] + (GBA_FORECAST_RIGHT[1] * 32)) * size(word))

        .databank 0

      aGBABattleForecastSideTable
        .byte GBA_FORECAST_LEFT, GBA_FORECAST_RIGHT

      ; The tiles image has some extra graphics that we don't want
      ; because they were needed to get superfamiconv to generate
      ; the tilemaps correctly, so we only include the tiles we
      ; need here.

      g4bppGBABattleForecastTiles .binary "ForecastTiles.4bpp", 0, (16 * 4 * size(Tile4bpp))

      .if (GBA_FORECAST_SIZE[0] < 16)

        ; If forecast window is small enough, interleave the
        ; two layers' tilemaps to save space.

        aBattleForecastReplacementBG1Tilemap .text BFTilemapRows
        aBattleForecastReplacementBG3Tilemap = aBattleForecastReplacementBG1Tilemap + BFRowSize

      .else

        ; Otherwise, waste space inserting both separately.

        aBattleForecastReplacementBG1Tilemap .binary "BG1.bin"
        aBattleForecastReplacementBG3Tilemap .binary "BG3.bin"

      .endif

      rsGBABattleForecastBuildTilemap

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        ; Inputs:
        ; wR17: side

        ; Vanilla draws this in segments. Why?
        ; We're going to do it all at once.

        _Layers  := [(aBattleForecastReplacementBG1Tilemap, _BG1VRAMPositions, TilemapEntry(0, 0, true, false, false))]
        _Layers ..= [(aBattleForecastReplacementBG3Tilemap, _BG3VRAMPositions, TilemapEntry(0, 1, true, false, false))]

        .for _Layer in _Layers

          _Tilemap  := _Layer[0]
          _Table    := _Layer[1]
          _BaseTile := _Layer[2]

          lda #_BaseTile
          sta wUnknown000DE7,b

          lda #<>_Tilemap
          sta lR18
          lda #>`_Tilemap
          sta lR18+size(byte)

          ; Width, height

          lda #GBA_FORECAST_SIZE[0]
          sta wR0
          lda #GBA_FORECAST_SIZE[1]
          sta wR1

          ; Determine buffer position by side.

          ldx wR17
          lda _Table,x
          sta lR19

          jsl rlDrawTilemapPackedRect

        .endfor

        rts

        _VRAMPos .sfunction Position, Buffer, (<>Buffer + ((Position[0] + (Position[1] * 32)) * size(word)))

        _BG1VRAMPositions
          .word _VRAMPos(GBA_FORECAST_LEFT, aBG1TilemapBuffer)
          .word _VRAMPos(GBA_FORECAST_RIGHT, aBG1TilemapBuffer)

        _BG3VRAMPositions
          .word _VRAMPos(GBA_FORECAST_LEFT, aBG3TilemapBuffer)
          .word _VRAMPos(GBA_FORECAST_RIGHT, aBG3TilemapBuffer)

        .databank 0

      rsGBABattleForecastCopyAllegiancePalettes

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        ; Copy the right palette based on allegiances

        ldy #<>aBGPaletteBuffer.aPalette1.Colors[2]
        lda aActionStructUnit1.DeploymentNumber
        jsr rsGBABattleForecastCopyAllegiancePalettePart

        ldy #<>aBGPaletteBuffer.aPalette1.Colors[9]
        lda aActionStructUnit2.DeploymentNumber
        jsr rsGBABattleForecastCopyAllegiancePalettePart

        rts

        .databank 0

      rsGBABattleForecastCopyAllegiancePalettePart

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        and #AllAllegiances
        lsr a
        lsr a
        lsr a
        lsr a
        lsr a
        tax
        lda _Palettes,x
        tax
        lda #(7 * size(Color)) - size(byte)
        phb
        mvn #`aPlayerForecastPalette,#`aBGPaletteBuffer
        plb
        rts

        _Palettes
          .word <>aPlayerForecastPalette
          .word <>aEnemyForecastPalette
          .word <>aNPCForecastPalette

        .databank 0

      rsGBABattleForecastColorWindowCenter

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        ; Inputs:
        ; wR17: side

        lda aUnknown7E4E6B
        sta lR18
        lda aUnknown7E4E6B+size(byte)
        sta lR18+size(byte)

        lda #TilemapEntry(0, 2, true, false, false)
        sta wUnknown000DE7,b

        lda #<>_Table
        sta lUnknown000DDE,b
        lda #>`_Table
        sta lUnknown000DDE+size(byte),b

        jsl rlUnknown87D6FC

        ; Get coordinates by side

        lda wR17
        beq _Left

          ldx #(GBA_FORECAST_RIGHT_CENTER_POSITION[0] + (GBA_FORECAST_RIGHT_CENTER_POSITION[1] * 32)) * size(word)
          bra +

        _Left

          ldx #(GBA_FORECAST_LEFT_CENTER_POSITION[0] + (GBA_FORECAST_LEFT_CENTER_POSITION[1] * 32)) * size(word)

        +
        jsl rlUnknown87D4DD
        rts

        _Table
          .byte GBA_FORECAST_CENTER_SIZE
          .long aBG1TilemapBuffer
          .byte 0
          .long aUnknown7F8614

        .databank 0

      rsGBABattleForecastDrawUnitText

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        ; Inputs:
        ; wR17: side

        ; Fetch side coordinates

        ldx wR17
        lda aGBABattleForecastSideTable,x
        sta wR16

        ; Text info

        lda #<>aDefaultTilemapInfo
        sta lUnknown000DDE,b
        lda #>`aDefaultTilemapInfo
        sta lUnknown000DDE+size(byte),b

        lda #TilemapEntry(0 + (24 * 16), 0, true, false, false)
        sta wUnknown000DE7,b

        ; Going to be doing the same thing thrice, might
        ; as well make it a subroutine.

        lda aActionStructUnit1.Character
        jsl rlGetCharacterNamePointer
        lda #UNIT_NAME_WIDTH
        sta wR1
        lda #pack(GBA_FORECAST_UNIT_NAME_POSITION)
        clc
        adc wR16
        sta wR2
        jsr _Draw

        lda aActionStructUnit2.Character
        jsl rlGetCharacterNamePointer
        lda #UNIT_NAME_WIDTH
        sta wR1
        lda #pack(GBA_FORECAST_TARGET_NAME_POSITION)
        clc
        adc wR16
        sta wR2
        jsr _Draw

        sep #$20

        lda aActionStructUnit2.EquippedItemMaxDurability
        xba
        lda aActionStructUnit2.EquippedItemID1
        rep #$20

        jsl rlCopyItemDataToBuffer
        jsl rlGetItemNamePointer
        ; Lil' Manster: centered in the same 7 tiles as the
        ; name above it, like the original. The few 8-tile
        ; weapon names get left-aligned by the check in _Draw.
        lda #UNIT_NAME_WIDTH
        sta wR1
        lda #pack(GBA_FORECAST_TARGET_WEAPON_NAME_POSITION)
        clc
        adc wR16
        sta wR2
        jsr _Draw

        rts

        _Draw

          ; Inputs:
          ; wR1: max text width
          ; wR2: packed coordinates
          ; lR18: long pointer to text

          ; Get the amount to offset
          ; the text in order to center it.

          jsl rlGetMenuTextWidth
          sta wR0

          lda wR1
          sec
          sbc wR0
          bcs +

            ; Lil' Manster: text wider than the box would
            ; underflow here and draw at a garbage position,
            ; so just left-align it instead.

            lda #0

          +
          lsr a

          ; Add offset to position

          clc
          adc wR2

          tax
          jsl rlDrawMenuText

          rts

        .databank 0

      rsGBABattleForecastDrawLabels

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        ; Text info

        lda #<>aDefaultTilemapInfo
        sta lUnknown000DDE,b
        lda #>`aDefaultTilemapInfo
        sta lUnknown000DDE+size(byte),b

        lda #TilemapEntry(0 + (24 * 16), 0, true, false, false)
        sta wUnknown000DE7,b

        ; Draw labels

        lda #<>menutextGBABattleForecastLabels
        sta lR18
        lda #>`menutextGBABattleForecastLabels
        sta lR18+size(byte)

        ldx wR17
        lda _CoordTable,x
        tax
        jsl rlDrawMultilineMenuText

        rts

        _CoordTable
          .byte GBA_FORECAST_LEFT_LABEL_POSITION, GBA_FORECAST_RIGHT_LABEL_POSITION

        .databank 0

      menutextGBABattleForecastLabels
        .enc "LilManster"
        .text GBABattleForecastLabelText

      rsGBABattleForecastDrawNumbers

        .al
        .xl
        .autsiz
        .databank `aBG1TilemapBuffer

        ; Inputs:
        ; wR17: side

        ldx wR17
        lda aGBABattleForecastSideTable,x
        sta wR16

        lda #TilemapEntry(0 + (42 * 16), 2, true, false, false)
        sta wUnknown000DE7,b

        ; Loop counter

        stz wR15

        _Loop

          ; A requirement pointer of -1 terminates the table.

          ldx wR15

          ; If no pointer, skip ahead.

          lda _StatTable,x
          beq +

            ; End of table

            cmp #-1
            beq _End

              ; If requirement stat is 0, show dashes.

              tay
              lda 0,b,y
              and #$00FF
              beq _Dashed

          +
          stz lR18+size(byte)

          ; Get stat, show dashes if N/A

          lda _StatTable+size(word),x
          tay

          lda 0,b,y
          and #$00FF
          cmp #narrow(-1, 1)
          beq _Dashed

            sta lR18

            ; Get opponent's stat, skip if none.

            lda _StatTable+(size(word) * 2),x
            beq _Continue

              tay

              lda lR18

              sep #$20

              sec
              sbc 0,b,y

              ; Check if number needs to be raised to the minimum.

              cmp _StatTable+(size(word) * 3),x
              bpl +

                lda _StatTable+(size(word) * 3),x

              +

              sta lR18

              rep #$20

            _Continue

            lda _StatTable+(size(word) * 3)+size(byte),x
            clc
            adc wR16
            tax
            jsl rlDrawNumberAsMenuText

        _Next
          lda wR15
          clc
          adc #(size(word) * 3) + (size(byte) * 3)
          sta wR15
          bra _Loop

        _End
          rts

        _Dashed
          lda #TilemapEntry(0 + (24 * 16), 2, true, false, false)
          sta wUnknown000DE7,b

          ; Move left a tile because numbers are right-aligned
          ; but text is left-aligned.

          lda _StatTable+(size(word) * 3)+size(byte),x
          dec a
          clc
          adc wR16
          tax

          lda #<>menutextGBABattleForecastDash
          sta lR18
          lda #>`menutextGBABattleForecastDash
          sta lR18+size(byte)

          jsl rlDrawMenuText

          lda #TilemapEntry(0 + (42 * 16), 2, true, false, false)
          sta wUnknown000DE7,b

          bra _Next

        _StatTable

          ; Format:
          ; optional short pointer to requirement stat
          ; short pointer to displayed stat
          ; optional short pointer to opponent stat
          ; byte min stat
          ; byte (x, y)

          .word <>None
          .word <>aActionStructUnit2.StartingCurrentHP
          .word <>None
          .byte 0
          .byte GBA_FORECAST_TARGET_STAT_POSITION + (0, 0)

          .word <>aActionStructUnit2.EquippedItemID2
          .word <>aActionStructUnit2.BattleMight
          .word <>aActionStructUnit1.BattleDefense
          .byte 0
          .byte GBA_FORECAST_TARGET_STAT_POSITION + (0, 2)

          .word <>aActionStructUnit2.EquippedItemID2
          .word <>aActionStructUnit2.BattleAdjustedHit
          .word <>None
          .byte 1
          .byte GBA_FORECAST_TARGET_STAT_POSITION + (0, 4)

          .word <>aActionStructUnit2.EquippedItemID2
          .word <>aActionStructUnit2.BattleAdjustedCrit
          .word <>None
          .byte 0
          .byte GBA_FORECAST_TARGET_STAT_POSITION + (0, 6)

          .word <>None
          .word <>aActionStructUnit1.StartingCurrentHP
          .word <>None
          .byte 0
          .byte GBA_FORECAST_UNIT_STAT_POSITION + (0, 0)

          .word <>aActionStructUnit1.EquippedItemID2
          .word <>aActionStructUnit1.BattleMight
          .word <>aActionStructUnit2.BattleDefense
          .byte 0
          .byte GBA_FORECAST_UNIT_STAT_POSITION + (0, 2)

          .word <>aActionStructUnit1.EquippedItemID2
          .word <>aActionStructUnit1.BattleAdjustedHit
          .word <>None
          .byte 1
          .byte GBA_FORECAST_UNIT_STAT_POSITION + (0, 4)

          .word <>aActionStructUnit1.EquippedItemID2
          .word <>aActionStructUnit1.BattleAdjustedCrit
          .word <>None
          .byte 0
          .byte GBA_FORECAST_UNIT_STAT_POSITION + (0, 6)

          .sint -1

        .databank 0

        menutextGBABattleForecastDash
          .enc "LilManster"
          .text GBABattleForecastDashText

      rsGBABattleForecastDMAItemIcon

        .al
        .autsiz
        .databank ?

        ; This is basically rlDMASheetIconByVRAMOffset
        ; ($8A8286) but in parts to form a 16x16 object.

        ; Inputs:
        ; wR0: Item icon ID
        ; wR1: VRAM offset

        ; Outputs:
        ; None

        lda #>`IconSheet
        sta lR18+size(byte)

        lda wR0
        asl a
        asl a
        asl a
        asl a
        asl a
        asl a
        asl a

        clc
        adc #<>IconSheet

        ; Save these for second row.

        pha
        pei wR1

        sta lR18

        lda #size(Tile4bpp) * 2
        sta wR0

        jsl rlDMAByPointer

        pla
        clc
        adc #(size(Tile4bpp) * 16) >> 1
        sta wR1

        pla
        clc
        adc #size(Tile4bpp) * 2
        sta lR18

        lda #size(Tile4bpp) * 2
        sta wR0

        jsl rlDMAByPointer

        rts

        .databank 0

      procGBABattleForecastCenterShadingBounds .structProcInfo None, rlProcGBABattleForecastCenterShadingBoundsInit, rlProcGBABattleForecastCenterShadingBoundsOnCycle, None

      rlProcGBABattleForecastCenterShadingBoundsInit

        .al
        .xl
        .autsiz
        .databank ?

        ; Inputs:
        ; aProcSystem.wInput0: 0 for right, 2 for left side

        ; Copy side into proc.

        lda aProcSystem.wInput0,b
        sta aProcSystem.aBody0,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastCenterShadingBoundsOnCycle

        .al
        .xl
        .autsiz
        .databank ?

        ; Delay by a cycle.

        lda #<>rlProcGBABattleForecastCenterShadingBoundsOnCycle2
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastCenterShadingBoundsOnCycle2

        .al
        .xl
        .autsiz
        .databank ?

        ; Use the side to select start, stop pixels.

        phx

        lda aProcSystem.aBody0,b,x
        tax

        lda _BoundsTable,x
        jsl rlUnknown8594C9

        plx

        jsl rlProcEngineFreeProc

        rtl

        _BoundsTable
          .byte (GBA_FORECAST_LEFT_CENTER_POSITION[0], (GBA_FORECAST_LEFT_CENTER_POSITION + GBA_FORECAST_CENTER_SIZE)[0]) * 8
          .byte (GBA_FORECAST_RIGHT_CENTER_POSITION[0], (GBA_FORECAST_RIGHT_CENTER_POSITION + GBA_FORECAST_CENTER_SIZE)[0]) * 8

      rlProcGBABattleForecastCommonInit

        .al
        .autsiz
        .databank ?

        ; Rather than having multiple init routines
        ; that do the same thing, just have them all call this.

        lda aProcSystem.wInput0,b
        sta aProcSystem.aBody0,b,x

        lda aProcSystem.wInput1,b
        and #$00FF
        sta aProcSystem.aBody1,b,x

        ; This is only used by the multipliers proc, but
        ; it doesn't hurt to do it for the others.

        lda aProcSystem.wInput2,b
        and #$00FF
        sta aProcSystem.aBody2,b,x

        rtl

        .databank 0

      rsProcGBABattleForecastCommonRenderer

        .al
        .xl
        .autsiz
        .databank ?

        ; Inputs:
        ; X: proc offset
        ; Y: short pointer to sprite array
        ; wR1: packed coordinates

        lda wR1
        clc
        adc aProcSystem.aBody0,b,x
        pha

        and #$00FF
        asl a
        asl a
        asl a
        sta wR0

        pla
        xba
        and #$00FF
        asl a
        asl a
        asl a
        sta wR1

        stz wR4

        ; Lil' Manster: an effective weapon's icon uses palette
        ; 7 (5 | 2), which the multiplier proc keeps flashing.

        lda aProcSystem.aBody6,b,x
        beq +

          lda #$0400

        +
        sta wR5

        jsl rlPushToOAMBuffer

        rts

        .databank 0

      procGBABattleForecastUnitIcon .structProcInfo "iu", rlProcGBABattleForecastCommonInit, rlProcGBABattleForecastUnitIconOnCycle, None

      rlProcGBABattleForecastUnitIconOnCycle

        .al
        .xl
        .autsiz
        .databank ?

        ; Delay by a frame to wait for window to DMA

        lda #<>rlProcGBABattleForecastUnitIconOnCycle2
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastUnitIconOnCycle2

        .al
        .xl
        .autsiz
        .databank ?

        jsl rlGBAForecastUnitIconUpdateEffective

        ; Copy unit's icon

        ; First, check if already copied

        lda aProcSystem.aBody2,b,x
        bne +

        ; If not already copied, try copying.

        lda aProcSystem.aBody1,b,x
        beq +

          phx

          jsl rlCopyItemDataToBuffer

          lda aItemDataBuffer.Icon,b
          and #$00FF
          sta wR0

          lda #TileToVRAM(0 + (20 * 16), $0000, size(Tile4bpp))
          sta wR1

          jsr rsGBABattleForecastDMAItemIcon

          plx

        +

        lda #<>rlProcGBABattleForecastUnitIconOnCycle3
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastUnitIconOnCycle3

        .al
        .xl
        .autsiz
        .databank ?

        ; If done copying, flag icons as ready to display.

        lda bDMAArrayFlag,b
        ora bDecompressionArrayFlag,b
        ora aProcSystem.aBody2,b,x
        bne +

          lda #1
          sta aProcSystem.aBody2,b,x

          ; We only need to do this once, update the
          ; OnCycle to skip this part.

          lda #<>(+)
          sta aProcSystem.aHeaderOnCycle,b,x

        +

        ; Check if forecast has been killed, kill renderer.

        phx

        lda #(`procBattleForecast)<<8
        sta lR44+size(byte)
        lda #<>procBattleForecast
        sta lR44
        jsl rlProcEngineFindProc
        bcs +

          plx
          jsl rlProcEngineFreeProc
          rtl

        +

        ; Check if target has been selected

        lda aProcSystem.aBody4,b,x
        beq +

          plx
          jsl rlProcEngineFreeProc
          rtl

        +

        plx

        ; Render sprite

        ; First, check if there's an icon.

        lda aProcSystem.aBody1,b,x
        beq +

          lda #pack(GBA_FORECAST_UNIT_WEAPON_POSITION)
          sta wR1

          ldy #<>_Sprite

          jsr rsProcGBABattleForecastCommonRenderer

        +

        rtl

        _Sprite .structSpriteArray [[[0, 0], $00, SpriteLarge, $140, 3, 5, false, false]]

        .databank 0

      procGBABattleForecastTargetIcon .structProcInfo "it", rlProcGBABattleForecastCommonInit, rlProcGBABattleForecastTargetIconOnCycle, None

      rlProcGBABattleForecastTargetIconOnCycle

        .al
        .xl
        .autsiz
        .databank ?

        ; Delay by a frame to wait for window to DMA

        lda #<>rlProcGBABattleForecastTargetIconOnCycle2
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastTargetIconOnCycle2

        .al
        .xl
        .autsiz
        .databank ?

        jsl rlGBAForecastTargetIconUpdateEffective

        ; Check if we already have the requested icon
        ; copied.

        lda aProcSystem.aBody1,b,x
        beq +

          phx

          jsl rlCopyItemDataToBuffer
          lda aItemDataBuffer.Icon,b
          and #$00FF

          plx

          cmp aProcSystem.aBody2,b,x
          beq +

            phx

            sta wR0

            lda #TileToVRAM(2 + (20 * 16), $0000, size(Tile4bpp))
            sta wR1

            jsr rsGBABattleForecastDMAItemIcon

            plx

        +

        lda #<>rlProcGBABattleForecastTargetIconOnCycle3
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastTargetIconOnCycle3

        .al
        .xl
        .autsiz
        .databank ?

        ; If done copying, flag icons as ready to display.

        lda bDMAArrayFlag,b
        ora bDecompressionArrayFlag,b
        bne +

        lda aProcSystem.aBody1,b,x
        beq +

          phx

          jsl rlCopyItemDataToBuffer
          lda aItemDataBuffer.Icon,b
          and #$00FF

          plx

          sta aProcSystem.aBody2,b,x

          ; We only need to do this once, update the
          ; OnCycle to skip this part.

          lda #<>(+)
          sta aProcSystem.aHeaderOnCycle,b,x

        +

        ; Check if forecast has been killed, kill renderer.

        phx

        lda #(`procBattleForecast)<<8
        sta lR44+size(byte)
        lda #<>procBattleForecast
        sta lR44
        jsl rlProcEngineFindProc
        bcs +

          plx
          jsl rlProcEngineFreeProc
          rtl

        +

        ; Check if target has been selected

        lda aProcSystem.aBody4,b,x
        beq +

          plx
          jsl rlProcEngineFreeProc
          rtl

        +

        plx

        ; Render sprite

        ; First, check if there's an icon.

        lda aProcSystem.aBody1,b,x
        beq +

          lda #pack(GBA_FORECAST_TARGET_WEAPON_POSITION)
          sta wR1

          ldy #<>_Sprite

          jsr rsProcGBABattleForecastCommonRenderer

        +

        rtl

        _Sprite .structSpriteArray [[[0, 0], $00, SpriteLarge, $142, 3, 5, false, false]]

        .databank 0

      g4bppGBABattleForecastMultiplierTiles .binary "Multipliers.4bpp"

      ; Lil' Manster: must directly follow the multiplier tiles,
      ; both are uploaded in one transfer.
      g4bppGBAForecastTriangleArrowTiles .binary "TriangleArrows.4bpp"

      procGBABattleForecastMultipliers .structProcInfo "Bm", rlProcGBABattleForecastCommonInit, rlProcGBABattleForecastMultipliersOnCycle, None

      rlProcGBABattleForecastMultipliersOnCycle

        .al
        .xl
        .autsiz
        .databank ?

        ; Delay by a frame to wait for window to DMA

        lda #<>rlProcGBABattleForecastMultipliersOnCycle2
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastMultipliersOnCycle2

        .al
        .autsiz
        .databank ?

        phx
        jsl rlDMAByStruct

        .structDMAToVRAM g4bppGBABattleForecastMultiplierTiles, size(g4bppGBABattleForecastMultiplierTiles) + size(g4bppGBAForecastTriangleArrowTiles), VMAIN_Setting(true), $2880

        plx

        lda #<>rlProcGBABattleForecastMultipliersOnCycle3
        sta aProcSystem.aHeaderOnCycle,b,x

        rtl

        .databank 0

      rlProcGBABattleForecastMultipliersOnCycle3

        .al
        .autsiz
        .databank ?

        ; Lil' Manster: advance the float animation, one loop
        ; every 64 frames like FE8's forecast. This has to happen
        ; here, while X is still this proc: after the
        ; rlProcEngineFindProc below, X points at the main
        ; forecast proc until the loop restores it.

        ; Without animation the counter parks on an extra
        ; table entry with no offset (and no bob).

        lda @l LM_OPTIONS_WORD
        and #LM_OPTION_FORECAST
        cmp #LM_FORECAST_STILL
        bne _LMAnimated

          lda #64
          bra _LMSetCounter

        _LMAnimated

        lda aProcSystem.aBody5,b,x
        inc a
        and #$003F

        _LMSetCounter
        sta aProcSystem.aBody5,b,x

        ; Check if forecast has been killed, kill renderer.

        php
        phb
        phx

        lda #(`procBattleForecast)<<8
        sta lR44+size(byte)
        lda #<>procBattleForecast
        sta lR44
        jsl rlProcEngineFindProc
        bcs +

          plx
          plb
          plp
          jsl rlProcEngineFreeProc
          rtl

        +

        ; Check if target has been selected

        lda aProcSystem.aBody4,b,x
        beq +

          plx
          plb
          plp
          jsl rlProcEngineFreeProc
          rtl

        +

        sep #$20

        lda #`_MultiplierSpriteTable
        pha

        rep #$20

        plb

        .databank `_MultiplierSpriteTable

        ; Lil' Manster: effective weapon flash.

        plx
        phx
        jsr rsGBAForecastAnimateEffectivePalette

        _Multipliers  := [(aProcSystem.aBody1, GBA_FORECAST_UNIT_MULTIPLIER_POSITION)]
        _Multipliers ..= [(aProcSystem.aBody2, GBA_FORECAST_TARGET_MULTIPLIER_POSITION)]

        .for _ItemOffset, _Coordinates in _Multipliers

          plx
          phx

          ; Check if we have a number to draw

          lda _ItemOffset,b,x
          cmp #2
          blt +

            ; Get sprite to draw

            sec
            sbc #2

            tay
            lda _MultiplierSpriteTable,y
            tay

            lda aProcSystem.aBody0,b,x
            and #$00FF
            asl a
            asl a
            asl a
            clc
            adc #_Coordinates[0]
            sta wR0

            lda aProcSystem.aBody0,b,x
            xba
            and #$00FF
            asl a
            asl a
            asl a
            clc
            adc #_Coordinates[1]
            sta wR1

            ; Lil' Manster: float offset

            phy

            lda aProcSystem.aBody5,b,x
            asl a
            tay

            lda _FloatXTable,y
            clc
            adc wR0
            sta wR0

            lda _FloatYTable,y
            clc
            adc wR1
            sta wR1

            ply

            stz wR4
            stz wR5

            jsl rlPushToOAMBuffer

          +

        .endfor

        ; Lil' Manster: weapon triangle arrows, placed like the
        ; GBA games (11 pixels right of the weapon icon's left
        ; edge, level with its top). FE5 gives the unit with the
        ; advantage +5 hit and stores it in WeaponTriangleBonus;
        ; the other unit gets the down arrow.

        _Arrows  := [(aActionStructUnit1.WeaponTriangleBonus, aActionStructUnit2.WeaponTriangleBonus, GBA_FORECAST_UNIT_WEAPON_POSITION)]
        _Arrows ..= [(aActionStructUnit2.WeaponTriangleBonus, aActionStructUnit1.WeaponTriangleBonus, GBA_FORECAST_TARGET_WEAPON_POSITION)]

        lda @l LM_OPTIONS_WORD
        and #LM_OPTION_ARROWS
        beq _LMGBAArrows
        jmp _LMArrowsDone

        _LMGBAArrows

        .for LMArrowOwn, LMArrowOther, LMArrowIcon in _Arrows

          .block

            plx
            phx

            sep #$20
            lda @l LMArrowOwn
            rep #$20
            and #$00FF
            beq _NotUp

              ldy #<>GBAForecastArrowUpSprite
              lda #0
              bra _Draw

            _NotUp

            sep #$20
            lda @l LMArrowOther
            rep #$20
            and #$00FF
            beq _Done

              ldy #<>GBAForecastArrowDownSprite
              lda #8

            _Draw

            ; Bob step: (counter / 8) & 3, as a word offset,
            ; added to the up (0) or down (8) half of the table.

            pha

            lda aProcSystem.aBody5,b,x
            lsr a
            lsr a
            and #$0006
            clc
            adc $01,s
            sta $01,s

            lda aProcSystem.aBody0,b,x
            and #$00FF
            asl a
            asl a
            asl a
            clc
            adc #(LMArrowIcon[0] * 8) + 11
            sta wR0

            lda aProcSystem.aBody0,b,x
            xba
            and #$00FF
            asl a
            asl a
            asl a
            clc
            adc #(LMArrowIcon[1] * 8)
            sta wR1

            plx

            lda GBAForecastArrowBob,x
            clc
            adc wR1
            sta wR1

            stz wR4
            stz wR5

            jsl rlPushToOAMBuffer

            _Done

          .endblock

        .endfor

        _LMArrowsDone

        plx
        plb
        plp

        rtl

        _MultiplierSpriteTable
          .addr GBABattleForecastMultiplierDoubleSprite
          .addr GBABattleForecastMultiplierQuadSprite

        ; Lil' Manster: float offsets in pixels, a small ellipse
        ; (x -4..+4, y -2..+2) matching FE8's battle forecast.

        _FloatXTable .sint 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 4, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 1, 1, 1, 0, 0, 0, -1, -1, -2, -2, -2, -3, -3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -3, -3, -3, -2, -2, -2, -1, -1, 0
        _FloatYTable .sint 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0

        GBABattleForecastMultiplierDoubleSpriteData  := [[[0, 0], $00, SpriteSmall, 4 + (20 * 16), 3, 1, false, false]]
        GBABattleForecastMultiplierDoubleSpriteData ..= [[[8, 0], $00, SpriteSmall, 5 + (20 * 16), 3, 1, false, false]]
        GBABattleForecastMultiplierDoubleSpriteData ..= [[[8, -8], $00, SpriteSmall, 7 + (20 * 16), 3, 1, false, false]]

        GBABattleForecastMultiplierDoubleSprite .structSpriteArray GBABattleForecastMultiplierDoubleSpriteData

        GBABattleForecastMultiplierQuadSpriteData  := [[[0, 0], $00, SpriteSmall, 4 + (20 * 16), 3, 0, false, false]]
        GBABattleForecastMultiplierQuadSpriteData ..= [[[8, 0], $00, SpriteSmall, 6 + (20 * 16), 3, 0, false, false]]
        GBABattleForecastMultiplierQuadSpriteData ..= [[[8, -8], $00, SpriteSmall, 8 + (20 * 16), 3, 0, false, false]]

        GBABattleForecastMultiplierQuadSprite   .structSpriteArray GBABattleForecastMultiplierQuadSpriteData

        ; Lil' Manster: triangle arrows, 8x16 each as two 8x8
        ; pieces in tiles $149-$14C (uploaded right after the
        ; multiplier tiles). Up = unit palette 2 (green),
        ; down = unit palette 1 (red).

        GBAForecastArrowUpSpriteData    := [[[0, 0], $00, SpriteSmall,  9 + (20 * 16), 3, 2, false, false]]
        GBAForecastArrowUpSpriteData   ..= [[[0, 8], $00, SpriteSmall, 10 + (20 * 16), 3, 2, false, false]]

        GBAForecastArrowUpSprite .structSpriteArray GBAForecastArrowUpSpriteData

        GBAForecastArrowDownSpriteData  := [[[0, 0], $00, SpriteSmall, 11 + (20 * 16), 3, 1, false, false]]
        GBAForecastArrowDownSpriteData ..= [[[0, 8], $00, SpriteSmall, 12 + (20 * 16), 3, 1, false, false]]

        GBAForecastArrowDownSprite .structSpriteArray GBAForecastArrowDownSpriteData

        ; Bob offsets in pixels: up arrows bob upward, down
        ; arrows downward, one step every 8 frames.

        GBAForecastArrowBob .sint 0, -1, -2, -1, 0, 1, 2, 1

        .databank 0

      ; Lil' Manster: effective weapon flash, like FE8's forecast.

      rlGBAForecastUnitIconUpdateEffective

        .al
        .xl
        .autsiz
        .databank ?

        ; X: unit icon proc. Stores 1 in aBody6 if the
        ; unit's weapon is effective against the target.

        lda #<>aActionStructUnit1
        ldy #<>aActionStructUnit2
        jsl rlGBAForecastCheckEffective
        jsr rsLMForecastFlashAllowed
        sta aProcSystem.aBody6,b,x
        rtl

        .databank 0

      rlGBAForecastTargetIconUpdateEffective

        .al
        .xl
        .autsiz
        .databank ?

        ; X: target icon proc. Same, for the target's weapon.

        lda #<>aActionStructUnit2
        ldy #<>aActionStructUnit1
        jsl rlGBAForecastCheckEffective
        jsr rsLMForecastFlashAllowed
        sta aProcSystem.aBody6,b,x
        rtl

        .databank 0

      rsLMForecastFlashAllowed

        .al
        .autsiz
        .databank ?

        ; Lil' Manster: no flashing in the still forecast.
        ; A: effectiveness result, cleared if still.

        pha
        lda @l LM_OPTIONS_WORD
        and #LM_OPTION_FORECAST
        cmp #LM_FORECAST_STILL
        beq +

          pla
          rts

        +
        pla
        lda #0
        rts

        .databank 0

      rlGBAForecastCheckEffective

        .al
        .xl
        .autsiz
        .databank ?

        ; Uses the game's own effectiveness check, the one
        ; the damage calculation uses.

        ; Inputs:
        ; A: short pointer to the attacker's action struct
        ; Y: short pointer to the defender's action struct

        ; Outputs:
        ; A: 1 if the attacker's weapon is effective, else 0

        php
        phb
        phx
        phy

        tax

        sep #$20

        lda #`aActionStructUnit1
        pha
        plb

        .databank `aActionStructUnit1

        lda structActionStructEntry.EquippedItemID1,b,x
        beq _No

          lda structActionStructEntry.EquippedItemMaxDurability,b,x
          xba
          lda structActionStructEntry.EquippedItemID1,b,x

          rep #$20

          jsl rlCopyItemDataToBuffer

          lda $01,s
          sta wR1

          lda bActionStructDistance
          and #$00FF

          jsl rlCheckIfWeaponEffective

          lda #0
          bcc _Done

          lda #1
          bra _Done

        _No

          rep #$20
          lda #0

        _Done

        ply
        plx
        plb
        plp
        rtl

        .databank 0

      rsGBAForecastAnimateEffectivePalette

        .al
        .xl
        .autsiz
        .databank `GBAForecastFlashBright

        ; Inputs:
        ; X: multiplier proc (frame counter in aBody5)
        ; DB: this bank

        ; Fills palette 7 with the icon palette (5),
        ; brightened by 3 per step per channel (capped),
        ; following FE8's 32-frame pulse.

        lda @l LM_OPTIONS_WORD
        and #LM_OPTION_FORECAST
        cmp #LM_FORECAST_STILL
        bne +
          rts
        +

        lda aProcSystem.aBody5,b,x
        and #$001F
        tay

        lda GBAForecastFlashLevels,y
        and #$00FF
        asl a
        asl a
        asl a
        asl a
        asl a
        sta wR6

        ldx #size(word)

        _Loop

          lda aOAMPaletteBuffer.aPalette5,b,x
          sta wR2

          ; Red

          and #$001F
          ora wR6
          tay
          lda GBAForecastFlashBright,y
          and #$00FF
          sta wR3

          ; Green

          lda wR2
          lsr a
          lsr a
          lsr a
          lsr a
          lsr a
          sta wR2
          and #$001F
          ora wR6
          tay
          lda GBAForecastFlashBright,y
          and #$00FF
          asl a
          asl a
          asl a
          asl a
          asl a
          tsb wR3

          ; Blue

          lda wR2
          lsr a
          lsr a
          lsr a
          lsr a
          lsr a
          and #$001F
          ora wR6
          tay
          lda GBAForecastFlashBright,y
          and #$00FF
          xba
          asl a
          asl a
          tsb wR3

          lda wR3
          sta aOAMPaletteBuffer.aPalette7,b,x

          inc x
          inc x
          cpx #size(aOAMPaletteBuffer.aPalette7)
          bne _Loop

        rts

        .databank 0

      ; Brightness step per frame (FE8's table).

      GBAForecastFlashLevels
        .byte 0, 1, 1, 2, 3, 4, 5, 5, 4, 4, 4, 3, 3, 3, 2, 2, 2, 2, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0

      ; GBAForecastFlashBright[step * 32 + value] = min(31, value + 3 * step)

      GBAForecastFlashBright
          .byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
          .byte 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 31, 31, 31
          .byte 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 31, 31, 31, 31, 31, 31
          .byte 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
          .byte 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
          .byte 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31

    .endsection GBABattleForecastWindowSection

  ; Lil' Manster: level in the map hover window

    .include "HoverWindowLevel.asm"

  ; Lil' Manster: Configuration menu rows for all of this

    .include "OptionsMenu.asm"

  ; Standalone installer

    .if (USE_GBA_FORECAST_FREESPACE)

      * := GBA_FORECAST_FREESPACE
      .logical mapped(GBA_FORECAST_FREESPACE)

        .dsection GBABattleForecastWindowSection

      .endlogical

    .endif ; USE_GBA_FORECAST_FREESPACE

.endif ; GUARD_GBA_FORECAST
