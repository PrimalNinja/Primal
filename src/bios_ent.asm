;#dialect=RASM

				org #0000
				relocate_start

								; WARNING NO CODE FROM HERE IN THIS FILE

BIOS:			jp Main			; BIOS provides platform dependent way to access hardware in a uniform way

								; header
				dw RelocationTable - BIOS
				dw 1			; version
				dw 1			; API compatability ID
				db 1			; required memory type
				dw PatchTable
				dw JumpBlock	; pointer to the jumpblock
				dw 0			; pointer to the ISR
				dw 0			; pointer to the component that loaded this
				db "PRIMAL", 0	; type must be after the jump to main
				db "BIOS for Elan Enterprise 64/128", 0	; description

				include "bios.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

BIOS_KeyIn:		ret	
		
BIOS_ISRInit:	ret	

RelocationTable:
				dw relocate_count
				relocate_table
				relocate_end

END_OF_BIOS:
