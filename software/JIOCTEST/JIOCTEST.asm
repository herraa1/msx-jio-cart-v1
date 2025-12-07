; JIOCTEST.asm

CHPUT:	equ 0x00A2

    org 0xc800-7

; bload header
db 0xFE
dw start, endadr, start

start:

; print program banner
    LD      HL, banner	; address of program banner
    CALL    CHPUTS		; print null terminated program banner

    ld      b,3
    ld      hl,probe_ports
    call    probe_list_of_ports
    jr      z,@found

    ld      hl,msg_jiocart_not_found
    call    CHPUTS
    jr      @bye

@found:
    ld      c,a
    ld      hl,msg_jiocart_found
    call    CHPUTS
    ld      a,c
    call    print_hex
    ld      hl,cr_lf
    call    CHPUTS

@bye:
    ret

;;
; Probes a list of I/O ports looking for a jiocart.
; Inputs:
;   HL = address of byte array containing all ports
;        to be probed
;   B  = count of ports to be probed
; Outputs:
;   NZ when jiocart was not found
;   Z when jiocart was found
;   A <- port where jiocart was found when flag Z set
probe_list_of_ports:
    ld      a,(hl)
    call    probe_one_port
    jr      z,@found
    inc     hl
    djnz    probe_list_of_ports
    ld      a,0xf0
    xor     0x0f
@found:
    ret

;;
; Probes an I/O port looking for a jiocart
; Inputs:
;   A = port to probe
; Outputs:
;   flag Z set (Z) when jiocart found
;   flag Z not set (NZ) when jiocart not found
probe_one_port:
    push    bc
    ld      c,a
    ld      a,0xf7
    out     (c),a
    in      a,(c)
    and     0xfc
    cp      0x44
    jnz     @not_this_port
    ld      a,0xdb
    out     (c),a
    in      a,(c)
    and     0xfc
    cp      0x88
    jnz     @not_this_port
    ld      a,0x2f
    out     (c),a
    in      a,(c)
    and     0xfc
    cp      0xcc
@not_this_port:
    ld      a,c
    pop     bc
    ret

;;
; Print the number in A as an hexdecimal number
; Inputs:
;   A = nuber to print
print_hex:
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

CHPUTS:
    LD      A,(HL)
    OR      A
    RET     z
    PUSH    HL
    CALL    CHPUT
    POP     HL
    INC     HL
    JR      CHPUTS

cr_lf:
    db "\r\n\0"

banner:
    db 0x0c
    db "JIOCTEST - JIOCART probe test v0.1ahm\r\n"
    db 0x00

msg_jiocart_found:
    db "JIOCART found at 0x"
    db 0x00

msg_jiocart_not_found:
    db "JIOCART NOT found!"
    db 0x00

probe_ports:
    db 0x00,0x20,0x30

endadr:
