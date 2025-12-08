; JSM115K.asm
;
; Super-simple serial terminal suitable to re-configure the HC-05
; bluetooth module within a jiocart using 115200 bps in AT mode from
; the MSX itself.
; Sends a line once Enter is pressed, and then receives a line
; terminated in CR, until program is stopped.
;
; Based on jsm.as from the MSXJIO project by Louthrax
; See https://github.com/louthrax/MSXJIO
;
; Released under
; Attribution-NonCommercial-ShareAlike 4.0 International
; license like the original jsm.as
;
; Modified and commented by Albert Herranz for 115k/jiocart
; See https://github.com/herraa1/msx-jio-cart-v1
; 
; Uses 115200 bps serial routines by Nyyrikki
; See https://www.msx.org/forum/msx-talk/development/software-rs-232-115200bps-on-msx
;
; Assemble with Konamiman's Nestor80 [1] by running:
;   N80 JASM115K.asm
;
; [1] https://github.com/Konamiman/Nestor80
;

CHPUT:  equ 0x00A2
INLIN:  equ 0x00B1

CHGCPU: equ 0x0180
GETCPU: equ 0x0183

MSXVER: equ 0x002D

; must match IOSEL setting on the jiocart
JIOREG: equ 0x30

        org 0xc800-7

; bload header
db 0xFE
dw start, endadr, start

start:

; print program banner
        LD   HL, banner     ; address of program banner
        CALL CHPUTS         ; print null terminated program banner

        CALL save_cpu_mode  ; save cpu mode for later

main_loop:
        CALL INLIN          ; read a line from keyboard,
                            ; up to 256 characters are
                            ; stored between 0xf55e and 0xf65d
        RET  c              ; return/exit pgm if STOP pressed

        PUSH HL             ; HL points to start buffer minus one

find_null:
        INC  HL             ; go to the start of the buffer
        LD   A,(HL)         ; load byte from buffer
        OR   A              ; check if byte is null terminator
        JR   nz,find_null   ; keep searching otherwise

null_found:
        ; XXX this will override other vars if more than 254 chars
        ; are read
        LD   (HL),"\r"      ; add "\r"
        INC  HL
        LD   (HL),"\n"      ; add "\n"
        INC  HL
        LD   (HL),"\0"      ; null terminate the buffer
        ld   b,h            ; save end of string
        ld   c,l
        POP  HL             ; set HL to start of the buffer - 1
        INC  HL             ; advance to the start of the buffer
        ld   d,h            ; DE stores start of string
        ld   e,l            ;
        ld   h,b            ; HL stores end of string
        ld   l,c            ;
        sbc  hl,de          ; HL stores length of string

        ld   b,h            ; BC stores length of string
        ld   c,l            ;
        ld   h,d            ; HL stores start of string
        ld   l,e            ;

        CALL set_z80_mode   ; set z80 mode
        DI                  ; disable interrupts

        ; HL=buffer, BC=length
        CALL tx_string      ; TX string

rx_string:
        LD   HL,recvbuf
        CALL rx_bytes       ; receive serial bytes until "\r"

        LD   (HL),0         ; null terminate buffer

        or   a
        JR   nz,return_seen ; z is set when "\r" is seen

        ; XXX this is not reached anymore
        ; check if ctrl key is pressed
        IN   A,(0xaa)       ; PPI reg C, keyb & cassette
        AND  0xf0           ; clear keyboard matrix row select register
        ADD  A,6            ; select row 6
        OUT  (0xaa),A
        IN   A,(0xa9)       ; PPI reg B, keyboard matrix row
        BIT  1,A            ; check if CTRL was pressed
        JR   nz,rx_string   ; CTRL was not pressed, keep receiving lines

return_seen: ; return was received
        EI                  ; enable interrupts
        CALL restore_cpu_mode ; restore CPU mode

        LD   HL,recvbuf     ; print received string
        CALL CHPUTS

; print two new lines after received string
        LD   HL,cr_lf
        CALL CHPUTS
        LD   HL,cr_lf
        CALL CHPUTS

        JR   main_loop   ; repeat again

; for 115200 bps we need to spend 31 cycles between each serial bit
; using a standard MSX z80 clock
;
; 3579545 Hz / 115200 bauds = ~31.07 cpu cycles

rx_bytes:
;********************************************************************************************************************************
; IN:  HL = DATA
;      /*BC = LENGTH*/
;********************************************************************************************************************************
        ld   d,b            ; put parameters on final place
        ld   e,c

        ld   iy,"\r"        ; receive function will stop when
                            ; this character is seen

        dec  hl             ; on every iteration we'll write
                            ; to (hl) and then increment hl,
                            ; compensate that for 1st iteration

        ld   c,JIOREG       ; C contains the jiocart i/o register

        ld   ix,0
        add  ix,sp          ; save sp in ix, we'll use sp
                            ; for 7 cycle instruction "ld sp,hl"

        ; The idea here is to test for the expected parity of the whole
        ; i/o register when a "1" bit is received, irrespective of
        ; other bit values in the same register, and assuming that the
        ; other bit values are not going to change during the whole
        ; i/o process.
        ; In the case of the joystick port, japanese keyboard layout,
        ; cassette input signal or other pins could influence parity.
        ; In the case of jiocart, other bit signals like CTS/ENA,
        ; DTR/STATE or TX may influence parity.

        in   a,(c)          ; read i/o register
        or   1              ; assume a "1" bit was received
;(
        ld   a,(hl)         ; store value from (hl) into a,
                            ; we will write a to (hl) on first
                            ; iteration
;)
        jp   pe,RX_PE       ; select a execution flow according to
                            ; observed parity
;________________________________________________________________________________________________________________________________

RX_PO:
        ; look for start bit "0" by looping while a "1" bit is seen
        ; a "1" is detected here if i/o reg parity is odd
        ; we use the accumulator to store the read byte

        in   f,(c)          ; 14
        jp   po,RX_PO       ; 11   LOOP=25
        ld   (hl),a         ;  8  = 33 CYCLES

        in   a,(c)          ; 14   Bit 0
        nop                 ;  5   in odd parity, accumulator is
                            ;      always in its final form
        rrca                ;  5
        dec  de             ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 1
        xor  b              ;  5
        rrca                ;  5
        inc  hl             ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 2
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 3
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 4
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 5
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 6
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 7
        xor  b              ;  5
        rrca                ;  5   accumulator has now the final
                            ;      received byte

        ; return if we received a '\r'
        cp   iyl            ;  5
        jp   nz,RX_PO       ; 11 | 14+5+5+5+11 = 40 CYCLES
                            ; we are now into the stop bit window
;________________________________________________________________________________________________________________________________

ReceiveOK:
        ld   (hl),a
        ld   sp,ix

        ld   a,1
        ret

;________________________________________________________________________________________________________________________________

RX_PE:
        ; look for start bit "0" by looping while a "1" bit is seen
        ; a "1" is detected here if i/o reg parity is even
        ; we use the accumulator to store the read byte

        in   f,(c)          ; 14
        jp   pe,RX_PE       ; 11   LOOP=25
        ld   (hl),a         ;  8 = 33 CYCLES

        in   a,(c)          ; 14   Bit 0
        cpl                 ;  5   in even parity, accumulator is
                            ;      in inverted form, compensate
        rrca                ;  5
        dec  de             ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 1
        xor  b              ;  5
        rrca                ;  5
        inc  hl             ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 2
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 3
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 4
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 5
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 6
        xor  b              ;  5
        rrca                ;  5
        ld   sp,hl          ;  7 = 31 CYCLES

        in   b,(c)          ; 14   Bit 7
        xor  b              ;  5
        rrca                ;  5   accumulator has now the final
                            ;      received byte

        ; return if we received a '\r'
        cp   iyl            ;  5
        jp   nz,RX_PE       ; 11 | 14+5+5+5+11 = 40 CYCLES
                            ; we are now into the stop bit window

        jr  ReceiveOK

tx_string: ; send a null terminated string
;********************************************************************************************************************************
; IN:  HL = DATA
;      BC = LENGTH
;********************************************************************************************************************************
        exx
        push bc
        push de
        exx

        call vJIOTransmit2

        exx
        pop  de
        pop  bc
        exx
        ret

vJIOTransmit2:
        ex   de,hl          ; HL contains now buffer address
        inc  bc             ; compensate for later BC-1 test
        exx                 ; BEGIN SHADOW
        ld   c,JIOREG       ; C contains the jiocart i/o register

        in   a,(c)          ; read the i/o register

        and  0xfb           ; unset only tx bit preserving all other bits

                            ; preserving CTS/ENA on jiocart,
                            ; allows using AT mode on HC-05
                            ; from the MSX itself, controlled by
                            ; software

                            ; tx bit (bit 2) is unset now
        ld   d,a            ; D contains i/o reg value for a "0" bit
        or   0x04           ; set tx bit (bit 2)
        ld   e,a            ; E contains i/o reg value for a "1" bit

        db   0x3e           ; 3e c0 is ld a,0xc0, which is a dummy
                            ; instruction that bypasses
                            ; the next "ret nz" when execution
                            ; flow goes through this path
JIOTransmitLoop:
        ret  nz             ; c0 as opcode, never triggers, 6 cycles
                            ; 14+11 (previous) + 6 = 31 cycles

        out  (c),e          ; send a "1" bit (idle / stop), 14 cycles
        exx                 ; END SHADOW, 5 cycles
        ld   a,(hl)         ; get one byte from buffer, 8 cycles
        cpi                 ; compare a to (hl), inc hl, dec bc, 18 cycles
                            ; this sets Z and defuses "ret nz" later
        ret  po             ; return if BC-1 is cero (po is P=0), 12/6
        exx                 ; BEGIN SHADOW, 5 cycles
        rrca                ; get one bit from the right, 5 cycles
                            ; 14+5+8+18+6+5+5 = 61 cycles

                            ; we spent nearly two bits here
                            ; but the receiver is supposed to be looking for
                            ; a new start bit, so in practice it's ok

        out  (c),d  ; =0    ; write a "0" bit (start), 14 cycles
        ret  nz             ; never triggers, 6 cycles
        jp   c,TRANSMIT10   ; if "1" go to transmit first "1",
                            ; 11 cycles | 14+6+11=31 CYCLES

        out  (c),d  ; -0    ; write the first "0" bit, 14 cycles
        rrca                ; get one bit from the right, 5 cycles
        jp   c,TRANSMIT11   ; if "1" go to transmit second "1",
                            ; 11 cycles = 14+5+11=30 CYCLES
;________________________________________________________________________________________________________________________________

TRANSMIT01:                     ; second "0"
        out  (c),d          ; -1 14
        rrca                ;     5
        jr   c,TRANSMIT12   ;    13/8
        nop                 ;     5 | 14+5+8+5 = 32 CYCLES

TRANSMIT02:                 ; third "0"
        out  (c),d          ; -0 14
        rrca                ;     5
        jp   c,TRANSMIT13   ;    11 | 14+5+11 = 30 CYCLES

TRANSMIT03:                 ; fourth "0"
        out  (c),d          ; -1 14
        rrca                ;     5
        jr   c,TRANSMIT14   ;    13/8
        nop                 ;     5 | 14+5+8+5 = 32 CYCLES

TRANSMIT04:                 ; fifth "0"
        out  (c),d          ; -0 14
        rrca                ;     5
        jp   c,TRANSMIT15   ;    11 | 14+5+11 = 30 CYCLES

TRANSMIT05:                 ; sixth "0"
        out  (c),d          ; -1 14
        rrca                ;     5
        jr   c,TRANSMIT16   ;    13/8
        nop                 ;     5 | 14+5+8+5 = 32 CYCLES

TRANSMIT06:                 ; seventh "0"
        out  (c),d          ; -0 14
        rrca                ;     5
        jp   c,TRANSMIT17   ;    11 | 14+5+11 = 30 CYCLES

TRANSMIT07:                 ; eighth "0"
        out  (c),d          ; -1 14
        jp   JIOTransmitLoop ;    11 | 14+11 = 25 CYCLES
;________________________________________________________________________________________________________________________________

TRANSMIT10:                 ; first "1"
        out  (c),e          ; -0 14
        rrca                ;     5
        jp   nc,TRANSMIT01  ;    11 | 14+5+11 = 30 CYCLES

TRANSMIT11:                 ; second "1"
        out  (c),e          ; -1 14
        rrca                ;     5
        jr   nc,TRANSMIT02  ;    13/8
        nop                 ;     5 | 14+5+8+5 = 32 CYCLES

TRANSMIT12:                 ; third "1"
        out  (c),e          ; -0 14
        rrca                ;     5
        jp   nc,TRANSMIT03  ;    11 | 14+5+11 = 30 CYCLES

TRANSMIT13:                 ; fourth "1"
        out  (c),e          ; -1 14
        rrca                ;     5
        jr   nc,TRANSMIT04  ;    13/8
        nop                 ;     5 | 14+5+8+5 = 32 CYCLES

TRANSMIT14:                 ; fifth "1"
        out  (c),e          ; -0 14
        rrca                ;     5
        jp   nc,TRANSMIT05  ;    11 | 14+5+11 = 30 CYCLES

TRANSMIT15:                 ; sixth "1"
        out  (c),e          ; -1 14
        rrca                ;     5
        jr   nc,TRANSMIT06  ;    13/8
        nop                 ;     5 | 14+5+8+5 = 32 CYCLES

TRANSMIT16:                 ; seventh "1"
        out  (c),e          ; -0 14
        rrca                ;     5
        jp   nc,TRANSMIT07  ;    11 | 14+5+11 = 30 CYCLES

TRANSMIT17:                 ; eighth "1"
        out  (c),e          ; -1 14
        jp   JIOTransmitLoop ;    11 | 14+11 = 25 CYCLES

;********************************************************************************************************************************

CHPUTS:
        LD   A,(HL)
        OR   A
        RET  z
        PUSH HL
        CALL CHPUT
        POP  HL
        INC  HL
        JR   CHPUTS

save_cpu_mode: ;  save cpu mode if turbo R
        LD   A,(MSXVER)     ; MSX version number
        CP   3              ; 3 is MSX turbo R
        RET  c              ; return if not
        CALL GETCPU
        LD   (cpu_mode),A   ; save CPU mode
        RET

restore_cpu_mode: ; restore CPU mode if turbo R
        LD   A,(MSXVER)     ; MSX version number
        CP   3              ; 3 is MSX turbo R
        RET  c              ; return if not
        LD   A,(cpu_mode)   ; load saved cpu mode
        JP   CHGCPU

set_z80_mode: ; set Z80 mode for turbo R
        LD   A,(MSXVER)     ; MSX version number
        CP   3              ; 3 is MSX turbo R
        RET  c              ; return if not
        LD   A,0x80         ; set Z80 mode and
                            ; turn led accordingly
        JP   CHGCPU

cpu_mode:
        db 0

cr_lf:
        db "\r\n\0"

banner:
        db 0x0c
        db "JSM - JIO 38400 bauds Serial Monitor v1.0ahm\r\n"
        db "Originally coded by Louthrax\r\n"
        db "Modified by ahmsx for 115200 bauds\r\n"
        db "115200 bauds routines by Nyyrikki\r\n"
        db "Enter your commands and validate with [RETURN]\r\n"
        db "Press [CTRL] to unlock reception\r\n"
        db "Press [CTRL] + [C] to exit\r\n"
        db "Useful commands:\r\n"
        db "  Display current UART mode: AT+UART?\r\n"
        db "  Set UART mode for JIO:     AT+UART=115200,0,0\r\n"
        db "  Set device name:           AT+NAME=xxxxx\r\n"
        db "-----------------------------------------\r\n\0"

recvbuf:
        ds 256

endadr:
