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
				db "256k Silicon Disc Memory for Amstrad CPC", 0		; description

				include "mem.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

RAM_SEL_PORT_APPHEAP_COUNT	equ 9
RAM_SEL_PORT_SYSHEAP_COUNT	equ 5
RAM_SEL_PORT_BUFFHEAP_COUNT	equ 5	; not supported in this model

RAM_BANK_START		equ #4000
RAM_BANK_END		equ #7FFF
RAM_BANK_SIZE		equ #4000

RAM_SEL_APP_PORTS:	defw #7fc0
ADDABLE_APP_PORTS:	defw #7fe4, #7fe5, #7fe6, #7fe7
					defw #7fec, #7fed, #7fee, #7fef
					defw 0
					
RAM_SEL_SYS_PORTS:	defw #7fc0	
ADDABLE_SYS_PORTS:	defw #7ffc, #7ffd, #7ffe, #7fff
					defw 0
					
RAM_SEL_BUFF_PORTS:	defw #7fc0	
ADDABLE_BUFF_PORTS:	defw #7ff4, #7ff5, #7ff6, #7ff7
					defw 0
					
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

				ld b, 0
				add hl, bc
				add hl, hl
				ld c, (hl)
				inc hl
				ld b, (hl)
				out (c), c

				ld (de), a
				ret
		
PS_BankUnSelect:
				ld bc, #7fc0			; deselects memory bank (same as selecting bank 0)
				out (c), c
				ret
				
PS_BankStart:	ld hl, RAM_BANK_START	; start of current memory bank
				ret

PS_BankEnd:		ld de, RAM_BANK_END		; end of current memory bank
				ret

PS_BankSize:	ld bc, RAM_BANK_SIZE	; size of current memory bank
				ret

PS_Initialise:	ret

TABLE_RELOC:
				dw relocate_count
				relocate_table
				relocate_end

END_RELOC:

