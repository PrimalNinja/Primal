;#dialect=RASM

BUILD_ADDR		equ #7ae9
KEYPRESS		equ #2EF4
CHAROUT			equ #033A
DKLOAD			equ #4041
FILESTART		equ #78a4
FILEEND			equ #78f9
RAMTOP			equ #7881
SAVOB			equ #4044
SEARCH			equ #402C
STROUT			equ #2BA7

COPYBUFFERSIZE	equ 128
STACKSIZE		equ 128

ERR_FILENOTFOUND equ 13

				org BUILD_ADDR

								; WARNING NO CODE FROM HERE IN THIS FILE

LOADER:			jp Main			; loader is a platform dependent program loader

								; header
ADDR_RELOCTABLE:dw 0			; this isn't being relocated, so always 0
ADDR_BUILD:		dw BUILD_ADDR	; the build address, used for relocation
ADDR_VERSION:	dw 1			; version
ADDR_APICOMPAT:	dw 1			; API compatability ID
ADDR_REQMEMTYPE:db 1			; required memory type
ADDR_PATCHTABLE:dw PatchTable
ADDR_JUMPBLOCK:	dw JumpBlock	; pointer to the jumpblock
ADDR_ISR:		dw 0			; pointer to the ISR
ADDR_LOADER:	dw 0			; always 0 for loader
MSG_PRIMAL:		db "PRIMAL", 0	; type must be after the jump to main
				db "Loader for VZ300", 0	; description

				include "load.asm"
		
								; WARNING CODE BELOW HERE ONLY IN THIS FILE

								; Memory Table Record Summary
								; 0 = End of Table
								; 1 = Non-Pageable block of RAM
								; 2 = Pageable block of RAM
								; 252 = Video RAM
								; 253 = Reserved RAM
								; 254 = ROM
								; 255 = Extension Block (anything following an extension record is ignored)
MemTable:		
				db 1
				dw END_OF_LOADER
MemBlock1End	dw 0

				db 0			; End of Block / can be patched to be an Extension Block
				dw 0, 0	

PS_RAMInit:						; initialise RAM
				ld (DOSVECTOR),iy

				ld hl,(RAMTOP)
				ld sp,hl		; put stack at himem
				
				ld de,STACKSIZE	; calculate new himem to be below the stack
				and a
				sbc hl,de
				ld (MemBlock1End),hl
				ret				

								; table of property tables
PropertyTable:	dw PropertyTable1, 0

								; table of propertyname zero terminated, 16bit value
PropertyTable1:	
				db "CANSAVE", 0, "Y", 0			; is saving to the boot device possible?
				db "CANDELETE", 0, "Y", 0		; is file deletion possible from the boot device?
				db "CANBUILD", 0, "Y", 0		; is building possible?
				db "ISBUILT", 0, "N", 0			; is the system built already?
				db "HASCLIPARAMS", 0, "N", 0	; does the host have commandline parameter support?
				db "PROMPTONSTART", 0, "Y", 0	; prompt on startup?
				db "CANSETCURSORPOS", 0, "Y", 0	; can we set the cursor position?
				db "DEFTEXTRES", 0, 16, 32		; the text resolution (Y, X)
				db 0
				
ADDR_EIDI:		db 0;

					; ------------------------- disable interrupts (supports nesting)
PS_DI:			di
				push hl
				ld hl, ADDR_EIDI
				inc (hl)
				;push af
				;ld a, #c9
				;ld (adr_isr_intercept), a
				;pop af
				pop hl
				ret

PS_EI:			push af
				push hl
				ld hl, ADDR_EIDI
				dec (hl)
				ld a, (ADDR_EIDI)
				and a
				jr nz, PS_EIEND
				ei
				;ld a, #43
				;ld (adr_isr_intercept), a

PS_EIEND:		pop hl
				pop af
				ret

DOSVECTOR:		dw 0			;iy should be stored here as it is used by the system

StrCpy8:		ld c,0				; copy max 8 characters of a . terminated string from hl to de
StrCpy8Loop:	ld a,c
				cp 8
				ret z			; max characters?
				
				ld a,(hl)
				cp '.'
				ret z			; a . (i.e. file extension not transferred to DOS vector)
				
				ld (de),a
				inc hl
				inc de
				inc c
				jr StrCpy8Loop

PS_CharIn:		call KEYPRESS
				ret	
		
PS_CharOut:		call CHAROUT
				ret	
		
PS_CharWait:	call KEYPRESS
				or a
				jr z,PS_CharWait
				ret
		
PS_CommandLine:	ret				; get commandline parameters

PS_FileExists:					; platform specific fileexists
				ld iy,(DOSVECTOR)
				push iy
				pop de
				inc de
				call StrCpy8
				
				call SEARCH
				cp ERR_FILENOTFOUND
				jp z,SysError
				xor a
				ret

PS_FileSize:					; platform specific filesize
				ld iy,(DOSVECTOR)
				push iy
				pop de
				inc de
				call StrCpy8
				
				call SEARCH
				or a
				jp nz,SysError
				
							; where do i get the filesize from?
				ret

PS_FileDelete:	ret				; platform specific filedelete

PS_FileLoad:					; platform specific fileload
				ld iy,(DOSVECTOR)
				push iy
				pop de
				inc de
				call StrCpy8
								; how do we specify where to load the file in memory?
				call DKLOAD
				or a
				ret				

PS_FileSave:	push de			; platform specific filesave
				push bc
				ld iy,(DOSVECTOR)
				push iy
				pop de
				inc de
				call StrCpy8
								; how do we specify what memory to save?
				pop bc
				pop hl
				ld (FILESTART),hl
				add hl,bc
				ld (FILEEND),hl
				
				call SAVOB
				or a
				ret

PS_StrIn:						; gets a string input
				ret	

PS_StrOutHL:	call STROUT		; outputs a string pointed to by HL
				ret
		
PS_Terminate:	ret				; terminate elegantly

END_OF_LOADER:
