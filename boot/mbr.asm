; Loaded at 0x7C00
; DL contains drive number MBR was loaded from
;
; Need to relocate away from 0x7C00
; Determine which partition to boot
; Use BIOS INT 13h commands to load the VBR to 0x7C00
; Set DS:SI to point to the partition table entry
; Jump to 0000:7C00 (CS:IP), with DL set to drive number
;
; Based on MS Win2K master boot record
;

%define newaddr  0x0600
%define origaddr 0x7C00
%define stacktop 0x7C00
%define relocated(x) (x - (origaddr - newaddr))

                bits    16
                cpu     386
                org     origaddr
section .text
xstart:
                xor     ax, ax          ; Zero segment regs
                mov     ss, ax
                mov     sp, stacktop    ; Interrupts can be enabled once
                sti                     ; stack is defined.
                mov     es, ax
                mov     ds, ax
                mov     si, xstart      ; Copy from.
                mov     di, newaddr     ; Copy to 0000:0600
                cld
                mov     cx, 256
                rep movsw               ; move 256 words (512 bytes)
                jmp     0x0000:relocated(continue)

                ; We're now relocated from 0x07C00 to 0x00600
continue:
scanpartitions:
                mov     bp, relocated(pe1)
                mov     cl, 4
scanpartition:
                cmp     [bp], ch        ; ch = 0 from above
                jl      foundbootable
                jnz     invalidentry
                add     bp, 0x10
                loop    scanpartition
                int     0x18

invalidentry:
                mov     ax, relocated(msg1)
print:
                mov     si, ax
.loadchar:
                lodsb
.hang:
                cmp     al, 0
                jz      .hang
                mov     bx, 0x0007
                mov     ah, 0x0e
                int     0x10
                jmp     .loadchar

foundbootable:
                mov     [bp + 0x10], cl         ; save partition number
                call    loadsector              ; load 1st sector into memory
                jnb     checkmagic
                inc     byte [bp + 0x10]
                cmp     byte [bp + 0x04], 0x0B
                jz      .altload
                cmp     byte [bp + 0x04], 0x0C
                jz      .altload

                mov     ax, relocated(msg2)
                jnz     print

.altload:
                add     byte [bp+0x02], 0x06
                add     word [bp+0x08], 0x06
                adc     word [bp+0x0a], 0x00
                call    loadsector
                jnb     checkmagic
                mov     ax, relocated(msg2)
                jmp     print

checkmagic:
                cmp     word [0x7dfe], 0xaa55
                jz      vbrjump
.bados:
                mov     ax, relocated(msg3)
                jmp     print

vbrjump:
                mov     di, sp                  ; sp is still 0x7c00
                push    ds                      ; 0x0000
                push    di                      ; 0x7C00
                mov     si, bp                  ; Partition table entry
                retf                            ; Jump to VBR

loadsector:
                mov     di, 0x0005
                mov     dl, [bp+0]              ; 80 -> DL (hdd)
                mov     ah, 0x08
                int     0x13                    ; Get drive params
                jb      .stdint13               ; Couldn't get, just use std int13

                mov     al, cl
                and     al, 0x3f                ; Max Sectors
                cbw
                mov     bl, dh                  ; Max Head value
                mov     bh, ah                  ; zero
                inc     bx                      ; Max heads = max head value + 1
                mul     bx                      ; max sectors per cylinder -> AX
                mov     dx, cx
                xchg    dl, dh
                mov     cl, 6
                shr     dh, cl
                inc     dx
                mul     dx                      ; dx:ax = sectors in the disk
                cmp     [bp + 0x0a], dx
                ja      .extint13               ; we need to use ext int13
                jb      .stdint13
                cmp     [bp + 0x08], ax
                jnb     .extint13               ; we need to use ext int13
.stdint13:
                mov     ax, 0x0201
                mov     bx, 0x7c00
                mov     cx, [bp + 0x02]
                mov     dx, [bp + 0x00]
                int     0x13
                jnb     .loaddone
                dec     di
                jz      .loaddone
.reset:
                xor     ah, ah
                mov     dl, [bp + 0x00]
                int     0x13
                jmp     .stdint13
.extint13:
                mov     dl, [bp + 0x00]
                pusha
                mov     bx, 0x55aa
                mov     ah, 0x41
                int     0x13
                jb      .loadfail
                cmp     bx, 0xaa55
                jnz     .loadfail
                test    cl, 1
                jz      .loadfail
                popa
.retry:
                pusha
                push    0x0000
                push    0x0000
                push    word[bp + 0x0a]
                push    word[bp + 0x08]
                push    0x0000
                push    0x7C00
                push    0x0001
                push    0x0010
                mov     ah, 0x42
                mov     si, sp
                int     0x13
                popa
                popa
                jnb     .loaddone
                dec     di
                jz      .loaddone
                xor     ah, ah
                mov     dl, [bp + 0x0000]
                int     0x13
                jmp     .retry
.loadfail:
                popa
                stc
.loaddone:
                ret
msg1:
                db "Invalid partition table", 0
msg2:
                db "Error loading operating system", 0
msg3:
                db "Missing operating system", 0
                times 0x1BE-($-xstart) db 0
pe1:                                    ; partition entry 1
                db 0x80
                db 1, 1, 0
                db 6
                db 0x3f, 0x3f, 0xc4
                dd 63
                dd 0x0c1e81
pe2:            times 16 db 0           ; partition entry 2
pe3:            times 16 db 0           ; partition entry 3
pe4:            times 16 db 0           ; partition entry 4
mbrsig:         db      0x55            ; MBR Signature
                db      0xAA
