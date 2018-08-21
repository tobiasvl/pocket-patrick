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

Ball_Status:
DS 7

SECTION "Constants", ROM0
SRAM_check EQU 42 ; TODO: change?

Tile_Positions:
DW $9821
DW $9821+2
DW $9821+4
DW $9821+6
DW $9821+8
DW $9821+10
DW $9821+12

DW $9821+40
DW $9821+42
DW $9821+44
DW $9821+46
DW $9821+48
DW $9821+50
DW $9821+52

DW $9821+80
DW $9821+82
DW $9821+84
DW $9821+86
DW $9821+88
DW $9821+90
DW $9821+92

DW $9821+120
DW $9821+122
DW $9821+124
DW $9821+126
DW $9821+128
DW $9821+130
DW $9821+132

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
    ld    bc, 37*16
    call    mem_CopyVRAM    ; load tile data
;    ld    hl, MapLabel
;    ld    a, [Tile_Positions]
;    sub   a, $21
;    ld    e, a
;    ld    a, [Tile_Positions+1]
;    ld    d, a
;    ld    bc, 32*32
;    call    mem_CopyVRAM    ; load bg map data

;    ld hl, PATRICK_Y
;    ld a, 64
;    ld [hl+], a
;    ld a, 64
;    ld [hl], a
;
;    call wait_vblank
;    ld hl, _OAMRAM
;    ld a, [PATRICK_Y]
;    ld [hl+], a
;    ld a, [PATRICK_X]
;    ld [hl+], a
;    ld a, 9
;    ld [hl+], a
;    inc hl
;    ld a, [PATRICK_Y]
;    ld [hl+], a
;    ld a, [PATRICK_X]
;    add a, 8
;    ld [hl+], a
;    ld a, 10
;    ld [hl+], a

    ld c, 7
.ball_loop:
    push bc
    call RandomTile
    pop bc
    ld b, a ; b is now tile
    ld hl, Ball_Status
    ld a, c
    dec a
    add a, h ; TODO or h
    ld l, a
    ld [hl], b ; save ball status
    ld hl, Tile_Status
    ld a, b
    add a, h  ; TODO or h?
    ld l, a
    ld a, 1
    cp a, [hl] ; does this tile contain something > 1, ie. not patrick?
    jr c, .next_ball ; if so, go to next ball
    ld [hl], c ; store ball
.next_ball:
    dec c
    jr z, Load_Level
    jr .ball_loop

Load_Level:
    ld a, 0
.draw_tile:
    push af
    ld hl, Tile_Positions
    ld de, Tile_Status
    sla a
    add a, l
    ld l, a
    pop af
    push af
    sla a
    add a, e
    ld e, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ld a, [de]
    cp a, 0
    jr z, .empty_tile

    sla a
    sla a
    add a, 12
    ld [hl], a
    inc hl
    inc a
    ld [hl], a
    inc a
    ld bc, $41
    add hl, bc
    ld [hl], a
    inc hl
    inc a
    ld [hl], a
    jr .done

.empty_tile:
    ld [hl], 1
    inc hl
    ld [hl], 2
    ld bc, $41
    add hl, bc
    ld [hl], 3
    inc hl
    ld [hl], 4

.done:
    pop af
    inc a
    cp a, 27
    jr nz, .draw_tile

;Draw_Level:
;    
;
;
;
;    call wait_vblank
;    ld    hl, TileLabel
;    ld    de, _VRAM        ; $8000
;    ld    bc, 8*16*8
;    call    mem_CopyVRAM    ; load tile data
;    ld    hl, MapLabel
;    ld    a, [Tile_Positions]
;    sub   a, $21
;    ld    e, a
;    ld    a, [Tile_Positions+1]
;    ld    d, a
;    ld    bc, 32*32
;    call    mem_CopyVRAM    ; load bg map data
;    
;
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
    jr nc, .noCarry
    inc hl
.noCarry
    and a, %01111111
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
DivDone:
;;;;;;;;

    ld a, e
    ret
