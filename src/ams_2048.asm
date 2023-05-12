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
				db "2048k Banked Memory for Amstrad CPC", 0		; description

				include "mem.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

RAM_SEL_PORT_COUNT	equ 127
RAM_BANK_START		equ #4000
RAM_BANK_END		equ #7FFF
RAM_BANK_SIZE		equ #4000
RAM_SEL_PORTS:		defw #7cc4, #7cc5, #7cc6, #7cc7
					defw #7ccc, #7ccd, #7cce, #7ccf
					defw #7cd4, #7cd5, #7cd6, #7cd7
					defw #7cdc, #7cdd, #7cde, #7cdf
					defw #7ce4, #7ce5, #7ce6, #7ce7
					defw #7cec, #7ced, #7cee, #7cef
					defw #7cf4, #7cf5, #7cf6, #7cf7
					defw #7cfc, #7cfd, #7cfe, #7cff

					defw #7dc4, #7dc5, #7dc6, #7dc7
					defw #7dcc, #7dcd, #7dce, #7dcf
					defw #7dd4, #7dd5, #7dd6, #7dd7
					defw #7ddc, #7ddd, #7dde, #7ddf
					defw #7de4, #7de5, #7de6, #7de7
					defw #7dec, #7ded, #7dee, #7def
					defw #7df4, #7df5, #7df6, #7df7
					defw #7dfc, #7dfd, #7dfe, #7dff

					defw #7ec4, #7ec5, #7ec6, #7ec7
					defw #7ecc, #7ecd, #7ece, #7ecf
					defw #7ed4, #7ed5, #7ed6, #7ed7
					defw #7edc, #7edd, #7ede, #7edf
					defw #7ee4, #7ee5, #7ee6, #7ee7
					defw #7eec, #7eed, #7eee, #7eef
					defw #7ef4, #7ef5, #7ef6, #7ef7
					defw #7efc, #7efd, #7efe, #7eff
					
					defw #7fc4, #7fc5, #7fc6, #7fc7
					defw #7fcc, #7fcd, #7fce, #7fcf
					defw #7fd4, #7fd5, #7fd6, #7fd7
					defw #7fdc, #7fdd, #7fde, #7fdf
					defw #7fe4, #7fe5, #7fe6, #7fe7
					defw #7fec, #7fed, #7fee, #7fef
					defw #7ff4, #7ff5, #7ff6, #7ff7
					defw #7ffc, #7ffd, #7ffe, #7fff
					
PS_BankCount:	ld a,RAM_SEL_PORT_COUNT			; returns number of banks
				ret
		
PS_BankSelect:	ld hl,RAM_SEL_PORTS			; selects memory bank
				ld b,0
				ld c,a
				add hl,bc
				add hl,hl
				ld c,(hl)
				inc hl
				ld b,(hl)
				out (c), c
				ret
		
PS_BankUnSelect:
				ld bc,#7fc0		; deselects memory bank (same as selecting bank 0)
				out (c),c
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

END_OF_BIOS:
