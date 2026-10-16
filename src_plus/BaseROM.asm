
.weak
  WARNINGS :?= "None"
.endweak

GUARD_BASEROM :?= false
.if (GUARD_BASEROM && (WARNINGS == "Strict"))

  .warn "File included more than once."

.elsif (!GUARD_BASEROM)
  GUARD_BASEROM := true

  ; Fill the base ROM in parts to prevent
  ; pc wrap warnings.

  ; Lil' Manster is a 6 MB ExLoROM, so copy the whole
  ; file instead of only the first 4 MB.

  BASEROM_SIZE := len(binary(BASEROM))

  * := $000000

  .for bank in range($000000, BASEROM_SIZE, $8000)
    * := bank
    .binary BASEROM, bank, $8000
  .next

.endif ; GUARD_BASEROM
