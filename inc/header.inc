ROM_HEADER:   MACRO
 NINTENDO_LOGO

 DB "PATRICK",0,0,0,0,0,0,0,0 ; Cart name - 15bytes
 DB 0                         ; $143
 DB 0,0                       ; $144 - Licensee code (not important)
 DB 0                         ; $146 - SGB Support indicator
 DB \1                        ; $147 - Cart type
 DB \2                        ; $148 - ROM Size
 DB \3                        ; $149 - RAM Size
 DB 1                         ; $14a - Destination code
 DB $33                       ; $14b - Old licensee code
 DB 0                         ; $14c - Mask ROM version
 DB 0                         ; $14d - Complement check (important)
 DW 0                         ; $14e - Checksum (not important)

        ENDM
