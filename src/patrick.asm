; vi:syntax=rgbds

INCLUDE "hardware.inc" ; standard hardware definitions from devrs.com

; IRQs
SECTION    "Vblank",ROM0[$0040]
;    push hl
;    ld hl, VBLANK_FLAG
;    ld [hl], 1
;    pop hl
    reti
SECTION    "LCDC",ROM0[$0048]
    reti
SECTION    "Timer_Overflow",ROM0[$0050]
    reti
SECTION    "Serial",ROM0[$0058]
    reti
SECTION    "p1thru4",ROM0[$0060]
    reti

;SECTION "Math Div 16 Ram",WRAM0
;
;_MD16temp    ds 2
;_MD16count   db

SECTION "FreeSpace",ROM0[$0068]
INCLUDE "memory.inc"

wait_vblank:
;    push hl
;    ld hl, VBLANK_FLAG
;    xor a
;.wait:
    halt
;    cp a, [hl]
;    jr z, .wait
;    ld [hl], a
;    pop hl
    ret

StartLCD:
    ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ8|LCDCF_OBJON
    ld [rLCDC], a
    ret

StopLCD:
    ld a, [rLCDC]
    rlca                ; Put the high bit of LCDC into the Carry flag
    ret nc              ; Screen is off already. Exit.
    call wait_vblank
; Turn off the LCD
    ld a, [rLCDC]
    res 7, a            ; Reset bit 7 of LCDC
    ld [rLCDC], a
    ret

SECTION    "start",ROM0[$0100]
nop
jp    begin

Nintendo_logo:
INCLUDE "header.inc"
 ROM_HEADER    CART_ROM_MBC1_RAM_BAT, CART_ROM_256K, CART_RAM_64K

SECTION "Variables", WRAM0
; TODO Reset all these variables when we play a level
; TODO Move some of these variables to HRAM?
Seed: DS 3
VBLANK_FLAG: DB
MARKER_Y: DB
MARKER_X: DB
MARKER_TILE: DB
PATRICK_Y: DB
PATRICK_X: DB
PATRICK_TILE: DB
LEVEL_NUMBER: DB
LEVEL_BCD: DB
REMAINING_TILES: DB
SCORE: DB
SCORE_BCD: DB
SCORE_WIN: DB
SCORE_WIN_BCD: DB
SCORE_LOSE: DB
SCORE_LOSE_BCD: DB

Tile_Status:
; 1 - patrick
; 2 - yellow (top)
; 3 - blue (right)
; 4 - darkblue (right/left)
; 5 - green (left)
; 6 - red (down)
; 7 - orange (top/down)
DS 28

Ball_Status:
DS 7

SECTION "Constants", ROM0, ALIGN[8]
SRAM_check EQU 42 ; TODO: change?

Tile_Positions:
board_start = $9863
DW board_start
DW board_start+$2
DW board_start+$4
DW board_start+$6
DW board_start+$8
DW board_start+$a
DW board_start+$c

DW board_start+$40
DW board_start+$42
DW board_start+$44
DW board_start+$46
DW board_start+$48
DW board_start+$4a
DW board_start+$4c

DW board_start+$80
DW board_start+$82
DW board_start+$84
DW board_start+$86
DW board_start+$88
DW board_start+$8a
DW board_start+$8c

DW board_start+$c0
DW board_start+$c2
DW board_start+$c4
DW board_start+$c6
DW board_start+$c8
DW board_start+$ca
DW board_start+$cc

SECTION "HiRAM", HRAM

hPadPressed::   ds 1
hPadHeld::      ds 1
hPadReleased::  ds 1
hPadOld::       ds 1

SECTION "Joypad", ROM0

BUTTON_A        EQU %00000001
BUTTON_B        EQU %00000010
BUTTON_SELECT   EQU %00000100
BUTTON_START    EQU %00001000
BUTTON_RIGHT    EQU %00010000
BUTTON_LEFT     EQU %00100000
BUTTON_UP       EQU %01000000
BUTTON_DOWN     EQU %10000000

ReadJoyPad::
    ldh     a,[hPadHeld]
    ldh     [hPadOld],a
    ld      c,a
    ld      a,$20
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $0F
    swap    a
    ld      b,a
    ld      a,$10
    ldh     [rP1],a
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    ldh     a,[rP1]
    cpl
    and     $0F
    or      b
    ldh     [hPadHeld],a
    ld      b,a
    ld      a,c
    cpl
    and     b
    ldh     [hPadPressed],a
    xor     a
    ldh     [rP1],a
    ldh     a,[hPadOld]
    ld      b,a
    ldh     a,[hPadHeld]
    cpl
    and     b
    ldh     [hPadReleased],a
    ret


; Tiles and map

SECTION "Game tiles", ROM0
INCLUDE "patrick_tiles.z80"
INCLUDE "patrick_map.z80"
INCLUDE "font.z80"

SECTION "SRAM check", SRAM
SRAM_present: DB

SECTION "Game logic", ROM0

begin:
    ; Initialize stack
    ld sp, $e000
    ; Enable interrupts
    ld a, IEF_VBLANK
    ld [rIE], a
    ei

init:
    call StopLCD
    ; Blank OAM
    xor a
    ld hl, _OAMRAM
    ld bc,$FE9F-_OAMRAM+1
    call mem_Set

    ; BLANK VRAM
    ld hl, _SCRN0
    ld bc, _SCRN1-_SCRN0
    call mem_SetVRAM

    ; Blank HRAM
    ld hl, _HRAM
    ld bc, 63
    call mem_Set

    ; Blank WRAM
    ld hl, _RAM+3
    ld bc, $DFFD-_RAM-2 ; Don't clear seed
    call mem_Set

    ld a, %11101111 ; palette
    ld [rOBP0], a
    ld a, %11100100
    ld [rBGP], a

    ld hl, TilesFont
    ld de, $8300
    ld bc, 16*11
    call mem_CopyVRAM
    ld hl, TilesFont+(16*11)
    ld de, $8410
    ld bc, 16*26
    call mem_CopyVRAM

    ld    hl, TileLabel
    ld    de, $8600
    ld    bc, 41*16
    call    mem_CopyVRAM    ; load tile data

    ld h, 0
    ld l, h
    ld [hl], CART_RAM_ENABLE
    ld a, [SRAM_present]
    cp a, SRAM_check
    jr z, .SRAM_ok
    ; Blank SRAM
    ld a, SRAM_check
    ld [SRAM_present], a
    ld h, 0
    ld l, h
    ld [hl], h ; Disable SRAM
.SRAM_ok:
    call StartLCD

GenerateLevel:
    xor a
    ld hl, Tile_Status
    ld bc, 28
    call mem_Set
    ld c, 7
.ball_loop:
    push bc
    call RandomTile
    pop bc
    ld b, a ; b is now tile

    ld hl, Ball_Status
    ld a, c
    dec a
    add a, l
    ld l, a

    ld [hl], b ; save ball status
    ld hl, Tile_Status
    ld a, b
    add a, l
    ld l, a
    ;ld a, 1
    ;cp a, [hl] ; does this tile contain something > 1, ie. not patrick?
    ;jr c, .next_ball ; if so, go to next ball
    ld [hl], c ; store ball
.next_ball:
    dec c
    jr z, Load_Level
    jr .ball_loop

Load_Level:
    xor a
.draw_tile:
    push af
    ld hl, Tile_Positions
    ld de, Tile_Status
    sla a
    add a, l
    ld l, a
    pop af
    push af
    ;sla a
    add a, e
    ld e, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ld a, [de]
    cp a, 0
    jr z, .empty_tile
    cp a, 1
    jr z, .patrick

    sla a
    sla a
    add a, $65
    call wait_vblank
    ld [hl+], a
    inc a
    ld [hl], a
    inc a
    ld bc, $1f
    add hl, bc
    ld [hl+], a
    inc a
    ld [hl], a
    jr .done

.patrick:
    pop af
    push af
    ld [PATRICK_TILE], a
    ld [MARKER_TILE], a
    call get_sprite_position
    ld a, d
    ld [PATRICK_Y], a
    ld [MARKER_Y], a
    ld a, e
    ld [PATRICK_X], a
    ld [MARKER_X], a

    call draw_patrick
    call draw_marker
    jr .done

.empty_tile:
    ld a, $61
    call wait_vblank
    ld [hl+], a
    inc a
    ld [hl], a
    inc a
    ld bc, $1f
    add hl, bc
    ld [hl+], a
    inc a
    ld [hl], a

.done:
    pop af
    inc a
    cp a, 28
    jp nz, .draw_tile

    ld hl, REMAINING_TILES
    ld [hl], a

 PRINT "LEVEL:", $9983
 PRINT "SCORE:", $99A3
 PRINT "WIN:", $99C3
 PRINT "LOSE:", $99E3

GameLoop:
    call wait_vblank
    call ReadJoyPad
    ldh a,[hPadPressed]
    and BUTTON_LEFT
    jr nz, .left
    ldh a,[hPadPressed]
    and BUTTON_RIGHT
    jr nz,.right
    ldh a,[hPadPressed]
    and BUTTON_UP
    jr nz,.up
    ldh a,[hPadPressed]
    and BUTTON_DOWN
    jr nz,.down
    ldh a,[hPadPressed]
    and BUTTON_A
    jp nz,.button_a
    ldh a,[hPadPressed]
    and BUTTON_B
    jp nz,.button_b
    jr GameLoop
.left:
    ld hl, MARKER_X
    ld a, [hl]
    ld b, a

    ld a, [PATRICK_X]
    sub a, 16

    cp a, b
    jr nc, GameLoop

    ld a, b
    ld b, $28
    cp a, b
    jr c, GameLoop

    sub a, 16
    ld [hl], a

    ld hl, MARKER_TILE
    dec [hl]

    call draw_marker
    jr GameLoop
.right:
    ld a, [PATRICK_X]
    add a, 16
    ld b, a

    ld hl, MARKER_X
    ld a, [hl]

    cp a, b
    jr nc, GameLoop

    ld b, $80
    cp a, b
    jr nc, GameLoop

    add a, 16
    ld [hl], a

    ld hl, MARKER_TILE
    inc [hl]

    call draw_marker
    jr GameLoop
.down:
    ld a, [PATRICK_Y]
    add a, 16
    ld b, a

    ld hl, MARKER_Y
    ld a, [hl]

    cp a, b
    jr nc, GameLoop

    ld b, $58
    cp a, b
    jr nc, GameLoop

    add a, 16
    ld [hl], a

    ld hl, MARKER_TILE
    ld a, [hl]
    add a, 7
    ld [hl], a

    call draw_marker
    jp GameLoop
.up:
    ld hl, MARKER_Y
    ld a, [hl]
    ld b, a

    ld a, [PATRICK_Y]
    sub a, 16

    cp a, b
    jp nc, GameLoop

    ld a, b
    ld b, $38
    cp a, b
    jp c, GameLoop

    sub a, 16
    ld [hl], a

    ld hl, MARKER_TILE
    ld a, [hl]
    sub a, 7
    ld [hl], a

    call draw_marker
    jp GameLoop
.button_b:
    ld a, [REMAINING_TILES]
    cp a, 28
    jp nz, GameLoop
    jp GenerateLevel
.button_a:
    ld a, [MARKER_TILE]
    ld hl, Tile_Status
    ;dec a
    add a, l
    ld l, a
    ld a, [hl]
    cp a, -1
    jp z, GameLoop
    cp a, 1
    jp z, GameLoop
    ; tile is not destroyed

    ; destroy patrick's tile
    ld a, [PATRICK_TILE]
    call destroy_tile

    ; if this is a ball tile, destroy appropriate tiles

    ; move patrick to new tile
    ld a, [MARKER_TILE]
    ld [PATRICK_TILE], a
    ld b, a
    ld hl, Tile_Status
    ;dec a
    add a, l
    ld l, a
    ld [hl], 1
    ld hl, Tile_Positions
    ld a, b
    ;dec a
    sla a
    add a, l
    ld l, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call draw_patrick
    ld a, [MARKER_X]
    ld [PATRICK_X], a
    ld a, [MARKER_Y]
    ld [PATRICK_Y], a

    ld a, 1
    ld hl, REMAINING_TILES
    cp a, [hl]
    jp z, GenerateLevel

    ; check for lose condition

    jp GameLoop

destroy_tile:
    ; destroy tile number a
    ld hl, Tile_Status
    ld b, a
    ;dec a
    add a, l
    ld l, a
    ld [hl], -1
    ld hl, REMAINING_TILES
    dec [hl]
    ld hl, Tile_Positions
    ld a, b
    ;dec a
    sla a
    add a, l
    ld l, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    call wait_vblank
    xor a
    ld [hl+], a
    ld [hl], a
    ld bc, $1f
    add hl, bc
    ld [hl+], a
    ld [hl], a
    ret

draw_marker:
    push hl
    push af
    call wait_vblank
    ld hl, _OAMRAM+4
    ld a, [MARKER_Y]
    ld [hl+], a
    ld a, [MARKER_X]
    ld [hl+], a
    ld a, $85
    ld [hl+], a

    inc hl
    ld a, [MARKER_Y]
    ld [hl+], a
    ld a, [MARKER_X]
    add a, 8
    ld [hl+], a
    ld a, $86
    ld [hl+], a

    inc hl
    ld a, [MARKER_Y]
    add a, 8
    ld [hl+], a
    ld a, [MARKER_X]
    ld [hl+], a
    ld a, $87
    ld [hl+], a

    inc hl
    ld a, [MARKER_Y]
    add a, 8
    ld [hl+], a
    ld a, [MARKER_X]
    add a, 8
    ld [hl+], a
    ld a, $88
    ld [hl+], a

    pop af
    pop hl
    ret

draw_patrick:
    call wait_vblank
    ld [hl], $69
    inc hl
    ld [hl], $6b
    ld bc, $1f
    add hl, bc
    ld [hl], $6a
    inc hl
    ld [hl], $6c
    ret

RandomTile:
    ; http://www.devrs.com/gb/files/random.txt
    ; (Allocate 3 bytes of ram labeled 'Seed')
    ; Exit: A = 0-255, random number
    ld      hl,Seed
    ld      a,[hl+]
    sra     a
    sra     a
    sra     a
    xor     [hl]
    inc     hl
    rra
    rl      [hl]
    dec     hl
    rl      [hl]
    dec     hl
    rl      [hl]
    ld      a,[$fff4]          ; get divider register to increase randomness
    add     [hl]

    ; output = (input - input_start)*output_range / input_range + output_start;

    ; (a - 0) * 27 / 255 + 0;
    ; (a - 1) * 28 / 256 + 1;

    ld h, a
    ld e, 27

Mul8b:                           ; this routine performs the operation HL=H*E
    ld d,0                         ; clearing D and L
    ld l,d
    ld b,8                         ; we have 8 bits
Mul8bLoop:
    add hl,hl                      ; advancing a bit
    jr nc,Mul8bSkip                ; if zero, we skip the addition (jp is used for speed)
    add hl,de                      ; adding to the product if necessary
Mul8bSkip:
    dec b
    jr nz, Mul8bLoop

;    ld d, h
;    ld e, l
;    ld b, 0
;    ld c, 255

; 16 bit division
; DE = DE / BC, BC = remainder

;div_DE_BC_DEBCu:
;        ld      hl,_MD16temp
;        ld      [hl],c
;        inc     hl
;        ld      [hl],b
;        inc     hl
;        ld      [hl],17
;        ld      bc,0
;.nxtbit:
;        ld      hl,_MD16count
;        ld      a,e
;        rla
;        ld      e,a
;        ld      a,d
;        rla
;        ld      d,a
;        dec     [hl]
;        jr      z,.done
;        ld      a,c
;        rla
;        ld      c,a
;        ld      a,b
;        rla
;        ld      b,a
;        dec     hl
;        dec     hl
;        ld      a,c
;        sub     [hl]
;        ld      c,a
;        inc     hl
;        ld      a,b
;        sbc     a,[hl]
;        ld      b,a
;        jr      nc,.noadd
;
;        dec     hl
;        ld      a,c
;        add     a,[hl]
;        ld      c,a
;        inc     hl
;        ld      a,b
;        adc     a,[hl]
;        ld      b,a
;.noadd:
;        ccf
;        jr      .nxtbit
;
;.done:
;    ld a, e
    ld a, h
    ret
;
;get_map_position:
;; from a sprite's pixel position, get the BG map address.
;; d: Y pixel position
;; e: X pixel position
;; hl: returned map address
;    push af
;
;    ld h, HIGH(_SCRN0) >> 2
;
;    ; Y
;    ld a, [rSCY] ; account for scroll
;    sub a, 16    ; account for base sprite offset
;    add a, d
;    and $F8      ; snap to grid
;    add a, a
;    rl h
;    add a, a
;    rl h
;    ld l, a
;
;    ; X
;    ld a, [rSCX] ; account for scroll
;    sub a, 8     ; account for base sprite offset
;    add a, e
;    and $F8      ; snap to grid
;    rrca
;    rrca
;    rrca
;    add a, l
;    ld l, a
;
;    pop af
;    ret
;
get_sprite_position:
; from a BG map address, get the sprite position
; hl: map address
; d: Y pixel position
; e: X pixel position
    push af
    push hl
    ; Y
    ; (0x94 & 0b00111111)*4
    ld a, l
    rrc h
    rra
    rrc h
    rra
    rrc h
    rra
    rrc h
    rra
    and a, %00111111
    sla a
    sla a
    add a, 16 ; sprite offset
    ld d, a

    ; X
    ; (0x53 & 0b00011111)*8
    ld a, l
    and %00011111
    sla a
    sla a
    sla a
    add a, 8 ; sprite offset
    ld e, a
    pop hl
    pop af
    ret
