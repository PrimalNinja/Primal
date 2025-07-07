;#dialect=RASM

ORG_BUILD		equ #0000
SIZE_ALLOC		equ 0

				org ORG_BUILD
				relocate_start

								; WARNING NO CODE FROM HERE IN THIS FILE

START_RELOC:	jp Main			; jump to entry point

								; header
				dw TABLE_RELOC - START_RELOC
				dw ORG_BUILD
				dw SIZE_ALLOC	; allocate this amount of ram after loading this module so it isn't stored in the binary, usually it overwrites the relocation table
				dw 1			; version
				dw 1			; API compatability ID
				db 1			; required memory type
				dw TABLE_PATCH
ADDR_JUMPBLOCK:	dw JUMPBLOCK	; pointer to the jumpblock
				dw 0			; pointer to the ISR
ADDR_LOADER:	dw 0			; pointer to the component that loaded this
				db "PRIMAL", 0	; type must be after the jump to main
				db "64k Virtual Memory for Amstrad CPC", 0		; description

				include "mem.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

RAM_SEL_PORT_APPHEAP_COUNT	equ 5
RAM_SEL_PORT_SYSHEAP_COUNT	equ 5
RAM_SEL_PORT_BUFFHEAP_COUNT	equ 5	; not supported in this model

RAM_BANK_START		equ #4000
RAM_BANK_END		equ #7FFF
RAM_BANK_SIZE		equ #4000

RAM_SEL_APP_PORTS:	defw DEF_7fc0
ADDABLE_APP_PORTS:	defw APP_7fc4, APP_7fc5, APP_7fc6, APP_7fc7
					defw 0

RAM_SEL_SYS_PORTS:	defw DEF_7fc0
ADDABLE_SYS_PORTS:	defw SYS_7fc4, SYS_7fc5, SYS_7fc6, SYS_7fc7
					defw 0

RAM_SEL_BUFF_PORTS:	defw DEF_7fc0
ADDABLE_BUFF_PORTS:	defw BUFF_7fc4, BUFF_7fc5, BUFF_7fc6, BUFF_7fc7
					defw 0

FILENAME_CURRENT:	defw DEF_7fc0
					
DEF_7fc0:		defb "def_7fc0.bin", 0

APP_7fc4:		defb "app_7fc4.bin", 0
APP_7fc5:		defb "app_7fc5.bin", 0
APP_7fc6:		defb "app_7fc6.bin", 0
APP_7fc7:		defb "app_7fc7.bin", 0

SYS_7fc4:		defb "sys_7fc4.bin", 0
SYS_7fc5:		defb "sys_7fc5.bin", 0
SYS_7fc6:		defb "sys_7fc6.bin", 0
SYS_7fc7:		defb "sys_7fc7.bin", 0
					
BUFF_7fc4:		defb "buf_7fc4.bin", 0
BUFF_7fc5:		defb "buf_7fc5.bin", 0
BUFF_7fc6:		defb "buf_7fc6.bin", 0
BUFF_7fc7:		defb "buf_7fc7.bin", 0
					
PS_BankCount:	call SysHeapType
				cp 1
				jr z, PS_BankCount1

				cp 2
				jr z, PS_BankCount2
				
				cp 3
				jr z, PS_BankCount3
				jp SysError
				
PS_BankCount1:	
				ld a, RAM_SEL_PORT_APPHEAP_COUNT
				ret
		
PS_BankCount2:	
				ld a, RAM_SEL_PORT_SYSHEAP_COUNT
				ret
		
PS_BankCount3:	
				ld a, RAM_SEL_PORT_BUFFHEAP_COUNT
				ret
		
PS_BankSelect:	ld b, a
				call SysHeapType
				ld a, b

				ld hl, RAM_SEL_APP_PORTS	; selects memory bank
				ld de, ADDR_CURRENTAPPBANK
				cp 1
				jr z, PS_BankSelectDo

				ld hl, RAM_SEL_SYS_PORTS	; selects memory bank
				ld de, ADDR_CURRENTSYSBANK
				cp 2
				jr z, PS_BankSelectDo

				ld hl, RAM_SEL_BUFF_PORTS	; selects memory bank
				ld de, ADDR_CURRENTBUFFBANK
				cp 3
				jr z, PS_BankSelectDo
				jp SysError
				
PS_BankSelectDo:
				ld c, a
				ld a, (de)
				cp c
				ret z
				
				push de		;*
											; selects memory bank
				ld b, 0
				add hl, bc
				add hl, hl
				ld c, (hl)				; bc = new filename
				inc hl
				ld b, (hl)
				
				push bc
				; save current memory
				ld hl, (FILENAME_CURRENT)
				ld de, RAM_BANK_START
				ld bc, RAM_BANK_SIZE
				call SysFileSave
				pop bc
				jp nz, VirtualMemoryError
				
				; select new one
				ld l, c
				ld h, b
				ld de, RAM_BANK_START
				push hl
				call SysFileLoad
				pop hl
				jp nz, VirtualMemoryError
				
				pop de		;*
				; store the current bank
				ld (FILENAME_CURRENT), hl
				ld (de), a

				xor a
				ret
		
PS_BankUnSelect:
				; first check if we already are in this memory
				; if we are then just return otherwise
				ld hl, (FILENAME_CURRENT)
				ld bc, DEF_7fc0
				xor a
				sbc hl, bc
				ret z
				
				; save current memory
				ld hl, (FILENAME_CURRENT)
				ld de, RAM_BANK_START
				ld bc, RAM_BANK_SIZE
				call SysFileSave
				jr nz, VirtualMemoryError
				
				; select new one
				ld hl, DEF_7fc0
				ld de, RAM_BANK_START
				push hl
				call SysFileLoad
				pop hl
				jr nz, VirtualMemoryError
				
				; store the current bank
				ld (FILENAME_CURRENT), hl
				ret
				
PS_BankStart:	ld hl, RAM_BANK_START	; start of current memory bank
				ret

PS_BankEnd:		ld de, RAM_BANK_END		; end of current memory bank
				ret

PS_BankSize:	ld bc, RAM_BANK_SIZE	; size of current memory bank
				ret
				
PS_Initialise:	ld hl, RAM_BANK_START	; clear memory where banking occurs
				ld de, (RAM_BANK_START+1)
				ld bc, (RAM_BANK_SIZE-1)
				ldir
				
				ld hl, RAM_SEL_APP_PORTS
				call PS_Initialise2

				ld hl, RAM_SEL_SYS_PORTS
				call PS_Initialise2
				ret

PS_Initialise2:
PS_InitialiseLoop:
				ld e, (hl)
				inc hl
				ld d, (hl)
				inc hl
				ld a, e
				or d
				ret z
				
				push hl		; *
				
				ld l, e
				ld h, d
				push hl		; **
				call SysFileExists
				pop hl		; **
				jr z, PS_InitialiseSkip
				
				push hl		; **
				call SysFileDelete
				pop hl		; **
				
PS_InitialiseSkip:
				ld de, RAM_BANK_START
				ld bc, RAM_BANK_SIZE
				call SysFileSave
				
				pop hl		; *
				jr nz, VirtualMemoryError
				
				jr PS_InitialiseLoop
				
VirtualMemoryError:
				call SysStrOutPC
				db "Virtual Memory Error.", 0
				ret

TABLE_RELOC:
				dw relocate_count
				relocate_table
				relocate_end

END_RELOC:
