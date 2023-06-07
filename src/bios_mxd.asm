;#dialect=RASM

BUILD_ADDR		equ #0000

				org BUILD_ADDR
				relocate_start

								; WARNING NO CODE FROM HERE IN THIS FILE

RELOC_START:	jp Main			; jump to entry point

								; header
				dw RelocationTable - RELOC_START
				dw BUILD_ADDR
				dw 1			; version
				dw 1			; API compatability ID
				db 1			; required memory type
				dw PatchTable
				dw JumpBlock	; pointer to the jumpblock
				dw 0			; pointer to the ISR
				dw 0			; pointer to the component that loaded this
				db "PRIMAL", 0	; type must be after the jump to main
				db "BIOS for MSX DOS", 0	; description

				include "bios.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

PS_KeyIn:		ret	
		
PS_ISRInit:		ret	

RelocationTable:
				dw relocate_count
				relocate_table
				relocate_end

RELOC_END:
