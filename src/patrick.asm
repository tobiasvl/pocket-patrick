; vi:syntax=rgbds

INCLUDE "hardware.inc" ; standard hardware definitions from devrs.com

; IRQs
; copy x-bytes to [de]
SECTION "Copy Data",ROM0[$28]
COPY_DATA:
  ; pop return address off stack into hl
  pop hl
  ; here we get the number of bytes to copy
  ; hl contains the address of the bytes following the "rst $28" call

  ; counter
  ld a, [hl+]
  ld c, a

  ; bc now contains $000D
  ; hl now points to the first byte of our assembled subroutine (which is $F5)
  ; begin copying data
.copy_data_loop:
  ; load a byte of data into a
  ld a, [hl+]

  ; store the byte in de, our destination ($FF80 in this context)
  ld [de], a

  ; go to the next destination byte, decrease counter
  inc de
  dec c

  ; check if counter is zero, if not repeat loop
  ld a, c
  or a
  jr nz,.copy_data_loop

  ; all done, return home
  jp hl
  reti

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

DMA_COPY:
  ; load de with the HRAM destination address
  ld  de, $ff90
  rst $28
  DB .end_of_DMA_routine-.DMA_routine ; number of bytes to copy

; Copy this into HRAM:
.DMA_routine:
  ; first we load $C1 into the DMA register at $FF46
  push af
  ld a, $C1
  ld [$FF46], a

  ; DMA transfer begins, we need to wait 160 microseconds while it transfers
  ; the following loop takes exactly that long
  ld a, $28
.loop:
  dec a
  jr nz, .loop
  pop af
  reti
.end_of_DMA_routine:
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
MARKER_TILE: DB
PATRICK_Y: DB
PATRICK_X: DB
PATRICK_TILE: DB
LEVEL: DB
REMAINING_TILES: DB
STEPS: DB
SCORE: DW
SCORE_WIN: DB
SCORE_LOSE: DB
HIGH_SCORE: DW

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

SECTION "OAM data",WRAM0[$C100]
OAM_SpriteData:
MARKER_Y: DB
MARKER_X: DB
DS (4*4)-2 ; 4*4*7

SECTION "Constants", ROM0, ALIGN[8]
SRAM_check EQU 42 ; TODO: change?

Tile_Positions:
board_start = $9883
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

PATRICK EQU $69
LOSE_PATRICK EQU $89
WIN_PATRICK EQU $8D

SpriteData:
    DB 0,0,$85,0,0,0,$86,0,0,0,$87,0,0,0,$88,0
;    DB 0,0,$61,0,0,0,$62,0,0,0,$63,0,0,0,$64,0
;    DB 0,0,$61,0,0,0,$62,0,0,0,$63,0,0,0,$64,0
;    DB 0,0,$61,0,0,0,$62,0,0,0,$63,0,0,0,$64,0
;    DB 0,0,$61,0,0,0,$62,0,0,0,$63,0,0,0,$64,0
;    DB 0,0,$61,0,0,0,$62,0,0,0,$63,0,0,0,$64,0
;    DB 0,0,$61,0,0,0,$62,0,0,0,$63,0,0,0,$64,0

SECTION "Joypad variables", HRAM

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
INCLUDE "patrick_logo.z80"

SECTION "SRAM check", SRAM
SRAM_present: DB
SRAM_highscore: DW

SECTION "Game logic", ROM0

begin:
    ; Initialize stack
    ld sp, $e000
    ; Enable interrupts
    ld a, IEF_VBLANK
    ld [rIE], a
    ei

init:
    ;call StopLCD
    ; Blank OAM
    call wait_vblank
    xor a
    ld hl, _OAMRAM
    ld bc,$FE9F-_OAMRAM+1
    call mem_Set

    call DMA_COPY

    ; Blank HRAM
    ld hl, _HRAM
    ld bc, 4
    call mem_Set

    ; Blank WRAM
    ld hl, _RAM+3
    ld bc, $DFFD-_RAM-2 ; Don't clear seed
    call mem_Set

    ld a, %11100100
    ld [rOBP0], a
    ld a, %11100100
    ld [rBGP], a

    ld hl, TilesFont
    ld de, $8270
    ld bc, 16*20
    call mem_CopyVRAM
    ld hl, TilesFont+(16*20)
    ld de, $8410
    ld bc, 16*26
    call mem_CopyVRAM

    ld    hl, TileLabel
    ld    de, $8600
    ld    bc, 49*16
    call    mem_CopyVRAM    ; load tile data

    ld h, 0
    ld l, h
    ld [hl], CART_RAM_ENABLE
    ld a, [SRAM_present]
    cp a, SRAM_check
    jr z, .SRAM_ok
    ; Blank SRAM
    xor a
    ld hl, _SRAM
    ld bc, 32
    call mem_Set
    ld a, SRAM_check
    ld [SRAM_present], a
.SRAM_ok:
    ld a, [SRAM_highscore]
    ld [HIGH_SCORE], a
    ld a, [SRAM_highscore+1]
    ld [HIGH_SCORE+1], a
    ld [hl], h ; Disable SRAM

NintendoLogo:
    call wait_vblank
    ld a, WIN_PATRICK
    ld hl, $9900
    push hl
    call draw_patrick+3
    pop hl

    ;call StartLCD
    ld d, 10
    ld e, 20
.foo:
    call wait_vblank
    dec e
    jr nz, .foo
    ld e, 20

    ld a, $a0
    call draw_patrick+3

    ld a, l
    sub a, $1f
    ld l, a
    ld a, WIN_PATRICK
    push hl
    call draw_patrick+3
    pop hl

    dec d
    jr nz, .foo

TitleScreen:
    ; BLANK VRAM
    xor a
    ld hl, _SCRN0
    ld bc, _SCRN1-_SCRN0
    call mem_SetVRAM

    ld hl, patrick_logo_tile_data
    ld de, $8a00
    ld bc, patrick_logo_tile_data_size
    call mem_CopyVRAM

    ld hl, patrick_logo_map_data
    ld de, $9820
    ld bc, _SCRN1-_SCRN0
    call mem_CopyVRAM

    ;PRINT "START",$98e8
    ;PRINT "TUTORIAL",$9908
    PRINT "HISCORE:",$99a4
    PRINT "BY",$9a09
    PRINT "TOBIASVL",$9a26

.place_sprites:
   call wait_vblank
   ld a, 100
   ld [$fe00], a
   ld [$fe04], a
   ld [$fe08], a
   ld [$fe0c], a
   ld [$fe10], a
   ld [$fe14], a
   ld [$fe18], a
   ld [$fe1c], a
   ld [$fe20], a
   ld [$fe24], a
   ld a, 44
   ld [$fe01], a
   ld a, "P"
   ld [$fe02], a
   ld a, 52
   ld [$fe05], a
   ld a, "R"
   ld [$fe06], a
   ld a, 60
   ld [$fe09], a
   ld a, "E"
   ld [$fe0A], a
   ld a, 68
   ld [$fe0D], a
   ld a, "S"
   ld [$fe0E], a
   ld a, 76
   ld [$fe11], a
   ld a, "S"
   ld [$fe12], a

   call wait_vblank
   ld a, 94
   ld [$fe15], a
   ld a, "S"
   ld [$fe16], a
   ld a, 102
   ld [$fe19], a
   ld a, "T"
   ld [$fe1A], a
   ld a, 110
   ld [$fe1D], a
   ld a, "A"
   ld [$fe1E], a
   ld a, 118
   ld [$fe21], a
   ld a, "R"
   ld [$fe22], a
   ld a, 126
   ld [$fe25], a
   ld a, "T"
   ld [$fe26], a

    call wait_vblank
    ld hl, $99ad
    ld de, HIGH_SCORE
    ld a, [de]
    and a, $0f
    add a, $30
    ld [hl+], a
    inc de
    ld a, [de]
    sra a
    sra a
    sra a
    sra a
    and a, $0f
    add a, $30
    ld [hl+], a
    ld a, [de]
    and a, $0f
    add a, $30
    ld [hl], a

    ld a, 1
    ld [LEVEL], a

    ld d, 0
MainMenu:
    inc d
    call wait_vblank
    ld a, d
    cp a, 50
    jr nz, .input_loop
    ld a, [rLCDC]
    xor a, LCDCF_OBJON
    ld [rLCDC], a
    ld d, 0
.input_loop:
    call wait_vblank
    call ReadJoyPad
    ;;ldh a,[hPadPressed]
    ;;and BUTTON_LEFT
    ;;jr nz, .left
    ;;ldh a,[hPadPressed]
    ;;and BUTTON_RIGHT
    ;;jr nz,.right
    ;ldh a,[hPadPressed]
    ;and BUTTON_UP
    ;jp nz,.up
    ;ldh a,[hPadPressed]
    ;and BUTTON_DOWN
    ;jr nz,.down
    ;ldh a,[hPadPressed]
    and BUTTON_A
    jp nz, Play
    ldh a,[hPadPressed]
    and BUTTON_START
    jp nz, Play
    ldh a,[hPadPressed]
    jr MainMenu
    ;;and BUTTON_B
    ;;jp nz,.button_b
    ;jr MainMenu
;.down:
;.up:
;.button_a:

Play:
    ; BLANK VRAM
    xor a
    ld hl, _SCRN0
    ld bc, _SCRN1-_SCRN0
    call mem_SetVRAM

GenerateLevel:
    ld a, $60
    ld [SCORE_WIN], a
    ld [SCORE_LOSE], a
    xor a
    ld [STEPS], a
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
    call init_marker
    call StopLCD
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

    ld a, PATRICK
    call draw_patrick+3
    jr .done

.empty_tile:
    ld a, $61
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

    PRINT "LEVEL", board_start+$120
    PRINT "SCORE", board_start+$140
    PRINT "WIN   +", board_start+$160
    PRINT "LOSE  -", board_start+$180
    call print_info
    call print_balls
    ld a, [rLCDC]
    or a, LCDCF_OBJON
    ld [rLCDC], a

    call StartLCD

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
    jp nz,.up
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
    call RandomTile
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
    call RandomTile
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
    call RandomTile
    ld a, [PATRICK_Y]
    add a, 16
    ld b, a

    ld hl, MARKER_Y
    ld a, [hl]

    cp a, b
    jp nc, GameLoop

    ld b, $58
    cp a, b
    jp nc, GameLoop

    add a, 16
    ld [hl], a

    ld hl, MARKER_TILE
    ld a, [hl]
    add a, 7
    ld [hl], a

    call draw_marker
    jp GameLoop
.up:
    call RandomTile
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
    call RandomTile
    ld a, [REMAINING_TILES]
    cp a, 28
    jp nz, GameLoop
    jp GenerateLevel
.button_a:
    call RandomTile
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
    ld a, [MARKER_TILE]
    ld b, a
    ld hl, Tile_Status
    add a, l
    ld l, a
    ld a, [hl]
    cp a, 1
    call nc, destroy_adjacent

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
    ld a, $69
    call draw_patrick
    ld a, [MARKER_X]
    ld [PATRICK_X], a
    ld a, [MARKER_Y]
    ld [PATRICK_Y], a

    ld hl, SCORE_WIN
    ld a, [hl]
    dec a
    daa
    ld [hl], a
    ld hl, SCORE_LOSE
    ld a, [hl]
    inc a
    daa
    ld [hl], a
    call wait_vblank
    call print_info

    ld hl, REMAINING_TILES
    ld a, [hl]
    cp a, 1
    jp z, win

    ; check for lose condition
    ld a, [PATRICK_Y]
    sub a, 16
    ld d, a
    ld a, [PATRICK_X]
    sub a, 16
    ld e, a
    call get_map_position
    ld a, $60
    cp a, [hl]
    jp c, GameLoop

    ld a, e
    add a, 16
    ld e, a
    call get_map_position
    ld a, $60
    cp a, [hl]
    jp c, GameLoop

    ld a, e
    add a, 16
    ld e, a
    call get_map_position
    ld a, $60
    cp a, [hl]
    jp c, GameLoop

    ld a, d
    add a, 16
    ld d, a
    call get_map_position
    xor a
    cp a, [hl]
    jp nz, GameLoop

    ld a, d
    add a, 16
    ld d, a
    call get_map_position
    xor a
    cp a, [hl]
    jp nz, GameLoop

    ld a, e
    sub a, 16
    ld e, a
    call get_map_position
    xor a
    cp a, [hl]
    jp nz, GameLoop

    ld a, e
    sub a, 16
    ld e, a
    call get_map_position
    xor a
    cp a, [hl]
    jp nz, GameLoop

    ld a, d
    sub a, 16
    ld d, a
    call get_map_position
    xor a
    cp a, [hl]
    jp nz, GameLoop

lose:
    xor a
    ld hl, board_start+$160
    ld bc, 9
    call mem_SetVRAM

    ld a, [PATRICK_TILE]
    ld hl, Tile_Positions
    sla a
    add a, l
    ld l, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ld a, LOSE_PATRICK
    call draw_patrick

    ld hl, LEVEL
    ld a, [hl]
    inc a
    daa
    ld [hl], a
    ld de, SCORE+1
    ld hl, SCORE_LOSE
    ld a, [de]
    sub a, [hl]
    ld hl, SCORE+1
    daa
    ld [hl-], a
    jr nc, game_over
    ld a, [hl]
    dec a
    daa
    jr nc, .not_zero
    xor a
    ld [hl+], a
.not_zero:
    ld [hl], a
    jr game_over

win:
    xor a
    ld hl, board_start+$180
    ld bc, 9
    call mem_SetVRAM

    ld a, [PATRICK_TILE]
    ld hl, Tile_Positions
    sla a
    add a, l
    ld l, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a

    ld a, WIN_PATRICK
    call draw_patrick

    ld hl, LEVEL
    ld a, [hl]
    inc a
    daa
    ld [hl], a
    ld hl, SCORE+1
    ld a, [SCORE_WIN]
    add a, [hl]
    daa
    ld [hl-], a
    jp nc, .store_hiscore
    ld a, [hl]
    inc a
    daa
    ld [hl], a
.store_hiscore
    ld hl, HIGH_SCORE
    cp a, [hl]
    jr c, game_over
    inc hl
    ld a, [SCORE+1]
    cp a, [hl]
    jr c, game_over
    ld [hl-], a
    ld a, [SCORE]
    ld [hl], a
    ld h, 0
    ld l, h
    ld [hl], CART_RAM_ENABLE
    ld [SRAM_highscore], a
    ld a, [SCORE+1]
    ld [SRAM_highscore+1], a
    ld [hl], h ; Disable SRAM

game_over:
    ld a, [rLCDC]
    xor a, LCDCF_OBJON
    ld [rLCDC], a
.game_over_loop:
    call wait_vblank
    call ReadJoyPad
    ldh a,[hPadPressed]
    and BUTTON_A
    jp nz, Play
    ldh a,[hPadPressed]
    and BUTTON_B
    jp nz, GenerateLevel
    jr .game_over_loop

destroy_tile:
    push af
    ; destroy tile number a
    ld hl, Tile_Status
    ld b, a
    ;dec a
    add a, l
    ld l, a
    ld a, -1
    cp a, [hl]
    jr z, .done ; was destroyed already
    ld [hl], a
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
.done:
    pop af
    ret

destroy_adjacent:
    ; 2 - yellow (top)
    ; 3 - blue (right)
    ; 4 - darkblue (right/left)
    ; 5 - green (left)
    ; 6 - red (down)
    ; 7 - orange (top/down)
    cp a, 2
    jr z, .up
    cp a, 3
    jr z, .right
    cp a, 4
    jr z, .right_left
    cp a, 5
    jr z, .left
    cp a, 6
    jr z, .down
    cp a, 7
    jr z, .up_down

.up_down:
    push bc
    call .up
    pop bc
    call .down
    ret

.right_left:
    push bc
    call .right
    pop bc
    call .left
    ret

.up:
    ld a, b
    sub a, 8
    ret c
    cp a, 6
    jr z, .up_middle
    cp a, 13
    jr z, .up_middle
    cp a, 20
    call nz, destroy_tile
.up_middle:
    inc a
    call destroy_tile
    inc a
    cp a, 7
    ret z
    cp a, 14
    ret z
    cp a, 21
    ret z
    call destroy_tile
    ret
.right:
    ld a, b
    cp a, 6
    ret z
    cp a, 13
    ret z
    cp a, 20
    ret z
    cp a, 27
    ret z
    sub a, 6
    call nc, destroy_tile
    add a, 7
    call destroy_tile
    add a, 7
    cp a, 27
    call c, destroy_tile
    ret
.left:
    ld a, b
    cp a, 0
    ret z
    cp a, 7
    ret z
    cp a, 14
    ret z
    cp a, 21
    ret z
    sub a, 8
    call nc, destroy_tile
    add a, 7
    call destroy_tile
    add a, 7
    cp a, 27
    call c, destroy_tile
    ret
.down:
    ld a, b
    add a, 6
    cp a, 27
    ret nc
    cp a, 6
    jr z, .down_middle
    cp a, 13
    jr z, .down_middle
    cp a, 20
    call nz, destroy_tile
.down_middle:
    inc a
    call destroy_tile
    inc a
    cp a, 7
    ret z
    cp a, 14
    ret z
    cp a, 21
    ret z
    call destroy_tile
    ret

init_marker:
    ld hl, SpriteData
    ld de, OAM_SpriteData
    ld bc, 4*4 ;4*4*7
    call mem_Copy
    call wait_vblank
    ld a, %10010011 ; palette
    ld [rOBP0], a
    call $ff90
    ret

draw_marker:
    xor a
    ld b, a
    ld c, 3
    ld hl, MARKER_Y
    ld d, [hl]
    inc hl
    ld e, [hl]

    ld hl, OAM_SpriteData
    ld a, d
    ld [hl+], a
    ld a, e
    ld [hl], a
    add hl, bc

    ld a, d
    ld [hl+], a
    ld a, e
    add a, 8
    ld [hl], a
    add hl, bc

    ld a, d
    add a, 8
    ld [hl+], a
    ld a, e
    ld [hl], a
    add hl, bc

    ld a, d
    add a, 8
    ld [hl+], a
    ld a, e
    add a, 8
    ld [hl], a

    call wait_vblank
    call $ff90

    ret

draw_patrick:
    call wait_vblank
    ld [hl+], a
    add a, 2
    ld [hl], a
    ld bc, $1f
    add hl, bc
    dec a
    ld [hl+], a
    add a, 2
    ld [hl], a
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

get_map_position:
; from a sprite's pixel position, get the BG map address.
; d: Y pixel position
; e: X pixel position
; hl: returned map address
    push af

    ld h, HIGH(_SCRN0) >> 2

    ; Y
    ld a, [rSCY] ; account for scroll
    sub a, 16    ; account for base sprite offset
    add a, d
    and $F8      ; snap to grid
    add a, a
    rl h
    add a, a
    rl h
    ld l, a

    ; X
    ld a, [rSCX] ; account for scroll
    sub a, 8     ; account for base sprite offset
    add a, e
    and $F8      ; snap to grid
    rrca
    rrca
    rrca
    add a, l
    ld l, a

    pop af
    ret

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

print_info:
    ld hl, board_start+$127
    ld de, LEVEL
    ld a, [de]
    sra a
    sra a
    sra a
    sra a
    and a, $0f
    add a, $30
    ld [hl+], a
    ld a, [de]
    and a, $0f
    add a, $30
    ld [hl+], a

    ld hl, board_start+$146
    ld de, SCORE
    ld a, [de]
    and a, $0f
    add a, $30
    ld [hl+], a
    inc de
    ld a, [de]
    sra a
    sra a
    sra a
    sra a
    and a, $0f
    add a, $30
    ld [hl+], a
    ld a, [de]
    and a, $0f
    add a, $30
    ld [hl], a

    ld hl, board_start+$167
    ld de, SCORE_WIN
    ld a, [de]
    sra a
    sra a
    sra a
    sra a
    and a, $0f
    add a, $30
    ld [hl+], a
    ld a, [de]
    and a, $0f
    add a, $30
    ld [hl], a

    ld hl, board_start+$187
    ld de, SCORE_LOSE
    ld a, [de]
    sra a
    sra a
    sra a
    sra a
    and a, $0f
    add a, $30
    ld [hl+], a
    ld a, [de]
    and a, $0f
    add a, $30
    ld [hl], a
    ret

print_balls:
    xor a
    ld hl, board_start-$60
    ld bc, $2c
    call mem_SetVRAM

    ld hl, Ball_Status
    ld de, board_start-$60
    ld c, 7
.loop_ball:
    ld a, e
    cp a, $30
    jr c, .ten
    ld e, $43
.ten:
    ld a, [hl+]
    inc a
    call bin2bcd
    ld b, a
    and a, $f0
    jr z, .one
    sra a
    sra a
    sra a
    sra a
    add a, $30
    ld [de], a
    inc de
.one:
    ld a, b
    and a, $0f
    add a, $30
    ld [de], a
    inc de
    inc de
    dec c
    jr nz, .loop_ball
    ret

bin2bcd:
   	push	bc
   	ld	c, a
   	ld	b, 8
   	xor	a
.loop:
   	sla	c
   	adc	a, a
   	daa
    dec b
   	jr nz, .loop
   	pop	bc
   	ret
