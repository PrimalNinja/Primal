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
				db "No Banked Memory", 0	; description

				include "mem.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

RAM_SEL_PORT_COUNT	equ 0
RAM_BANK_SIZE		equ 0

PS_BankCount:	ld a,0			; returns number of banks
				ret
		
PS_BankSelect:	jp SysError		; selects memory bank
		
PS_BankUnSelect:
				jp SysError		; deselects memory bank
		
PS_BankStart:	ld hl, 0		; start of current memory bank
				ret

PS_BankEnd:		ld de, 0		; end of current memory bank
				ret

PS_BankSize:	ld bc, 0		; size of current memory bank
				ret

PS_Initialise:	ret

RelocationTable:
				dw relocate_count
				relocate_table
				relocate_end

END_OF_BIOS:
