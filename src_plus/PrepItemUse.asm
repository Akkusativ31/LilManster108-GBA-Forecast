; Lil' Manster: use stat-boosting rings in the preparations
; Items menu, like the GBA games.
;
; Items > (unit) > Discard > pick a ring. If the unit is deployed,
; the prompt becomes "Use or discard item?" with Use / Discard / No.
; Using it runs the same stat-gain code the map's Item > Use does
; (same amounts, same caps) and removes the ring.
;
; A unit that used an item in prep is locked into the lineup for
; this chapter: the Deploy screen won't remove it. That keeps the
; rule from the map (only units in the chapter can use items).
;
; Only the nine rings are usable here. Promotion items, Stamina
; Drinks, manuals and consumables stay map-only.
;
; All addresses are Lil' Manster 1.08's.

GUARD_LM_PREP_ITEM_USE :?= false
.if (!GUARD_LM_PREP_ITEM_USE)
  GUARD_LM_PREP_ITEM_USE := true

  ; Game variables (direct page / bank $7E, as the prep code uses them)

  LMJoy1New             = $00E8
  LMPrepSelectedUnit    = $7E0E6F ; aSelectedCharacterBuffer
  LMPrepSelectedItems   = $7E0E8E ; .Items
  LMPrepSelectedState   = $7E0E74 ; .UnitState
  LMPrepSelectedPointer = $7E0EB1 ; .DeploymentSlot (pointer to the unit's struct)
  LMPrepSelectedNumber  = $7E0EB0 ; .DeploymentNumber
  LMCurrentChapter      = $7E0E11
  LMPrepItemsAction     = $7E4E0A ; wPrepItemsActionIndex
  LMPrepConfirmCursor   = $7E4FA0 ; wActiveTileUnitParameter1 (0 / 2 / 4)
  LMPrepDiscardIndex    = $7EB6ED ; wPrepItemsDiscardIndex
  LMItemUseEffect       = $7E0F4C ; aItemDataBuffer.UseEffect

  LMActionDiscard       = $0007 ; aMainPrepItemsActionTable.Discard
  LMActionConfirm       = $000A ; aMainPrepItemsActionTable.HandleDiscardConfirm

  ; Our own variables, in WRAM that's free in every scene we checked
  ; (title, map, battles, menus, preps). Reset clears it.

  LMPrepUseMode   = $7EFF7E ; 1 while our three-choice prompt is up
  LMPrepLockTag   = $7EFF80 ; $4C00 | chapter the lock list belongs to
  LMPrepLockCount = $7EFF82
  LMPrepLocks     = $7EFF84 ; up to 16 unit struct pointers

  LMPrepLockSearch = $7EFF7C ; scratch for the lock search
  LMPrepPromoCount = $7EFFA4 ; units waiting to promote on turn 1
  LMPrepPromos     = $7EFFA6 ; their deployment numbers (bytes)
  LMPrepSavedMusic = $7EFFB8 ; chapter map music while the scenes play
  LMPrepMsgBuffer  = $7EFFBA ; menu text built for the use message (16 words)
  LMPrepMsgItem    = $7EFFDC ; item that was just used
  LMPrepWaitStart  = $7EFFDE ; frame count when the wait began
  LMPrepWaitActive = $7EFFE0
  LMPrepMusic      = $2D     ; preparations theme ($888374 starts it)
  LMPrepPromoMax   = 16

  LMPrepLockMax   = 16

  ; Rings: LuckRing ($7D) .. LegRing ($85)

  LMFirstRing = $7D
  LMLastRing  = $85

  ; Knight Crest ($86): promotion, like the map's Item > Use
  ; minus the promotion scene.

  LMKnightCrest = $86

  ; Manuals: ParagonManual ($9E) .. LunaManual ($A7), teach a skill

  LMFirstManual = $9E
  LMLastManual  = $A7

  ; Routines

  rlLMClearDiscardDescription = address($81F1CB)
  rlLMEnableBG3Sync           = address($81B212)
  rlLMDrawMenuText            = address($87E728)
  rlLMCopyItemDataToBuffer    = address($83B00D)
  rlLMClearStatGains          = address($83E033)
  rlLMCopyExpandedBuffer      = address($83905C)
  rlLMCapStatGains            = address($83DFD6)
  rlLMPlaySound               = address($808C87)
  rlLMPlayExtendedSound       = address($808CDD)
  aLMPopUpSkillNames          = address($84E896) ; long pointers, Paragon..Luna
  rlLMDrawNumber              = address($858859)
  rlLMCanPromote              = address($87C09E) ; carry set if usable
  rlLMCanLearnSkill           = address($87BDD7) ; carry set if usable
  aLMManualSkillTable         = address($87BDAF) ; use effect, skills 1-3 bits
  rlLMGetPromotionClass       = address($83A9A6) ; A: character -> class
  rlLMPromoteBuffer           = address($87C113) ; wR0: new class
  rlLMCompactInventory        = address($83A49C) ; wR1: buffer
  rlLMCopyCharacterFromBuffer = address($839041) ; wR1: buffer
  rlLMDrawHoveredUnitInfo     = address($81E552)
  rlLMCopyCharacterToBuffer   = address($83901C) ; wR0: deployment number, wR1: buffer
  rlLMRunEventDefinitions     = address($8C9601) ; lR18: definition array
  rlLMRunChapterTurnEvents    = address($8C9C93)
  rlLMASMCPromoteUnit         = address($8CA36B)
  LMRtsInBank83               = address($838195)
  LMPlayerPhaseNext           = address($838529) ; advance the player phase substate
  LMPrepMenuProc              = address($8A8580)
  rlLMPrepBuildUnitList       = address($85F418)
  rlLMProcEngineCreateProc    = address($829BF1) ; lR44: proc
  LMNextGameState             = address($8381BF) ; jmp to the next state
  LMEventEngineStatus         = $7E172C
  LMEventEngineCharacterTarget = $7E1736
  LMEventEngineParameter1     = $7E1740
  LMEventEngineTruthFlag      = $7E174B
  LMCurrentTurn               = $7E0E13
  LMCurrentPhase              = $7E0E15
  lLMActionCallback           = $7EA4EC
  LMConfirmAfterRedraw        = address($81F2E3) ; cursor fix after a discard

  aLMRingGrowthTable          = address($888297) ; 10 bytes per ring
  aLMStatGainGrowths          = $7EA69B
  aLMActionStructUnit1        = $A4EF ; short pointer, as the game passes it

  LMConfirmContinue           = address($81F256) ; draws + reads the prompt
  LMConfirmOriginalInputs     = address($81F26C) ; after lda $E8 / bit #JOY_Left
  LMConfirmOriginalB          = address($81F297)
  LMConfirmOriginalA          = address($81F2A5)
  LMConfirmAfterClear         = address($81F2C1) ; compact, write back, redraw
  LMRtsInBank81               = address($81F27D)

  LMDeployOriginal            = address($85FD49)
  LMDeployRefuse              = address($85FD9F)

  ; Fixed-location hooks

  ; rsPrepItemsBuildDiscardConfirmMenu: jsl rlPrepItemsClearDiscardDescription

  * := $00F1E2
  .logical mapped($00F1E2)
    jsl rlLMPrepBuildConfirm
  .endlogical

  ; rsPrepItemsHandleDiscardConfirmInputs: lda wJoy1New / bit #JOY_Left

  * := $00F267
  .logical mapped($00F267)
    jml rlLMPrepConfirmInputs
    nop
  .endlogical

  ; rlPrepItemsDrawDiscardCursor: ldx cursor / lda _CursorxTable,x

  * := $00F307
  .logical mapped($00F307)
    jsl rlLMPrepConfirmCursorX
    nop
    nop
    nop
  .endlogical

  ; Deploy screen A press: lda UnitState / bit #$4000

  * := $02FD43
  .logical mapped($02FD43)
    jml rlLMPrepDeployCheck
    nop
    nop
  .endlogical

  ; Phase start (game state 2): stz $0E2D / jsl RunChapterTurnEvents / jmp next

  * := $0181B8
  .logical mapped($0181B8)
    jml rlLMPhaseStartHook
    .fill mapped($0181BF) - *, $EA
  .endlogical

  ; Preparations menu opening (player phase substate $19):
  ; phx / start the menu proc / plx / jmp $8529

  * := $018DD9
  .logical mapped($018DD9)
    jml rlLMPrepMenuOpenHook
  .endlogical

  ; The Items menu's "Discard" command is renamed "Use". Its
  ; label is a fixed tilemap of menu font tiles; point it at
  ; the font's "Us" and "e" tiles instead (the same ones the
  ; description line uses).

  * := $3A7522 ; top row
  .word $220A, $21DF, $21DF, $21DF

  * := $3A7562 ; bottom row
  .word $21A5, $2189, $21DF, $21DF

  ; Items menu description for Discard

  * := $00F3A1
  .word <>menutextLMUseOrDiscardItems

  ; Bank $81 free space (the description pointer is bank-relative)

  * := $008C00
  .logical mapped($008C00)

    menutextLMUseOrDiscardItems ; "Use and discard items"
      .word $013E, $0005, $006C, $0010, $016D, $000E, $000F, $0010, $0051, $013B, $0159, 0

    .cerror * > mapped($008C80), "Prep item use text overflows"

  .endlogical

  .section GBABattleForecastWindowSection

    menutextLMUseOrDiscardItem ; "Use or discard this item?"
      .word $013E, $0005, $0008, $01D0, $009F, $0135, $00D9, $01B1, $0087, $001F, $0051, $013B, $0161, 0

    menutextLMUseDiscardNo ; "Use  Discard  No": Use, then Discard 3 tiles in, No 8 tiles in
      .word $013E, $0005, $4081, $000D, $000E, $000F, $0010, $4081, $001A, $0054, 0

    menutextLMCancelClassChange ; "Cancel class change?"
      .word $0042, $0138, $003B, $01BA, $00F0, $0105, $01BA, $0077, $0144, $01B6, 0

    menutextLMClassChangeLine1 ; "Class change after"
      .word $001D, $001E, $001F, $00BE, $006C, $00FB, $015E, $01E8, $003C, 0

    menutextLMClassChangeLine2 ; "leaving this menu"
      .word $0012, $003A, $0047, $0053, $005A, $009F, $015B, $001C, $015C, 0

    menutextLMOriginalYesNo = address($81F234) ; "Yes       No"

    rlLMPrepBuildConfirm

      .al
      .xl
      .autsiz
      .databank $7E

      ; Replaces the first call of the discard prompt. Usable item:
      ; draw our prompt and continue the menu at the input step.
      ; Anything else: return and let the original prompt draw.

      lda #0
      sta @l LMPrepUseMode

      jsl rlLMClearDiscardDescription

      jsr rsLMPrepIsPendingSeal
      bcc +

        jmp _CancelPrompt

      +
      jsr rsLMPrepCanUseSelected
      bcs +

        rtl

      +
      lda #1
      sta @l LMPrepUseMode

      lda #$2180
      sta $7E0DE7
      lda #$C0F6
      sta $7E0DDE
      lda #$83C0
      sta $7E0DDF

      ldx #2 | (10 << 8)
      lda #(`menutextLMUseOrDiscardItem) << 8
      sta lR18+size(byte)
      lda #<>menutextLMUseOrDiscardItem
      sta lR18
      jsl rlLMDrawMenuText

      ldx #4 | (13 << 8)
      lda #(`menutextLMUseDiscardNo) << 8
      sta lR18+size(byte)
      lda #<>menutextLMUseDiscardNo
      sta lR18
      jsl rlLMDrawMenuText

      jsl rlLMEnableBG3Sync

      ; Cursor starts on "No", like the original prompt.

      lda #4
      sta LMPrepConfirmCursor

      lda #LMActionConfirm
      sta LMPrepItemsAction

      bra _Continue

      _CancelPrompt

        ; A Master Seal whose owner is already set to promote:
        ; offer to cancel it instead.

        lda #2
        sta @l LMPrepUseMode

        jsr rsLMPrepSetTextInfo

        ldx #2 | (10 << 8)
        lda #(`menutextLMCancelClassChange) << 8
        sta lR18+size(byte)
        lda #<>menutextLMCancelClassChange
        sta lR18
        jsl rlLMDrawMenuText

        ldx #4 | (13 << 8)
        lda #(`menutextLMOriginalYesNo) << 8
        sta lR18+size(byte)
        lda #<>menutextLMOriginalYesNo
        sta lR18
        jsl rlLMDrawMenuText

        jsl rlLMEnableBG3Sync

        lda #2
        sta LMPrepConfirmCursor

        lda #LMActionConfirm
        sta LMPrepItemsAction

      _Continue

      ; Drop our return address and carry on where the
      ; original prompt setup ends.

      sep #$20
      pla
      pla
      pla
      rep #$20

      jml LMConfirmContinue

      .databank 0

    rsLMPrepSetTextInfo

      .al
      .xl
      .autsiz
      .databank $7E

      lda #$2180
      sta $7E0DE7
      lda #$C0F6
      sta $7E0DDE
      lda #$83C0
      sta $7E0DDF
      rts

      .databank 0

    rsLMPrepIsPendingSeal

      .al
      .xl
      .autsiz
      .databank $7E

      ; Carry set if the item under the cursor is a Master Seal
      ; and its owner is already waiting to promote.

      ldx LMPrepDiscardIndex
      lda LMPrepSelectedItems,x
      and #$00FF
      cmp #LMKnightCrest
      bne +

        jsr rsLMPrepSelectedSlot
        jsr rsLMPrepFindPromo
        rts

      +
      clc
      rts

      .databank 0

    rsLMPrepCanUseSelected

      .al
      .xl
      .autsiz
      .databank $7E

      ; Carry set if the item under the discard cursor is a ring
      ; and its owner is deployed.

      lda LMPrepSelectedState
      bit #UnitStateMoved ; deployed, in preps
      beq _No

      ldx LMPrepDiscardIndex
      lda LMPrepSelectedItems,x
      and #$00FF
      cmp #LMKnightCrest
      beq _Crest

      cmp #LMFirstManual
      blt +

      cmp #LMLastManual + 1
      bge _No

        ; Manuals: usable unless the unit already has the skill
        ; (the map's own check).

        lda LMPrepSelectedItems,x
        jsl rlLMCopyItemDataToBuffer
        jsl rlLMCanLearnSkill
        rts

      +
      cmp #LMFirstRing
      blt _No

      cmp #LMLastRing + 1
      bge _No

      sec
      rts

      _Crest

        ; Same check the map uses (level 10+, has a promotion).

        jsl rlLMCanPromote
        rts

      _No
      clc
      rts

      .databank 0

    rlLMPrepConfirmInputs

      .al
      .xl
      .autsiz
      .databank $7E

      lda @l LMPrepUseMode
      bne +

        lda LMJoy1New
        bit #JOY_Left
        jml LMConfirmOriginalInputs

      +
      cmp #3
      bne _NotMessage

        ; Message mode: any A/B closes it.

        lda LMJoy1New
        bit #JOY_A | JOY_B
        beq _MessageWait

          lda #0
          sta @l LMPrepUseMode
          lda #LMActionDiscard
          sta LMPrepItemsAction
          lda #$0021
          jsl rlLMPlaySound

        _MessageWait
        jml LMRtsInBank81

      _NotMessage
      cmp #4
      bne _NotUseMessage

        ; Use message: A/B closes it. Same as after discarding:
        ; compact the inventory, write the unit back, redraw and
        ; fix the cursor.

        lda LMJoy1New
        bit #JOY_A | JOY_B
        beq _MessageWait

          lda #0
          sta @l LMPrepUseMode
          lda #LMActionDiscard
          sta LMPrepItemsAction
          ldx LMPrepDiscardIndex
          jml LMConfirmAfterClear

      _NotUseMessage
      cmp #2
      bne _ThreeChoice

        jmp _CancelInputs

      _ThreeChoice
      lda LMJoy1New
      bit #JOY_Left
      bne _Left

      bit #JOY_Right
      bne _Right

      bit #JOY_B
      bne _B

      bit #JOY_A
      bne _A

      jml LMRtsInBank81

      _Left

        lda LMPrepConfirmCursor
        beq +

          dec a
          dec a
          sta LMPrepConfirmCursor
          lda #$0009
          jsl rlLMPlaySound

        +
        jml LMRtsInBank81

      _Right

        lda LMPrepConfirmCursor
        cmp #4
        beq +

          inc a
          inc a
          sta LMPrepConfirmCursor
          lda #$0009
          jsl rlLMPlaySound

        +
        jml LMRtsInBank81

      _B

        lda #0
        sta @l LMPrepUseMode
        jml LMConfirmOriginalB

      _A

        lda #0
        sta @l LMPrepUseMode

        lda LMPrepConfirmCursor
        beq _Use

        cmp #2
        bne _Cancel

          ; Discard: the original A handler with "Yes" selected.

          stz LMPrepConfirmCursor
          jml LMConfirmOriginalA

        _Cancel

          ; No: the original A handler with "No" selected.

          lda #2
          sta LMPrepConfirmCursor
          jml LMConfirmOriginalA

        _Use

          ldx LMPrepDiscardIndex
          lda LMPrepSelectedItems,x
          and #$00FF
          cmp #LMKnightCrest
          bne _Ring

            ; Master Seal: the unit promotes, with the real
            ; scene, when the chapter starts. Keep the seal
            ; until then and say so.

            jsr rsLMPrepAddPromo
            jsr rsLMPrepLockSelected

            lda #$000D
            jsl rlLMPlaySound

            jsl rlLMClearDiscardDescription
            jsr rsLMPrepSetTextInfo

            ldx #2 | (10 << 8)
            lda #(`menutextLMClassChangeLine1) << 8
            sta lR18+size(byte)
            lda #<>menutextLMClassChangeLine1
            sta lR18
            jsl rlLMDrawMenuText

            ldx #2 | (13 << 8)
            lda #(`menutextLMClassChangeLine2) << 8
            sta lR18+size(byte)
            lda #<>menutextLMClassChangeLine2
            sta lR18
            jsl rlLMDrawMenuText

            jsl rlLMEnableBG3Sync

            lda #3
            sta @l LMPrepUseMode
            lda #LMActionConfirm
            sta LMPrepItemsAction
            jml LMRtsInBank81

          _Ring

          sta @l LMPrepMsgItem

          cmp #LMFirstManual
          blt _NotManual

            jsl rlLMPrepUseManual

            ; The map's "skill learned" jingle

            lda #$1528
            jsl rlLMPlayExtendedSound
            bra _UseMessage

          _NotManual

          jsl rlLMPrepUseRing
          bcs +

            ; Stat already at its cap: like the map, the ring
            ; can't be used. Back to the item list.

            lda #$0022
            jsl rlLMPlaySound
            lda #2
            sta LMPrepConfirmCursor
            jml LMConfirmOriginalA

          +

          ; The map's stat-up jingle

          lda #$0023
          jsl rlLMPlaySound

          _UseMessage

          ; Say what happened ("Strength  +3", "Vantage  learned")
          ; until A or B, then finish like a discard.

          jsr rsLMPrepBuildUseMessage

          jsl rlLMClearDiscardDescription
          jsr rsLMPrepSetTextInfo

          ldx #2 | (10 << 8)
          lda #(`LMPrepMsgBuffer) << 8
          sta lR18+size(byte)
          lda #<>LMPrepMsgBuffer
          sta lR18
          jsl rlLMDrawMenuText

          jsl rlLMEnableBG3Sync

          lda #4
          sta @l LMPrepUseMode
          lda #LMActionConfirm
          sta LMPrepItemsAction
          jml LMRtsInBank81

      _CancelInputs

        lda LMJoy1New
        bit #JOY_Left
        beq +

          lda #0
          sta LMPrepConfirmCursor
          lda #$0009
          jsl rlLMPlaySound
          jml LMRtsInBank81

        +
        bit #JOY_Right
        beq +

          lda #2
          sta LMPrepConfirmCursor
          lda #$0009
          jsl rlLMPlaySound
          jml LMRtsInBank81

        +
        bit #JOY_B
        beq +

          lda #0
          sta @l LMPrepUseMode
          jml LMConfirmOriginalB

        +
        bit #JOY_A
        beq +

          lda #0
          sta @l LMPrepUseMode

          lda LMPrepConfirmCursor
          bne _KeepPromo

            jsr rsLMPrepSelectedSlot
            jsr rsLMPrepRemovePromo

            lda #$000D
            jsl rlLMPlaySound

          _KeepPromo
          lda #LMActionDiscard
          sta LMPrepItemsAction

        +
        jml LMRtsInBank81

      .databank 0

    rlLMPrepConfirmCursorX

      .al
      .xl
      .autsiz
      .databank $7E

      ldx LMPrepConfirmCursor
      lda @l LMPrepUseMode
      cmp #1
      beq +

        cmp #3
        bge _Hidden

        lda @l _Two,x
        rtl

      +
      lda @l _Three,x
      rtl

      _Hidden
      lda #256
      rtl

      _Two   .word 16, 56
      _Three .word 16, 40, 80

      .databank 0

    rlLMPrepUseRing

      .al
      .xl
      .autsiz
      .databank $7E

      ; Applies the ring under the discard cursor to the selected
      ; unit, the same way the map's Item > Use does it
      ; (83/E033, 83/905C, 88/8297 growths, 83/DFD6 caps), then
      ; clears the item and locks the unit's deployment.

      ldx LMPrepDiscardIndex
      lda LMPrepSelectedItems,x
      jsl rlLMCopyItemDataToBuffer

      ldx #aLMActionStructUnit1
      jsl rlLMClearStatGains

      lda #<>LMPrepSelectedUnit
      sta wR0
      lda #aLMActionStructUnit1
      sta wR1
      jsl rlLMCopyExpandedBuffer

      sep #$20
      lda LMPrepSelectedUnit + structCharacterDataRAM.MaxHP
      sta $7EA54C
      rep #$20

      lda LMItemUseEffect
      sec
      sbc #2
      and #$00FF
      lsr a
      sta wR0
      asl a
      asl a
      clc
      adc wR0
      asl a
      tax

      ldy #0

      -
        lda aLMRingGrowthTable,x
        and #$00FF
        asl a
        asl a
        sta aLMStatGainGrowths,y
        inc x
        inc y
        inc y
        cpy #9 * size(word)
        bne -

      ldx #aLMActionStructUnit1
      jsl rlLMCapStatGains

      ; Nothing to gain (stat at its cap): don't use it.

      sep #$20
      lda $7EA553
      ora $7EA554
      ora $7EA555
      ora $7EA556
      ora $7EA557
      ora $7EA558
      ora $7EA559
      ora $7EA55A
      ora $7EA55B
      rep #$20
      and #$00FF
      bne +

        clc
        rtl

      +

      ; Add the capped gains (action struct +$64..) to the unit.

      _Gains  := [(structCharacterDataRAM.CurrentHP, $A553)]
      _Gains ..= [(structCharacterDataRAM.MaxHP, $A553)]
      _Gains ..= [(structCharacterDataRAM.Strength, $A554)]
      _Gains ..= [(structCharacterDataRAM.Magic, $A555)]
      _Gains ..= [(structCharacterDataRAM.Skill, $A556)]
      _Gains ..= [(structCharacterDataRAM.Speed, $A557)]
      _Gains ..= [(structCharacterDataRAM.Defense, $A558)]
      _Gains ..= [(structCharacterDataRAM.Constitution, $A559)]
      _Gains ..= [(structCharacterDataRAM.Luck, $A55A)]
      _Gains ..= [(structCharacterDataRAM.Movement, $A55B)]

      sep #$20

      .for _Stat, _Gain in _Gains
        lda LMPrepSelectedUnit + _Stat
        clc
        adc $7E0000 + _Gain
        sta LMPrepSelectedUnit + _Stat
      .endfor

      stz $7EA568
      stz $7EA5BB
      stz $7EA5BC

      rep #$30

      ; Use up the ring

      ldx LMPrepDiscardIndex
      lda #0
      sta LMPrepSelectedItems,x

      jsr rsLMPrepLockSelected

      ; Redraw HP in the unit window (Life Ring)

      lda #$22A0
      sta $7E0DE7

      lda LMPrepSelectedUnit + structCharacterDataRAM.CurrentHP
      and #$00FF
      sta lR18
      stz lR18+size(byte)
      ldx #5 | (7 << 8)
      jsl rlLMDrawNumber

      lda LMPrepSelectedUnit + structCharacterDataRAM.MaxHP
      and #$00FF
      sta lR18
      stz lR18+size(byte)
      ldx #8 | (7 << 8)
      jsl rlLMDrawNumber

      lda #$2180
      sta $7E0DE7

      jsl rlLMEnableBG3Sync

      sec
      rtl

      .databank 0

    rsLMPrepBuildUseMessage

      .al
      .xl
      .autsiz
      .databank $7E

      ; Builds the use message in LMPrepMsgBuffer (bank $7E, the
      ; data bank here; sources are read with long,x).

      lda @l LMPrepMsgItem
      and #$00FF
      cmp #LMFirstManual
      blt _RingMessage

        ; Manual: the skill name the map's popup uses, without
        ; its leading space (the popup puts the skill icon
        ; there), then " learned".

        sec
        sbc #LMFirstManual
        sta wR0
        asl a
        clc
        adc wR0
        tax
        lda @l aLMPopUpSkillNames,x
        sta lR18
        lda @l aLMPopUpSkillNames+1,x
        sta lR18+size(byte)

        ldy #size(word)

        -
          lda [lR18],y
          beq +

          sta LMPrepMsgBuffer-size(word),y
          inc y
          inc y
          cpy #12 * size(word)
          bne -

        +
        ldx #0

        -
          lda @l _Learned,x
          sta LMPrepMsgBuffer-size(word),y
          inc x
          inc x
          inc y
          inc y
          cpx #5 * size(word)
          bne -

        rts

      _RingMessage

        ; Ring: the stat that went up and by how much.

        ldx #0

        -
          lda $7EA553,x
          and #$00FF
          bne +

          inc x
          cpx #9
          bne -

          ldx #0
          lda #0

        +
        sta wR0

        txa
        asl a
        tax
        lda @l _StatNames,x
        tax

        ldy #0

        -
          lda @l (`_StatNames) << 16,x
          beq +

          sta LMPrepMsgBuffer,y
          inc x
          inc x
          inc y
          inc y
          bra -

        +
        lda #$2B83 ; "+"
        sta LMPrepMsgBuffer,y
        lda wR0
        xba
        clc
        adc #$4F82 ; digit
        sta LMPrepMsgBuffer+size(word),y
        lda #0
        sta LMPrepMsgBuffer+(2*size(word)),y
        rts

      _Learned .word $01D8, $0136, $0049, $008D, 0 ; " learned"

      _StatNames
        .word <>_HP, <>_Str, <>_Mag, <>_Skl, <>_Spd, <>_Def, <>_Con, <>_Lck, <>_Mov

      ; Spelled like the rings' descriptions, then a space
      _HP  .word $6782, $6F82, $4081, 0                         ; "HP  "
      _Str .word $0017, $00CC, $0144, $005A, $4081, 0           ; "Strength  "
      _Mag .word $002C, $002D, $00CD, $4081, 0                  ; "Magic  "
      _Skl .word $002E, $003D, $002F, 0                         ; "Skill "
      _Spd .word $0030, $0091, $0010, 0                         ; "Speed "
      _Def .word $0033, $00D2, $004D, $0005, 0                  ; "Defense "
      _Con .word $0035, $004D, $005F, $0190, $005F, $007B, $4081, 0 ; "Constitution  "
      _Lck .word $00E3, $0026, $4081, 0                         ; "Luck  "
      _Mov .word $002C, $0037, $013B, $001C, $0023, $4081, 0    ; "Movement  "

      .cerror (`_StatNames) != (`_Mov), "Stat names must share a bank"

      .databank 0

    rlLMPrepUseManual

      .al
      .xl
      .autsiz
      .databank $7E

      ; Teaches the manual's skill like the map does (OR its bits
      ; into the unit's skills), then clears the item.

      ldx LMPrepDiscardIndex
      lda LMPrepSelectedItems,x
      jsl rlLMCopyItemDataToBuffer

      sep #$20
      ldx #0

      -
        lda aLMManualSkillTable,x
        cmp LMItemUseEffect
        beq +

        inc x
        inc x
        inc x
        inc x
        cpx #10 * 4
        bne -

        ; Not in the table (shouldn't happen): change nothing.

        rep #$30
        bra _Clear

      +
      rep #$30

      lda LMPrepSelectedUnit + structCharacterDataRAM.Skills1
      ora aLMManualSkillTable+1,x
      sta LMPrepSelectedUnit + structCharacterDataRAM.Skills1

      lda LMPrepSelectedUnit + structCharacterDataRAM.Skills2
      ora aLMManualSkillTable+2,x
      sta LMPrepSelectedUnit + structCharacterDataRAM.Skills2

      _Clear

      ldx LMPrepDiscardIndex
      lda #0
      sta LMPrepSelectedItems,x

      jsr rsLMPrepLockSelected

      ldx LMPrepDiscardIndex
      rtl

      .databank 0


    ; Pending promotions: deployment numbers of units that used
    ; a Master Seal in prep. They promote on turn 1.

    rsLMPrepFindPromo

      .al
      .xl
      .autsiz
      .databank ?

      ; A: deployment number. Carry set if pending for this
      ; chapter; X = its index.

      and #$00FF
      sta @l LMPrepLockSearch

      jsr rsLMPrepCurrentLockTag
      cmp @l LMPrepLockTag
      bne _No

      ldx #0

      -
        txa
        cmp @l LMPrepPromoCount
        bge _No

        lda @l LMPrepPromos,x
        and #$00FF
        cmp @l LMPrepLockSearch
        beq _Yes

        inc x
        bra -

      _Yes
      sec
      rts

      _No
      clc
      rts

      .databank 0

    rsLMPrepAddPromo

      .al
      .xl
      .autsiz
      .databank $7E

      ; Adds the selected unit (makes sure the lists belong to
      ; this chapter first).

      jsr rsLMPrepCurrentLockTag
      cmp @l LMPrepLockTag
      beq +

        sta @l LMPrepLockTag
        lda #0
        sta @l LMPrepLockCount
        sta @l LMPrepPromoCount

      +
      jsr rsLMPrepSelectedSlot
      jsr rsLMPrepFindPromo
      bcs _Done

      lda @l LMPrepPromoCount
      cmp #LMPrepPromoMax
      bge _Done

      tax
      jsr rsLMPrepSelectedSlot
      sep #$20
      sta @l LMPrepPromos,x
      rep #$20
      inc x
      txa
      sta @l LMPrepPromoCount

      _Done
      rts

      .databank 0

    rsLMPrepSelectedSlot

      .al
      .xl
      .autsiz
      .databank ?

      ; A = deployment number of the selected unit, worked out from
      ; its struct pointer (the buffer's own number is stale in prep).

      phx
      lda @l LMPrepSelectedPointer
      sec
      sbc #$5298
      ldx #1

      -
        cmp #$41
        blt +

        sbc #$41
        inc x
        bra -

      +
      txa
      plx
      rts

      .databank 0

    rsLMPrepRemovePromo

      .al
      .xl
      .autsiz
      .databank ?

      ; A: deployment number to take out of the list.

      jsr rsLMPrepFindPromo
      bcc _Done

      ; Move the last entry into its place

      lda @l LMPrepPromoCount
      dec a
      sta @l LMPrepPromoCount
      phx
      tax
      sep #$20
      lda @l LMPrepPromos,x
      plx
      sta @l LMPrepPromos,x
      rep #$20
      bra _End

      _Done
      _End
      rts

      .databank 0

    ; Turn 1: run our event before the chapter's turn events.
    ; Replaces stz $0E2D / jsl rlEventEngineRunChapterTurnEvents /
    ; jmp to the next game state in the phase-start state.

    rlLMPhaseStartHook

      .al
      .xl
      .autsiz
      .databank ?

      jsr rsLMPromotionsPending
      bcc _Original

        ; Wait for anything already running, then start ours.
        ; The state stays the same, so this comes back here
        ; every frame until the list is empty.

        lda @l LMEventEngineStatus
        bne _Wait

          lda #<>aLMPromotionEventDefinitions
          sta lR18
          lda #>`aLMPromotionEventDefinitions
          sta lR18+size(byte)
          jsl rlLMRunEventDefinitions

        _Wait
        jml LMRtsInBank83

      _Original
      lda #0
      sta @l $7E0E2D
      jsl rlLMRunChapterTurnEvents
      jml LMNextGameState

      .databank 0

    ; Back on the preparations menu (from Items, Deploy, ...):
    ; play the promotion scene for every marked unit first, on
    ; the map behind the menu, then open the menu as usual.
    ; The units are promoted right then, so saving keeps it.

    rlLMPrepMenuOpenHook

      .al
      .xl
      .autsiz
      .databank ?

      lda @l LMPrepPromoCount
      beq _Original

      jsr rsLMPrepCurrentLockTag
      cmp @l LMPrepLockTag
      bne _Original

        lda @l LMEventEngineStatus
        bne _Wait

          ; The scene ends by clearing the map music: keep it.

          lda @l $7E0E2D
          ora #$8000 ; never 0, even if no map music is set yet
          sta @l LMPrepSavedMusic

          lda #<>aLMPromotionEventDefinitions
          sta lR18
          lda #>`aLMPromotionEventDefinitions
          sta lR18+size(byte)
          jsl rlLMRunEventDefinitions

        _Wait
        jml LMRtsInBank83

      _Original
      phx
      lda #>`LMPrepMenuProc
      sta lR44+size(byte)
      lda #<>LMPrepMenuProc
      sta lR44
      jsl rlLMProcEngineCreateProc
      plx
      jml LMPlayerPhaseNext

      .databank 0

    rsLMPromotionsPending

      .al
      .xl
      .autsiz
      .databank ?

      lda @l LMPrepPromoCount
      beq _No

      jsr rsLMPrepCurrentLockTag
      cmp @l LMPrepLockTag
      bne _No

      lda @l LMCurrentPhase
      and #$00FF
      bne _No

      lda @l LMCurrentTurn
      cmp #1
      bne _No

      sec
      rts

      _No
      clc
      rts

      .databank 0

    rlASMCLMNextPromotion

      .al
      .xl
      .autsiz
      .databank ?

      ; Takes the next unit off the list. If it's alive, on the
      ; map, still holds a Master Seal and can still promote, the
      ; seal is used up, the unit goes into the selected buffer
      ; (which rlASMCPromoteUnit promotes) and the truth flag is
      ; set. With no unit left, the truth flag is cleared.

      php
      phb
      sep #$20
      lda #$7E
      pha
      plb
      rep #$30

      .databank $7E

      _Next
      lda @l LMPrepPromoCount
      bne +

        stz LMEventEngineTruthFlag
        bra _Return

      +
      dec a
      sta @l LMPrepPromoCount
      tax
      lda @l LMPrepPromos,x
      and #$00FF
      sta wR0
      lda #<>LMPrepSelectedUnit
      sta wR1
      jsl rlLMCopyCharacterToBuffer

      lda LMPrepSelectedState
      bit #UnitStateDead | UnitStateCaptured | UnitStateRescued
      bne _Next

      ; In the preparations every deployed unit has the deployed
      ; bit, and in fog chapters also the hidden bit (the map is
      ; dark until the chapter starts). On the map, hidden units
      ; are skipped.

      ldx LMCurrentPhase
      cpx #$0080
      bne +

        bit #UnitStateMoved
        beq _Next
        bra ++

      +
      bit #UnitStateHidden
      bne _Next

      +

      ; Find the seal

      ldx #0

      -
        lda LMPrepSelectedItems,x
        and #$00FF
        cmp #LMKnightCrest
        beq +

        inc x
        inc x
        cpx #7 * size(word)
        bne -

        bra _Next

      +
      phx
      jsl rlLMCanPromote
      plx
      bcc _Next

      lda #0
      sta LMPrepSelectedItems,x

      lda #<>LMPrepSelectedUnit
      sta wR1
      jsl rlLMCompactInventory

      lda #<>LMPrepSelectedUnit
      sta wR1
      jsl rlLMCopyCharacterFromBuffer

      lda LMPrepSelectedUnit
      sta LMEventEngineCharacterTarget
      jsl rlLMGetPromotionClass
      sta LMEventEngineParameter1

      lda #1
      sta LMEventEngineTruthFlag

      _Return
      plb
      plp
      clc
      rtl

      .databank 0

    rlASMCLMFinishPromotion

      .al
      .xl
      .autsiz
      .databank ?

      ; On the map the promoted unit is written back when its
      ; action ends. The scene leaves the player phase's substate
      ; and the action type set for that, which on turn 1 would
      ; open a "Wait" menu, so write the unit back here and clear
      ; them instead.

      php
      rep #$30

      lda #<>LMPrepSelectedUnit
      sta wR1
      jsl rlLMCopyCharacterFromBuffer

      ; Substate 0 also sets the menu window gradient up again
      ; (the scene clears it) and, in the preparations, goes on
      ; to open the preparations menu.

      lda #0
      sta @l $7EA67F
      sta @l $7E0E25

      ; The scene also reuses the RAM of the preparations' unit
      ; list, which is otherwise only built when they open.

      lda @l $7E0E23
      and #$00FF
      cmp #5
      bne +

        jsl rlLMPrepBuildUnitList

      +

      plp
      clc
      rtl

      .databank 0

    rlASMCLMWaitTeardown

      .al
      .xl
      .autsiz
      .databank ?

      ; Waits 60 real frames (also while events are being
      ; skipped, which would make PAUSE instant).

      php
      rep #$30

      lda @l LMPrepWaitActive
      bne +

        lda #1
        sta @l LMPrepWaitActive
        lda @l $0000DB
        sta @l LMPrepWaitStart
        bra _Again

      +
      lda @l $0000DB
      sec
      sbc @l LMPrepWaitStart
      cmp #60
      blt _Again

        lda #0
        sta @l LMPrepWaitActive
        plp
        clc
        rtl

      _Again
      plp
      sec
      rtl

      .databank 0

    rlASMCLMEndPromotions

      .al
      .xl
      .autsiz
      .databank ?

      php
      rep #$30
      lda #0
      sta @l $7E0E25

      ; Preparations: the scene cleared the chapter's map music
      ; (put it back) and left the preparations theme stopped
      ; (request it again, the song the game starts them with).

      lda @l LMPrepSavedMusic
      beq _NoMusic

        lda @l $7E0E2D
        bne _MusicKept ; no scene played (the seal was traded away)

          lda @l LMPrepSavedMusic
          and #$7FFF
          sta @l $7E0E2D
          lda #LMPrepMusic
          sta @l $7E04BA

        _MusicKept
        lda #0
        sta @l LMPrepSavedMusic

      _NoMusic
      plp
      clc
      rtl

      .databank 0

    aLMPromotionEventDefinitions
      EVENT FlagAlwaysZero, eventLMPendingPromotions
        ; The engine needs at least one condition. This one is
        ; always true (wCurrentPhase isn't the player's in preps).
        CMP_WORD aLMAlwaysZero, 0
      END_DEFINITION
      END_DEFINITION_ARRAY

    aLMAlwaysZero
      .word 0

    eventLMPendingPromotions

      _Loop
        CALL_ASM_LOOP rlASMCLMNextPromotion
        JUMP_FALSE _End

        CALL_ASM_LOOP rlLMASMCPromoteUnit

        HALT_UNTIL_WORD wMapBattleFlag, $0000 ; not skippable: Start must not end the event before the scene does

        STORE_WORD $001791, $FFFF

        CALL_ASM_LOOP rlASMCLMFinishPromotion

        YIELD
        JUMP _Loop

      _End
        ; The scene's own teardown keeps running (and changing the
        ; music) for a while after the scene ends: let it finish
        ; before the preparations theme is requested again.
        CALL_ASM_LOOP rlASMCLMWaitTeardown

        ; Also when no scene played (the seal was traded away):
        ; starting the event cleared the menu window gradient.
        CALL_ASM_LOOP rlASMCLMEndPromotions
      END1

    rsLMPrepCurrentLockTag

      .al
      .autsiz
      .databank $7E

      lda LMCurrentChapter
      and #$00FF
      ora #$4C00
      rts

      .databank 0

    rsLMPrepLockSelected

      .al
      .xl
      .autsiz
      .databank $7E

      ; Adds the selected unit's struct pointer to the lock list.
      ; A list from another chapter is thrown away first.

      jsr rsLMPrepCurrentLockTag
      cmp @l LMPrepLockTag
      beq +

        sta @l LMPrepLockTag
        lda #0
        sta @l LMPrepLockCount
        sta @l LMPrepPromoCount

      +
      lda LMPrepSelectedPointer
      jsr rsLMPrepFindLock
      bcs _Done

      lda @l LMPrepLockCount
      cmp #LMPrepLockMax * size(word)
      bge _Done

      tax
      lda LMPrepSelectedPointer
      sta @l LMPrepLocks,x
      inc x
      inc x
      txa
      sta @l LMPrepLockCount

      _Done
      rts

      .databank 0

    rsLMPrepFindLock

      .al
      .xl
      .autsiz
      .databank ?

      ; A: unit struct pointer. Carry set if it's in the list for
      ; the current chapter.

      sta @l LMPrepLockSearch

      jsr rsLMPrepCurrentLockTag
      cmp @l LMPrepLockTag
      bne _No

      ldx #0

      -
        txa
        cmp @l LMPrepLockCount
        bge _No

        lda @l LMPrepLocks,x
        cmp @l LMPrepLockSearch
        beq _Yes

        inc x
        inc x
        bra -

      _Yes
      sec
      rts

      _No
      clc
      rts

      .databank 0

    rlLMPrepDeployCheck

      .al
      .xl
      .autsiz
      .databank $7E

      ; X: unit struct. A deployed unit that used an item in prep
      ; can't be taken out.

      lda @l $7E0000 + structCharacterDataRAM.UnitState,x
      bit #UnitStateMoved
      beq _Original

      phx
      txa
      jsr rsLMPrepFindLock
      plx
      bcc _Original

        jml LMDeployRefuse

      _Original
      lda @l $7E0000 + structCharacterDataRAM.UnitState,x
      bit #$4000
      jml LMDeployOriginal

      .databank 0

  .endsection GBABattleForecastWindowSection

.endif ; GUARD_LM_PREP_ITEM_USE
