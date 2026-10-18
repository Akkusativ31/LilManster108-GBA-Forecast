; Lil' Manster: where the forecast and hover window options live.
; See OptionsMenu.asm for the menu rows that set them.

GUARD_LM_OPTIONS_H :?= false
.if (!GUARD_LM_OPTIONS_H)
  GUARD_LM_OPTIONS_H := true

  LM_OPTIONS_WORD       = $7E4E5C ; aOptions.wTextSpeed
  LM_OPTIONS_TEMP       = $7EA985 ; menu's working copy of rows 12-15

  LM_OPTION_FORECAST    = $000F
  LM_OPTION_ARROWS      = $00F0
  LM_OPTION_LEVEL       = $0F00
  LM_OPTION_PREP        = $F000

  LM_PREP_OFF           = 1 << 12
  LM_PREP_NO_PENALTY    = 2 << 12

  LM_FORECAST_STILL     = 1
  LM_FORECAST_CLASSIC   = 2
  LM_ARROWS_THRACIA     = 1 << 4
  LM_ARROWS_OFF         = 2 << 4
  LM_LEVEL_OFF          = 1 << 8

.endif ; GUARD_LM_OPTIONS_H
