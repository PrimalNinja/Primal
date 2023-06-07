;#dialect=RASM

BUILD_ADDR		equ #0000
ALLOCSIZE		equ 0

				org BUILD_ADDR
				relocate_start

								; WARNING NO CODE FROM HERE IN THIS FILE

RELOC_START:	jp Main			; jump to entry point

								; header
				dw RelocationTable - RELOC_START
				dw BUILD_ADDR
				dw ALLOCSIZE	; allocate this amount of ram after loading this module so it isn't stored in the binary, usually it overwrites the relocation table
				dw 1			; version
				dw 1			; API compatability ID
				db 1			; required memory type
				dw PatchTable
ADDR_JUMPBLOCK:	dw JumpBlock	; pointer to the jumpblock
				dw 0			; pointer to the ISR
ADDR_LOADER:	dw 0			; pointer to the component that loaded this
				db "PRIMAL", 0	; type must be after the jump to main
				db "256k Banked Memory for Amstrad CPC", 0		; description

				include "mem.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

RAM_SEL_PORT_COUNT	equ 15
RAM_BANK_START		equ #4000
RAM_BANK_END		equ #7FFF
RAM_BANK_SIZE		equ #4000
RAM_SEL_PORTS:		defw #7fc4, #7fc5, #7fc6, #7fc7
					defw #7fcc, #7fcd, #7fce, #7fcf
					defw #7fd4, #7fd5, #7fd6, #7fd7
					defw #7fdc, #7fdd, #7fde, #7fdf
					
PS_BankCount:	ld a, RAM_SEL_PORT_COUNT; returns number of banks
				ret
		
PS_BankSelect:	ld c, a
				ld a, (ADDR_CURRENTBANK)
				cp c
				ret z

				ld hl, RAM_SEL_PORTS	; selects memory bank
				ld b, 0
				add hl, bc
				add hl, hl
				ld c, (hl)
				inc hl
				ld b, (hl)
				out (c), c

				ld (ADDR_CURRENTBANK), a
				ret
		
PS_BankUnSelect:
				ld bc, #7fc0			; deselects memory bank (same as selecting bank 0)
				out (c), c

				xor a
				ld (ADDR_CURRENTBANK), a
				ret
				
PS_BankStart:	ld hl, RAM_BANK_START	; start of current memory bank
				ret

PS_BankEnd:		ld de, RAM_BANK_END		; end of current memory bank
				ret

PS_BankSize:	ld bc, RAM_BANK_SIZE	; size of current memory bank
				ret

PS_Initialise:	ret

RelocationTable:
				dw relocate_count
				relocate_table
				relocate_end

RELOC_END:

