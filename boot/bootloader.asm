[org 0x7c00]
bits 16
 
jmp short start
nop

; jump over OEM block

;-------------------------------------------------
;	OEM Parameter block
;-------------------------------------------------

bpbOEM                  DB "MSWIN4.1"
bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs: 	    DB 2
bpbRootEntries: 	    DW 224
bpbTotalSectors: 	    DW 2880
bpbMedia: 	            DB 0xF0
bpbSectorsPerFAT: 	    DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
bpbHiddenSectors: 	    DD 0
bpbTotalSectorsBig:     DD 0
bsDriveNumber: 	        DB 0
bsUnused: 	            DB 0
bsExtBootSignature: 	DB 0x29
bsSerialNumber:	        DD 0xa0a1a2a3
bsVolumeLabel: 	        DB "nobotro os "
bsFileSystem: 	        DB "FAT12   "

start:
    jmp main

puts:
    push si
    push ax
    push bx

.loop:
    lodsb               ; loads next character in al
    or al, al           ; verify if next character is null?
    jz .done

    mov ah, 0x0E        ; call bios interrupt
    mov bh, 0           ; set page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si    
    ret

; ------------------------
; Disk routines
; ------------------------
; Parameters:
;    - ax: LBA Address
;    - cx: number of sectors
;    - dl: drive number
;    - es:bx: store address
; ------------------------

disk_read:
    push ax
    mov [dap_lba], ax      ; lower 16 bits of LBA
    xor ax, ax
    mov [dap_lba + 2], ax  ; upper 16 bits of lower dword (set to 0)

    mov word [dap + 4], bx
    mov word [dap + 6], es

    mov byte [dap], 0x10       ; size of DAP
    mov byte [dap + 1], 0x00   ; reserved
    mov word [dap + 2], cx      ; number of sectors
    ;call lba_to_chs                     ; compute CHS
    pop ax                              ; AL = number of sectors to read
    
    mov ah, 42h
    mov si, dap
    int 13h                             ; carry flag cleared = success

    ; Checking carry? Apparently it is always returing error event thought it is
    ; working. Docs also recommends that we should retry at least 3 times before
    ; failing when there is disk error

    ret

check_LBA:
    push ax
    push bx
    push cx
    mov ah, 0x41
    stc
    int 13h
    jnc .present
    
    mov si, msg_lba_not_present
    call puts
    cli
    hlt

.present:
    pop cx
    pop bx
    pop ax
    ret

disk_reset:
    pusha

    mov ah, 0
    stc
    int 13h
    ;jc floppy_error
    popa
    ret


load_kernel_data:
    pusha
    mov ax, 0x0
    mov es, ax      ; ES = 0
    mov bx, 0x1000  ; BX = 0x1000. ES:BX=0x0:0x1000 
    ; ES:BX = starting address to read sector(s) into
    mov ax, 1
    mov cl, 15
    call disk_read
    popa

    ret

main:
    MOV EBP, 0x7c00         ; Set stack base at top of free space
    MOV ESP, EBP

    ; DL hasn't been destroyed by our bootloader code and still
    ;     contains boot drive # passed to our bootloader by the BIOS
    mov [bsDriveNumber], dl ; dl has been set by bios

    call check_LBA 
    call disk_reset

    call load_kernel_data
    jmp load_gdt_and_kernel

;-------------------------------


load_gdt_and_kernel:
    cli
    xor ax,ax
    mov ds, ax 
      
    lgdt [gdt_descriptor]

    mov eax , cr0
    or eax , 0x1

    mov cr0 , eax

    jmp gdt_codeSeg:init_pm


    [bits 32]
    init_pm:
     
    MOV AX, gdt_dataSeg                     ; Update segments for protected mode as defined in GDT
    MOV DS, AX
    MOV SS, AX
    MOV ES, AX

    MOV EBP, 0x7c00                       ; Set stack base at top of free space
    MOV ESP, EBP

    call 0x1000;jump to kernel head
     
    jmp $

; Global descriptor table for 32-bit protected mode
gdt_start:                              ; Start of global descriptor table
    gdt_null:                           ; Null descriptor chunk
        dd 0x00
        dd 0x00
    gdt_code:                           ; Code descriptor chunk
        dw 0xFFFF
        dw 0x0000
        db 0x00
        db 0x9A
        db 0xCF
        db 0x00
    gdt_data:                           ; Data descriptor chunk
        dw 0xFFFF
        dw 0x0000
        db 0x00
        db 0x92
        db 0xCF
        db 0x00
    gdt_end:                            ; Bottom of table
gdt_descriptor:                         ; Table descriptor
    dw gdt_end - gdt_start - 1          ; Size of table
    dd gdt_start                        ; Start point of table
    
gdt_codeSeg equ gdt_code - gdt_start    ; Offset of code segment from start
gdt_dataSeg equ gdt_data - gdt_start    ; Offset of data segment from start

msg_greet:              db 'HELLO FROM THE BOOTLOADER', 0x0D, 0x0A, 0
msg_lba_present:        db 'LBA PRESENT', 0x0D, 0x0A, 0
msg_lba_not_present:    db 'LBA NOT PRESENT', 0x0D, 0x0A, 0

; ------------------------
; Disk Address Packet (DAP)
; ------------------------
dap:
    db 0x10       ; Size
    db 0x00       ; Reserved
    dw 1          ; Sectors to read
    dw 0x0        ; Offset
    dw 0x0        ; Segment
dap_lba:      
    dd 0          ; LBA low 32 bits (AX)
    dd 0          ; LBA high 32 bits

times 510 -( $ - $$ ) db 0 
dw 0xaa55
