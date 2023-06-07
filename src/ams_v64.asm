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
ADDR_JUMPBLOCK:	dw JumpBlock	; pointer to the jumpblock
				dw 0			; pointer to the ISR
ADDR_LOADER:	dw 0			; pointer to the component that loaded this
				db "PRIMAL", 0	; type must be after the jump to main
				db "64k Virtual Memory for Amstrad CPC", 0		; description

				include "mem.asm"

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

RAM_SEL_PORT_COUNT	equ 3
RAM_BANK_START		equ #4000
RAM_BANK_END		equ #7FFF
RAM_BANK_SIZE		equ #4000
RAM_SEL_FILES:		defw filename_7fc4, filename_7fc5, filename_7fc6, filename_7fc7, 0
filename_current:	defw filename_7fc0
					
filename_7fc0:	defb "mem_7fc0.bin",0
filename_7fc4:	defb "mem_7fc4.bin",0
filename_7fc5:	defb "mem_7fc5.bin",0
filename_7fc6:	defb "mem_7fc6.bin",0
filename_7fc7:	defb "mem_7fc7.bin",0
					
PS_BankCount:	ld a,RAM_SEL_PORT_COUNT			; returns number of banks
				ret
		
PS_BankSelect:								; selects memory bank
				ld hl,RAM_SEL_FILES
				ld b,0
				ld c,a
				add hl,bc
				add hl,hl
				ld c,(hl)				; bc = new filename
				inc hl
				ld b,(hl)

				; first check if we already are in this memory
				; if we are then just return otherwise
				ld hl,(filename_current)
				xor a
				sbc hl,bc
				ret z

				push bc
				; save current memory
				ld hl,(filename_current)
				ld de,RAM_BANK_START
				ld bc,RAM_BANK_SIZE
				call SysFileSave
				pop bc
				jr nz, VirtualMemoryError
				
				; select new one
				ld l,c
				ld h,b
				ld de,RAM_BANK_START
				push hl
				call SysFileLoad
				pop hl
				jr nz, VirtualMemoryError
				
				; store the current bank
				ld (filename_current), hl
				ret
		
PS_BankUnSelect:						; deselects memory bank
				; first check if we already are in this memory
				; if we are then just return otherwise
				ld hl,(filename_current)
				ld bc,filename_7fc0
				xor a
				sbc hl,bc
				ret z
				
				; save current memory
				ld hl,(filename_current)
				ld de,RAM_BANK_START
				ld bc,RAM_BANK_SIZE
				call SysFileSave
				jr nz, VirtualMemoryError
				
				; select new one
				ld hl,filename_7fc0
				ld de,RAM_BANK_START
				push hl
				call SysFileLoad
				pop hl
				jr nz, VirtualMemoryError
				
				; store the current bank
				ld (filename_current), hl
				ret
				
PS_BankStart:	ld hl,RAM_BANK_START	; start of current memory bank
				ret

PS_BankEnd:		ld de,RAM_BANK_END		; end of current memory bank
				ret

PS_BankSize:	ld bc,RAM_BANK_SIZE	; size of current memory bank
				ret
				
PS_Initialise:	ld hl,RAM_SEL_FILES

				ld hl,RAM_BANK_START	; clear memory where banking occurs
				ld de,(RAM_BANK_START+1)
				ld bc,(RAM_BANK_SIZE-1)
				ldir

PS_InitialiseLoop:
				ld e,(hl)
				inc hl
				ld d,(hl)
				inc hl
				ld a,e
				or d
				ret z
				
				push hl
				
				ld l,e
				ld h,d
				push hl
				call SysFileExists
				pop hl
				jr z, PS_InitialiseSkip
				
				push hl
				call SysFileDelete
				pop hl
				
PS_InitialiseSkip:
				ld de,RAM_BANK_START
				ld bc,RAM_BANK_SIZE
				call SysFileSave
				
				pop hl
				jr nz, VirtualMemoryError
				
				jr PS_InitialiseLoop
				
VirtualMemoryError:
				call SysStrOutPC
				db "Virtual Memory Error.", 0
				ret

RelocationTable:
				dw relocate_count
				relocate_table
				relocate_end

RELOC_END:
