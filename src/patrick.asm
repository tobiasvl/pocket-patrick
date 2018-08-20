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

Tile_Status:
; 1 - patrick
; 2 - yellow (top)
; 3 - blue (right)
; 4 - darkblue (right/left)
; 5 - green (left)
; 6 - red (down)
; 7 - orange (top/down)
DS 28

SECTION "Constants", ROM0
SRAM_check EQU 42 ; TODO: change?

Tile_Positions:
DW $9821
DW Tile_Positions+2
DW Tile_Positions+4
DW Tile_Positions+6
DW Tile_Positions+8
DW Tile_Positions+10
DW Tile_Positions+12

DW Tile_Positions+40
DW Tile_Positions+42
DW Tile_Positions+44
DW Tile_Positions+46
DW Tile_Positions+48
DW Tile_Positions+50
DW Tile_Positions+52

DW Tile_Positions+80
DW Tile_Positions+82
DW Tile_Positions+84
DW Tile_Positions+86
DW Tile_Positions+88
DW Tile_Positions+90
DW Tile_Positions+92

DW Tile_Positions+120
DW Tile_Positions+122
DW Tile_Positions+124
DW Tile_Positions+126
DW Tile_Positions+128
DW Tile_Positions+130
DW Tile_Positions+132

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
    ld hl, _RAM
    ld bc, $DFFD-_RAM+1 ; Don't clear stack
    call mem_Set

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
    call wait_vblank
    ld    hl, TileLabel
    ld    de, _VRAM        ; $8000
    ld    bc, 8*16*8
    call    mem_CopyVRAM    ; load tile data
    ld    hl, MapLabel
    ld    de, _SCRN0
    ld    bc, 32*32
    call    mem_CopyVRAM    ; load bg map data

    ld hl, PATRICK_Y
    ld a, 64
    ld [hl+], a
    ld a, 64
    ld [hl], a

    call wait_vblank
    ld hl, _OAMRAM
    ld a, [PATRICK_Y]
    ld [hl+], a
    ld a, [PATRICK_X]
    ld [hl+], a
    ld a, 9
    ld [hl+], a
    inc hl
    ld a, [PATRICK_Y]
    ld [hl+], a
    ld a, [PATRICK_X]
    add a, 8
    ld [hl+], a
    ld a, 10
    ld [hl+], a

.wait:
    halt
    jr .wait





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

;;;;;;;;;
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
;;;;;;;;;


    ld d, h
    ld e, l
    ld b, 0
    ld c, 255

;;;;;;;;;
DE_Div_BC:          ;1281-2x, x is at most 16
    ld a,16        ;7
    ld hl,0        ;10
    jr DivFoo         ;10
DivLoop:
    add hl,bc    ;--
    dec a        ;64
    jr z, DivDone        ;86
DivFoo:
    sla e        ;128
    rl d         ;128
    ;adc hl,hl    ;240
    rla
    add hl, hl
    rra
    and a, %01111111
    jr nc, .noCarry
    inc hl
.noCarry
    ;sbc hl,bc    ;240
REPT 8
    rl b
    ccf
ENDR
    rl b
REPT 8
    rl c
    ccf
ENDR
    rl c
    jr c, .carry
    inc bc
.carry
    add hl, bc
    ccf

    jr nc,DivLoop ;23|21
    inc e        ;--
    jr DivLoop+1
DivDone
;;;;;;;;

    ld a, e
    ret





