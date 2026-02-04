; JIOC38K.asm
;
; Super-simple serial terminal suitable to re-configure the HC-05
; bluetooth module within a msx-jio-cart using 38400 bps in AT mode from
; the MSX itself.
;
; Based on jsm.as from the MSXJIO project by Louthrax
; See https://github.com/louthrax/MSXJIO
;
; Released under
; Attribution-NonCommercial-ShareAlike 4.0 International
; license like the original jsm.as
;
; Modified by Albert Herranz for 38400/jiocart
; See https://github.com/herraa1/msx-jio-cart-v1
;

; Original 38400 bauds communication routine used by JIO Serial Monitor tool by Tiny Yarou

MSXVER                          equ                             0x002D
INLIN                           equ                             0x00B1
CHPUT                           equ                             0x00A2

CHGCPU                          equ                             0x0180
;Function : Changes CPU mode
;Input    : A = LED 0 0 0 0 0 x x
;                |            0 0 = Z80 (ROM) mode
;                |            0 1 = R800 ROM  mode
;                |            1 0 = R800 DRAM mode
;               LED indicates whether the Turbo LED is switched with the CPU
;Output   : none
;Registers: none


GETCPU                          equ                             0x0183
;Function : Returns current CPU mode
;Input    : none
;Output   : A = 0 0 0 0 0 0 x x
;                           0 0 = Z80 (ROM) mode
;                           0 1 = R800 ROM  mode
;                           1 0 = R800 DRAM mode
;Registers: AF

;##############################################################################

                                org                             0xC800-7

                                defb                            0xFE
                                defw                            BIN_Start
                                defw                            BIN_End
                                defw                            BIN_Start

;##############################################################################

BIN_Start:
                                ld                              hl,msg_welcome
                                call                            PrintString

                                call                            JioDetect
                                ld                              a,(JioPort)
                                cp                              0xff
                                jr                              nz,PrintJioAddress
                                ld                              hl,msg_jiocart_not_found
                                call                            PrintString
                                ret

PrintJioAddress:
                                ld                              c,a
                                ld                              hl,msg_jiocart_found
                                call                            PrintString
                                ld                              a,c
                                call                            PrintHex
                                ld                              hl,CRLF
                                call                            PrintString

                                ld                              hl,msg_usage
                                call                            PrintString

                                ld                              a,(JioPort)
                                ld                              (_fixup1),a
                                ld                              (_fixup2),a
                                ld                              (_fixup3),a
                                ld                              (_fixup4),a
                                ld                              (_fixup5),a

                                call                            GetInitialCPUMode


UserLoop:                       call                            INLIN
                                ret                             c

                                push                            hl

SearchEnd:                      inc                             hl
                                ld                              a,(hl)
                                or                              a
                                jr                              nz,SearchEnd

                                ld                              (hl),13
                                inc                             hl
                                ld                              (hl),10
                                inc                             hl
                                ld                              (hl),0

                                pop                             hl
                                inc                             hl
;______________________________________________________________________________

                                call                            SetZ80CPUMode

                                di

                                call                            SendString

CtrlNotPressed:                 ld                              hl,g_acReceivedMessage
                                call                            ReceiveString
                                ld                              (hl),0
                                jr                              z,NoInterrupted

                                in                              a,(c)
                                bit                             1,a
                                jr                              nz,CtrlNotPressed

NoInterrupted:                  ei

                                call                            RestoreCPUMode
;______________________________________________________________________________

                                ld                              hl,g_acReceivedMessage
                                call                            PrintString

                                ld                              hl,CRLF
                                call                            PrintString
                                ld                              hl,CRLF
                                call                            PrintString

                                jr                              UserLoop

;##############################################################################

PrintString:                    ld                              a,(hl)
                                or                              a
                                ret                             z
                                push                            hl
                                call                            CHPUT
                                pop                             hl
                                inc                             hl
                                jr                              PrintString

;##############################################################################

; for 38400 bps we need to spend ~93 cycles between each serial bit
; using a standard MSX z80 clock
;
; 3579545 Hz / 38400 bauds = ~93.21 cpu cycles

ReceiveString:
                                in a,(0xAA)
                                and 0xF0
                                add a,6
                                out (0xAA),a

                                ld c,0xA9

ReceiveCharacterLoop:           in f,(c)                           ; 14 cycles ; check if key pressed
                                ret po                             ;  6 cycles / 12 cycles

                                db 0xdb
_fixup1:
                                db 0x30
                                ; in a,(0x30)                       ; 12 cycles ; wait for start bit
                                rrca                               ;  5 cycles
                                jr c,ReceiveCharacterLoop          ;  8 cycles / 13 cycles

                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles
                                nop                                ;  5 cycles

                                ld d,0                             ;  8 cycles
                                ld b,8                             ;  8 cycles
                                                                               ; 12+5+8+15*5+8+8=116 cycles since start bit read

ReceiveBitLoop:
                                db 0xdb
_fixup2:
                                db 0x30
                                ; in a,(0x30)                        ; 12 cycles ; receive 1 data bit
                                rrca                               ;  5 cycles
                                rr d                               ; 10 cycles

                                ld a,2                             ;  8 cycles
ReceiveBitDelay:                dec a                              ;  5 cycles
                                nop                                ;  5 cycles
                                jr nz,ReceiveBitDelay              ;  8 cycles / 13 cycles

                                djnz ReceiveBitLoop                ;  9 cycles / 14 cycles
                                                                               ; 12+5+10+8+5+5+13+5+5+8+14 = 90 cycles per data bit

                                ld a,d                             ;  5 cycles
                                cp 0x0D                            ;  8 cycles ; check if CR received
                                ret z                              ;  6 cycles / 12 cycles
                                                                               ; 5+8+6=19 cycles extra for bit 8

WaitTransmissionEnd:
                                db 0xdb
_fixup3:
                                db 0x30
                                ; in a,(0x30)                        ; 12 cycles ; wait for stop bit
                                rrca                               ;  5 cycles
                                jr nc,WaitTransmissionEnd          ;  8 cycles / 13 cycles

                                ld (hl),d                          ;  8 cycles
                                inc hl                             ;  7 cycles

                                jp ReceiveCharacterLoop            ; 11 cycles
                                                                               ; 12+5+8+8+7+11=51 cycles after stop bit

;##############################################################################

SendString:                     ld a,(hl)
                                or a
                                ret z
                                call SendCharacter
                                inc hl
                                jr SendString

;______________________________________________________________________________

SendCharacter:                  push hl

                                ld l,a                             ; data bits in reg L
                                ld h,0xFF                          ; stop bit at bit 0 of reg H
                                and a                              ; zero carry, carry will be start bit
                                rl l                               ; put start bit first in xmit word
                                rl h

                                ld b,11                            ; 1 start bit + 8 data bits + 2? stop bits

SendBitLoop:
                                db 0xdb
_fixup4:
                                db 0x30
                                ; in a,(0x30)                        ; 12 cycles
                                rr h                               ; 10 cycles
                                rr l                               ; 10 cycles
                                jr nc,l4a70h                       ;  8 cycles / 13 cycles
                                set 2,a                            ; 10 cycles
                                jr l4a74h                          ; 13 cycles

l4a70h:                         res 2,a                            ; 10 cycles
                                jr l4a74h                          ; 13 cycles

l4a74h:
                                db 0xd3
_fixup5:
                                db 0x30
                                ; out (0x30),a                       ; 12 cycles
                                djnz SendBitLoop                   ;  9 cycles / 14 cycles
                                                                               ; 12+10+10+8+10+13+12+14=89 cycles bit "1"
                                                                               ; 12+10+10+13+10+13+12+14=94 cycles bit "0"

                                pop hl
                                ret

;##############################################################################

GetInitialCPUMode:              ld                              a,(MSXVER)
                                cp                              3
                                ret                             c
                                
                                call                            GETCPU
                                ld                              (InitialCPUMode),a
                                ret

;##############################################################################

RestoreCPUMode:                 ld                              a,(MSXVER)
                                cp                              3
                                ret                             c
                                
                                ld                              a,(InitialCPUMode)
                                jp                              CHGCPU

;##############################################################################

SetZ80CPUMode:                  ld                              a,(MSXVER)
                                cp                              3
                                ret                             c
                                
                                ld                              a,0x80
                                jp                              CHGCPU

InitialCPUMode:                 defb                            0

;##############################################################################

JIOPORT_ADDRESS                 equ                             0xFF

;;
;
;
JioDetect:
                                ld                              hl,JioPorts

;;
; Probe for a msx-jio-cart
; Inputs:
;   HL = 0xff terminated array of ports to probe
JioProbe:
                                ld                              a,(hl)
                                ld                              (JioPort),a
                                cp                              0xff
                                ret                             z
                                call                            JioProbePort
                                ret                             z
                                inc                             hl
                                jr                              JioProbe

JioProbePort:
                                ld                              c,a
                                ld                              a,0x2f
                                out                             (c),a
                                in                              a,(c)
                                and                             0xfc
                                cp                              0xcc
                                ret                             nz
                                ld                              a,0xdb
                                out                             (c),a
                                in                              a,(c)
                                and                             0xfc
                                cp                              0x88
                                ret                             nz
                                ld                              a,0xf7
                                out                             (c),a
                                in                              a,(c)
                                and                             0xfc
                                cp                              0x44
                                ret

; List of ports that are probed, end with $ff
JioPorts:                       db                              0x00,0x20,0x30,0xff
JioPort:                        db                              JIOPORT_ADDRESS

;;
; Print the number in A as an hexadecimal number
; Inputs:
;   A = number to print
PrintHex:
                                ld      c,a
                                call    @digit1
                                call    CHPUT
                                ld      a, c
                                call    @digit2
                                call    CHPUT
                                ret
@digit1:
                                rra
                                rra
                                rra
                                rra
@digit2:
                                or      0xf0
                                daa
                                add     a,0xa0
                                adc     a,0x40 ; Ascii hex at this point (0 to F)   
                                ret

;##############################################################################

CRLF:                           defb                            13,10,0

msg_welcome:                    defb                            12
                                defm                            "JIOC38K - JIOCART 38400 bauds tool v1",13,10
                                defm                            "Based on JSM v1.0 tool by Louthrax",13,10
                                defm                            "Adapted by Albert Herranz for JIOCART",13,10
                                defm                            "38400 bauds routines by Tiny Yarou",13,10
                                defm                            13,10,0

msg_usage:                      defm                            "Enter your commands then hit [RETURN]",13,10
                                defm                            "Press [CTRL] to unlock reception",13,10
                                defm                            "Press [CTRL] + [C] to exit",13,10
                                defm                            13,10
                                defm                            "Useful commands:",13,10
                                defm                            "  Display current UART mode: AT+UART?",13,10
                                defm                            "  Set UART mode for JIO:     AT+UART=115200,0,0",13,10
                                defm                            "  Set device name:           AT+NAME=xxx",13,10
                                defm                            "-------------------------------------",13,10,0

msg_jiocart_found:
                                defm "JIOCART found at 0x",0

msg_jiocart_not_found:
                                defm "JIOCART NOT found!",0

;##############################################################################

BIN_End:

;##############################################################################

g_acReceivedMessage:
