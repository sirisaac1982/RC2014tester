; tester.asm --- memory test and diagnostics for RC2014 Mini   2017-03-08  
; Copyright (c) 2017 John Honniball
;
; http://rc2014.co.uk

            section INIT
            module Tester

            defc INITSTACK=0ffffh
            
            defc ROMBASE=0000h
            defc ROMSIZE=8192
            
            defc RAMBASE=8000h
            defc RAMSIZE=32768
            
            defc ACIAS=80h      ; 6850 ACIA status register
            defc ACIAD=81h      ; 6850 ACIA data register
            
            defc CR=0Dh
            defc LF=0Ah
            defc SPACE=20h
            defc EOS=0
            
            org 0000h           ; EPROM (27C512) starts at 0x0000

RST00:      di                  ; Disable interrupts
            im 1                ; Select interrupt mode 1, jump to 0038h
            ld sp,INITSTACK     ; Initialise stack
            jr mcinit

RST08:      jp (hl)
            nop
            nop
            nop
            nop
            nop
            nop
            nop

RST10:      jp (hl)
            nop
            nop
            nop
            nop
            nop
            nop
            nop

RST18:      jp (hl)
            nop
            nop
            nop
            nop
            nop
            nop
            nop

RST20:      jp (hl)
            nop
            nop
            nop
            nop
            nop
            nop
            nop

RST28:      jp (hl)
            nop
            nop
            nop
            nop
            nop
            nop
            nop

RST30:      jp (hl)
            nop
            nop
            nop
            nop
            nop
            nop
            nop

RST38:      reti                ; Interrupt mode 1 address. Ignore and return

mcinit:     ld a,$03            ; Reset 6850 ACIA
            out (ACIAS),a
            ld a,$96            ; Initialise ACIA to divide-by-64
            out (ACIAS),a

setup:      ld hl,signon        ; Print sign-on message
            ld iy,ASMPC+7
            jp puts_iy
            
loop:       ld hl,hello
            ld iy,ASMPC+7
            jp puts_iy
            
            ld hl,ASMPC+6       ; Get a character from the ACIA
            jp t1in_hl
            
            ld hl,ASMPC+6       ; Print it in hex              
            jp hex2out_hl
            
            ld b,CR             ; Print CR/LF
            ld hl,ASMPC+6
            jp t1ou_hl
            
            ld b,LF
            ld hl,ASMPC+6
            jp t1ou_hl
            
            ld hl,chkmsg        ; Print EPROM checksum message
            ld iy,ASMPC+7
            jp puts_iy
            
            ld ix,ROMBASE       ; Initialise EPROM pointer
            ld bc,ROMSIZE       ; Initialise loop counter
            ld hl,0             ; Checksum accumulates in HL
            ld de,0             ; Bytes will get loaded into E
romchk:     ld e,(ix)           ; Load a ROM byte
            add hl,de           ; Add to total in HL
            inc ix              ; Next byte
            dec c               ; Byte counter LO
            jr nz,romchk        ; Is C zero?
            djnz romchk         ; Byte counter HI

            ld ix,ASMPC+7       ; We're done; checksum is in HL
            jp hex4out_ix

            ld b,CR
            ld hl,ASMPC+6
            jp t1ou_hl
            
            ld b,LF
            ld hl,ASMPC+6
            jp t1ou_hl
            
            ld hl,ramsz         ; Print RAM size message
            ld iy,ASMPC+7
            jp puts_iy
            
            ld ix,RAMBASE       ; Initialise RAM pointer
            ld bc,RAMSIZE       ; Initialise loop counter
            ld hl,0             ; HL counts good bytes
            ld de,0aa55h        ; Two test bytes
ramchk:     ld (ix),d           ; Store a byte in RAM
            ld (ix),e           ; Store a byte in RAM
            ld a,(ix)           ; Read it back
            cp a,e              ; Read OK?
            jr nz,notok
            inc hl              ; One more good byte
notok:      inc ix              ; Next byte
            ld a,0              ; Zero in A for comparisons
            dec bc              ; Byte counter
            cp a,c              ; Is C zero?
            jr nz,ramchk
            cp a,b              ; Is B zero?
            jr nz,ramchk

            ld ix,ASMPC+7       ; We're done; size is in HL
            jp hex4out_ix

            ld b,CR             ; CR/LF
            ld hl,ASMPC+6
            jp t1ou_hl
            
            ld b,LF
            ld hl,ASMPC+6
            jp t1ou_hl
            
            jp loop
            
; t1ou_hl
; Transmit one character via the 6850 ACIA, no stack
; Entry: character in B, return link in HL
; Exit: A now holds character, B unchanged
t1ou_hl:    in a,(ACIAS)        ; Read ACIA status register
            bit 1,a             ; Check status bit
            jr z,t1ou_hl        ; Loop and wait if busy
            ld a,b              ; Move char into A
            out (ACIAD),a       ; Send A to ACIA
            jp (hl)             ; Return via link in HL

; t1ou_iy
; Transmit one character via the 6850 ACIA, no stack
; Entry: character in B, return link in IY
; Exit: A now holds character, B unchanged
t1ou_iy:    in a,(ACIAS)        ; Read ACIA status register
            bit 1,a             ; Check status bit
            jr z,t1ou_iy        ; Loop and wait if busy
            ld a,b              ; Move char into A
            out (ACIAD),a       ; Send A to ACIA
            jp (iy)             ; Return via link in IY

; puts_hl
; Transmit a string of characters, terminated by zero, no stack
; Entry: IY points to string, return link in HL
; Exit: IY points to zero terminator, A and B changed
puts_hl:    ld a,(iy)           ; Load char pointed to by IY
            cp 0
            jr z,p1done         ; Found zero, end of string
            inc iy
            ld b,a
p1txpoll:   in a,(ACIAS)        ; Read ACIA status register
            bit 1,a             ; Check status bit
            jr z,p1txpoll       ; Loop and wait if busy
            ld a,b              ; Move char into A
            out (ACIAD),a       ; Send A to ACIA
            jr puts_hl
p1done:     jp (hl)             ; Return via link in HL

; puts_iy
; Transmit a string of characters, terminated by zero, no stack
; Entry: HL points to string, return link in IY
; Exit: HL points to zero terminator, A and B changed
puts_iy:    ld a,(hl)           ; Load char pointed to by HL
            cp 0
            jr z,p_done         ; Found zero, end of string
            inc hl
            ld b,a
p_txpoll:   in a,(ACIAS)        ; Read ACIA status register
            bit 1,a             ; Check status bit
            jr z,p_txpoll       ; Loop and wait if busy
            ld a,b              ; Move char into A
            out (ACIAD),a       ; Send A to ACIA
            jr puts_iy
p_done:     jp (iy)             ; Return via link in IY

; t1in_iy
; Read one character from the 6850 ACIA, no stack
; Entry: return link in IY
; Exit: character in A
t1in_iy:    in a,(ACIAS)        ; Read status reg
            bit 0,a
            jr z,t1in_iy
            in a,(ACIAD)        ; Get the character from the data reg
            jp (iy)             ; Return via link in IY

; t1in_hl
; Read one character from the 6850 ACIA, no stack
; Entry: return link in HL
; Exit: character in A
t1in_hl:    in a,(ACIAS)        ; Read status reg
            bit 0,a
            jr z,t1in_hl
            in a,(ACIAD)        ; Get the character from the data reg
            jp (hl)             ; Return via link in HL

; hex2out_hl
; Print A as two-digit hex
; Entry: A contains number to be printed, return link in HL
; Exit: A, B, C, IY modified
hex2out_hl: ld c,a
            srl a
            srl a
            srl a
            srl a
            cp a,10
            jp m,h1digit
            add a,7
h1digit:    add a,30h
            ld b,a
            ld iy,ASMPC+7
            jp t1ou_iy
            ld a,c
            and a,0fh
            cp a,10
            jp m,h2digit
            add a,7
h2digit:    add a,30h
            ld b,a
            ld iy,ASMPC+7
            jp t1ou_iy          
            jp (hl)             ; Return via link in HL

; hex4out_ix
; Print HL as four-digit hex
; Entry: HL contains number to be printed, return link in IX
; Exit: A, B, IY modified
hex4out_ix: ld a,h
            srl a
            srl a
            srl a
            srl a
            cp a,10
            jp m,h3digit
            add a,7
h3digit:    add a,30h
            ld b,a
            ld iy,ASMPC+7
            jp t1ou_iy
            ld a,h
            and a,0fh
            cp a,10
            jp m,h4digit
            add a,7
h4digit:    add a,30h
            ld b,a
            ld iy,ASMPC+7
            jp t1ou_iy
            ld a,l              ; And again with the low half
            srl a
            srl a
            srl a
            srl a
            cp a,10
            jp m,h5digit
            add a,7
h5digit:    add a,30h
            ld b,a
            ld iy,ASMPC+7
            jp t1ou_iy
            ld a,l
            and a,0fh
            cp a,10
            jp m,h6digit
            add a,7
h6digit:    add a,30h
            ld b,a
            ld iy,ASMPC+7
            jp t1ou_iy
            jp (ix)             ; Return via link in IX

; Testing assembler directives
            defb  $42
            defw  $babe
;           defl  $deadbeef
hello:      defm  "Hello, world", CR, LF, EOS
signon:     defm  "RC2014 Memory Test and Diagnostics ROM", CR, LF
            defm  "V1.00 2017-03-08", CR, LF, EOS
chkmsg:     defm  "EPROM checksum is ", EOS
ramsz:      defm  "RAM size is ", EOS
            defs  0400h-ASMPC,0ffh
            defw  $0400,$0402,$0404,$0406,$0408,$040A,$040C,$040E
            defw  $0410,$0412,$0414,$0416,$0418,$041A,$041C,$041E
            defw  $0420,$0422,$0424,$0426,$0428,$042A,$042C,$042E
            defw  $0430,$0432,$0434,$0436,$0438,$043A,$043C,$043E
            defs  0800h-ASMPC,0ffh
            defw  $0800,$0802,$0804,$0806,$0808,$080A,$080C,$080E
            defw  $0810,$0812,$0814,$0816,$0818,$081A,$081C,$081E
            defw  $0820,$0822,$0824,$0826,$0828,$082A,$082C,$082E
            defw  $0830,$0832,$0834,$0836,$0838,$083A,$083C,$083E
            defs  1000h-ASMPC,0ffh
            defw  $1000,$1002,$1004,$1006,$1008,$100A,$100C,$100E
            defw  $1010,$1012,$1014,$1016,$1018,$101A,$101C,$101E
            defw  $1020,$1022,$1024,$1026,$1028,$102A,$102C,$102E
            defw  $1030,$1032,$1034,$1036,$1038,$103A,$103C,$103E
            defs  2000h-ASMPC,0ffh
