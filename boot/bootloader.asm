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
bsVolumeLabel: 	        DB "nobotro os"
bsFileSystem: 	        DB "FAT12"

start:
    mov ax, 0
    mov ds, ax
    mov es, ax
    jmp main

;-------------------------
; FAT routines
;-------------------------

; - dl: drive number
update_bootR:
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 08h
    int 13h
    
    inc dh
    mov [bpbHeadsPerCylinder], dh
    and cl, 0b00111111
    mov [bpbSectorsPerTrack], cl

    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Returns:
;       - ax: kernel first cluster
fat_load_root_and_search_kernel:
    push bx
    push cx
    push dx

    ; root LBA
    xor ah, ah
    mov al, [bpbNumberOfFATs]
    mul word [bpbSectorsPerFAT]
    add ax, [bpbReservedSectors]
    mov [root_LBA], ax

    ; root size
    mov ax, [bpbRootEntries]
    shl ax, 5 ; same effect of multiply by 32
    add ax, [bpbBytesPerSector] ; add of denominator and sub by 1 is a cool trick to emulate ceil function
    dec ax
    div word [bpbBytesPerSector] ; quotient ax
    mov [root_size], ax

    ; read root dir
    mov cx, ds
    mov es, cx
    mov bx, buffer
    mov cx, ax
    mov ax, [root_LBA]
    mov dl, [bsDriveNumber]
    call disk_read

    call fat_search_kernel

    pop dx
    pop cx
    pop bx
    ret

fat_search_kernel:
    xor bx, bx
    mov si, buffer
.loop:
    push si 
    mov di, kernel_filename
    mov cx, 11
    cld
    repe cmpsb
    pop si

    jz .found
    add si, 32
    inc bx
    cmp bx, [bpbRootEntries]
    jl .loop
    jmp .not_found
.found:
    mov ax, [si + 26]
    jmp .finish
.not_found:    
    nop         ; gotta do something
.finish:
    ret

; - ax: first cluster number
; - es:bx: memory to load
fat_load_file:
    ; loading FAT on buffer
    push cx
    push dx
    
    push ax
    push bx
    push es
    
    mov cx, ds
    mov es, cx
    mov bx, buffer
    mov ax, [bpbReservedSectors]
    mov cl, [bpbSectorsPerFAT]
    mov dl, [bsDriveNumber]
    call disk_read
   
    pop es
    pop bx
    pop ax

.loop:
    ; cluster lba
    push ax

    sub ax, 2
    xor ch, ch
    mov cl, [bpbSectorsPerCluster]
    mul cx
    add ax, [root_LBA]
    add ax, [root_size]

    ;reading cluster
    mov dl, [bsDriveNumber]
    ; cx contains the sectorspercluster from previous operation
    call disk_read ; disk read will change ax; so we pushed it earlier

.update_bx:
    xor ch, ch
    mov cl, [bpbSectorsPerCluster]
    add bx, [bpbBytesPerSector]
    loop .update_bx

    pop ax ; ax = active cluster
    push ax
    mov cx, 2
    xor dx, dx
    div cx ; dx = remainder
    pop cx
    add ax, cx ; ax = ax + ax/2
    ; why? each fat entry is 12 bits .i.e 1.5 bytes so we multiply the active cluster by 1.5 to get the index
    
    mov si, buffer
    add si, ax
    mov ax, [ds:si] ; reading entry from fat at index ax (two bytes)
    ; but our fat entry is only 12 bytes
    ; so, if the index is even, we  do, new_cluster = new_cluster & 0xfff
    ; if index is odd, we do, new_cluster = new_cluster >> 4
    and cx, 1
    jz .even
    shr ax, 4
    jmp .next
.even:
    and ax, 0xfff
.next:
    cmp ax, 0xff8
    jb .loop
    
    pop dx
    pop cx
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

disk_reset:
    pusha

    mov ah, 0
    ; stc ; needed when checking carry (error)
    int 13h
    ;jc floppy_error
    popa
    ret

main:
    MOV EBP, 0x7c00         ; Set stack base at top of free space
    MOV ESP, EBP

    ; DL hasn't been destroyed by our bootloader code and still
    ;     contains boot drive # passed to our bootloader by the BIOS
    mov [bsDriveNumber], dl ; dl has been set by bios

    call disk_reset

    ;call load_kernel_data
    call update_bootR
    call fat_load_root_and_search_kernel ; ax = kernel cluster
    
    mov cx, ds
    mov es, cx 
    mov bx, 0x1000
    call fat_load_file
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


root_LBA:               dw 0
root_size:              dw 0
kernel_filename:        db 'KERNEL  BIN'

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

times 510-($ - $$) db 0 
dw 0xaa55

; We can use this buffer after our 512 byte bootloader code
buffer:
