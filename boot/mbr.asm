; Loaded at 0x7C00
; DL contains drive number MBR was loaded from
;
; Need to relocate away from 0x7C00
; Determine which partition to boot
; Use BIOS INT 13h commands to load the VBR to 0x7C00
; Set DS:SI to point to the partition table entry
; Jump to 0000:7C00 (CS:IP), with DL set to drive number
;
                bits    16
                cpu     386
                org     0x7C00
section .text
xstart:
                jmp     0x0000:start
start:
                xor     ax, ax
                mov     es, ax
                mov     ds, ax
                mov     ss, ax
                mov     sp, 0x7A00      ; stack top is 0000:7A00
                mov     di, sp          ; we'll relocate to 0000:7A00
                mov     si, xstart
                cld
                mov     cx, 256
                rep movsw               ; move 256 words (512 bytes)
                jmp     0x0000:(continue-0x0200)
continue:
                mov     si, message
print:
                lodsb
                cmp     al, 0
                je      hang

                mov     ah, 0x0E
                mov     bx, 7
                int     0x10
                jmp     print
hang:
                hlt
                jmp     hang

message:
                db 'Hello World!'

padding:                                ; pad up to 0x1BE
                times 0x1BE-($-xstart) db 0
pe1:            resb    16              ; partition entry 1
pe2:            resb    16              ; partition entry 2
pe3:            resb    16              ; partition entry 3
pe4:            resb    16              ; partition entry 4
mbrsig:         db      0x55            ; MBR Signature
                db      0xAA
