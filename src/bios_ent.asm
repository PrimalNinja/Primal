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
				dw JUMPBLOCK	; pointer to the jumpblock
				dw 0			; pointer to the ISR
				dw 0			; pointer to the component that loaded this
				db "PRIMAL", 0	; type must be after the jump to main
				db "BIOS for Elan Enterprise 64/128", 0	; description

				include "bios.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

PS_KeyIn:		ret	
		
PS_ISRInit:		ret	

TABLE_RELOC:
				dw relocate_count
				relocate_table
				relocate_end

END_RELOC:
