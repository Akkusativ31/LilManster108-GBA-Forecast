; Lil' Manster: Animations: Player.
;
; A fourth choice on the Animations row: battle animations play
; on the player phase, but battles on the enemy (and other)
; phases use the map battle instead. Battles against bosses and
; other named enemies (ones with a portrait) still animate.
;
; The game checks the setting in two places (Lil' Manster's own
; code): both now go through rlLMAnimationSetting, which turns
; Player (3) into On (0) or Off (1) for the battle at hand.

GUARD_LM_ENEMY_PHASE_ANIMS :?= false
.if (!GUARD_LM_ENEMY_PHASE_ANIMS)
  GUARD_LM_ENEMY_PHASE_ANIMS := true

  LMAnimationsPlayer = 3

  LMActionStruct1    = $7EA4EF ; the two combatants
  LMActionStruct2    = $7EA560
  LMCharacterTable   = $869A2D ; character data, $30 bytes each, by ID - 1
  LMCharacterPortrait = $2F    ; portrait byte, generics have none (>= $F9)

  ; lda $4E56 / and #$000F (6 bytes) -> jsl + 2 nops

  .for _Offset, _Address in [($0C6D7B, $98ED7B), ($48D687, $11D687)]
    * := _Offset
    .logical _Address
      jsl rlLMAnimationSetting
      nop
      nop
    .endlogical
  .endfor

  .section GBABattleForecastWindowSection

    rlLMAnimationSetting

      .al
      .autsiz
      .databank ?

      lda @l $7E4E56
      and #$000F
      cmp #LMAnimationsPlayer
      beq +
        rtl
      +

      php
      rep #$30
      phx

      ; Player phase: animations on.

      lda @l $7E0E15
      and #$00FF
      beq _On

      ; Other phases: on if a non-player combatant has a portrait.

      ldx #<>LMActionStruct1
      jsr _Named
      bcs _On
      ldx #<>LMActionStruct2
      jsr _Named
      bcs _On

        plx
        plp
        lda #1 ; Off
        rtl

      _On
      plx
      plp
      lda #0 ; On
      rtl

      _Named

        ; X: action struct (bank $7E). Carry set: a non-player unit
        ; with a portrait.

        lda @l $7E0000 + structExpandedCharacterDataRAM.DeploymentNumber,x
        and #$00C0
        beq _No ; player unit

        lda @l $7E0000 + structCharacterDataRAM.Character,x
        beq _No
        dec a
        asl a
        asl a
        asl a
        asl a
        pha
        asl a
        clc
        adc 1,s ; (ID - 1) * $30
        tax
        pla
        lda @l LMCharacterTable + LMCharacterPortrait,x
        and #$00FF
        cmp #$00F9
        bge _No

          sec
          rts

        _No
        clc
        rts

  .endsection GBABattleForecastWindowSection

.endif ; GUARD_LM_ENEMY_PHASE_ANIMS
