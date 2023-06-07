;#dialect=RASM

BUILD_ADDR		equ #0000
STACKSIZE		equ 128

COPYBUFFERSIZE	equ 128
COPYBUFFERADDR	equ ADDR_BUFFERS
ALLOCSIZE		equ COPYBUFFERSIZE

RAM_RESERVE		equ #4000 + ALLOCSIZE	; (32k)

				org BUILD_ADDR
				relocate_start

								; Symbos stuff
Compile_Address:
;==============================================================================
;### CODE AREA ################################################################
;==============================================================================
Code_Area_Start:

				; Name definitions used on documentation:
				include "LIB/SymbOS-Constants.asm"

				; Support Macros for graphics:
				include "LIB/SymbOS-Macros.asm"

;------------------------------------------------------------------------------
;### APPLICATION HEADER #######################################################
;------------------------------------------------------------------------------

				; Application header is same for SymbOS .COM and .EXE files.

				dw Code_Area_Size       ; +000 length of the code area
				dw Data_Area_Size       ; +002 length of the data area
				dw Transfer_Area_Size   ; +004 length of the transfer area
Data_Area_Address:                  ; +006 After loading:  This points to start of data area.
				dw Compile_Address      ; +006 Before loading: The address where program was compiled
Transter_Area_Address:              ; +008 After loading: This points to start of transfer adrea.
				dw relocate_count       ; +008 Before loading: Number of relocation table entries (SjAsm defined constant)
Sub_Proces_IDs:                     ; +010 (...+013) After loading: Sub process IDs (max 4pcs)
                                    ;      These will be killed automatically on exit
                                    ;      remove IDs from table if you kill manually.
				dw App_Stack_Offset     ; +010 Before loading: Application stack offset from Transfer area start
				dw 0                    ; +012 Before loading: Length of crunched data (NOT YET SUPPORTED)
App_Bank_Number:                    ; +014 After loading: RAM bank number where application was loaded.
				db 0                    ; +014 Before loading: Cruncher type (NOT YET SUPPORTED)
App_Name:   	SIZE "PRIMAL Loader for Symbos",24; +015 Application name (up to 24 characters)
				db 0                    ; +039 ASCIIZ String terminator (=0) in case the Name is max size
				db 1                    ; +040 Flags (+1=16 color icon available)
				dw App_16C_Icon.Offset  ; +041 16 color icon offset from beginning (Optional) 0 = None
				ds 5,0                  ; +043 (...+047) Reserved, must be 0
Reserved_Memory_Table:              ; +048 (...+087) After loading: Table of additional memory areas (max 8pcs)
                                    ;      Format: 8x ( db RAM_Bank : dw Address : dw Length )                   ;
				db "SymExe10"           ; +048 Before loading: SymbOS executable identification string
				dw RAM_RESERVE          ; +056 Before loading: Length of additional reserved code area memory
				dw 0                    ; +058 Before loading: Length of additional reserved data area memory
				dw 0                    ; +060 Before loading: Length of additional reserved transfer area memory
				ds 26,0                 ; +062 Before loading: Reserved space for future use. Must be 0
App_ID:                             ; +088 After loading: Application ID
				db 0                    ; +088 Before loading: Required OS Version minor (after dot)
Main_Process_ID:                    ; +089 After loading: Main process ID (Alternative address for App_Process_ID)
				db 2                    ; +089 Before loading: Required OS version major (before dot)
App_Icon_Small:                     ; +090 Application icon (small version), 8x8 pixel
				Graphic_Simple 8,8      ;      Macro for 4-color graphics header
				DS .ByteCount           ;      Actual picture data (16-bytes)
App_Icon_Large:                     ; +109 Application icon (Large version), 24x24 pixel
				Graphic_Simple 24,24    ;      Macro for 4-color graphics header
				DS .ByteCount           ;      Actual picture data (144-bytes)
                                    ; +256 Application code

App_Start:
				; The application start address
				; This address is defined in stack. -> See Transfer area
				;
				; Please note: Shadow registers are reserved for OS use.
				;-------------------------------------------------------

				; This routine contains all COM-file specific stuff. Other than these mandatory calls
				; the Shell-program works like any other EXE-file.

				call SyShell_PARALL     ; Mandatory: Get commandline parameters
				call SyShell_PARSHL     ; Mandatory: Parse Shell-specific parameters (ie. Shell Process ID)
										; Please see the SymShell include file & documentation for details.
										; This call will parse also user parameters to "string descriptor"-list.

								; END OF Symbos stuff





								; WARNING NO CODE FROM HERE IN THIS FILE

LOADER:			jp Main			; loader is a platform dependent program loader

								; header
ADDR_RELOCTABLE:dw 0			; this isn't being relocated, so always 0
ADDR_BUILD:		dw BUILD_ADDR	; the build address, used for relocation
ALLOC_SIZE:		dw ALLOCSIZE	; allocate this amount of ram after loading this module so it isn't stored in the binary, usually it overwrites the relocation table
ADDR_VERSION:	dw 1			; version
ADDR_APICOMPAT:	dw 1			; API compatability ID
ADDR_REQMEMTYPE:db 1			; required memory type
ADDR_PATCHTABLE:dw PatchTable
ADDR_JUMPBLOCK:	dw JumpBlock	; pointer to the jumpblock
ADDR_ISR:		dw 0			; pointer to the ISR
ADDR_LOADER:	dw 0			; always 0 for loader
MSG_PRIMAL:		db "PRIMAL", 0	; type must be after the jump to main
				db "Loader for Symbos", 0	; description

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
SYSTEMPOOLADDR:	dw ADDR_BUFFERS + ALLOCSIZE
				dw 0

				db 0			; End of Block / can be patched to be an Extension Block
				dw 0, 0	

PS_RAMInit:		ret				; initialise RAM

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
				db "DEFTEXTRES", 0, 25, 80		; the text resolution (Y, X)
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

PS_CharIn:		ret	
		
PS_CharOut:		ld e, 0			; E  = Channel (0=Standard, 1=Screen)
				ld d, a			; d = char to output
				call SyShell_CHROUT
				ret	
				
PS_CharWait:	ld e, 0			; E  = Channel (0=Standard, 1=Keyboard)
				call SyShell_CHRINP
				xor a
				ret	
		
PS_CommandLine:	ret				; get commandline parameters

PS_FileExists:	ret				; platform specific fileexists

PS_FileSize:	ret				; platform specific filesize

PS_FileDelete:	ret				; platform specific filedelete

PS_FileLoad:	ret				; platform specific fileload

PS_FileSave:	ret				; platform specific filesave

PS_StrIn:						; gets a string input
				ret	

PS_StrOutHL:	ld e, 0
				call SyShell_STROUT		; outputs a string pointed to by HL
				xor a
				ret	
		
PS_Terminate:					; terminate elegantly
				ld e, 0                 ; Exit type: Quit (Exit permanently)
				call SyShell_EXIT       ; Mandatory: Tell Shell host that we are quitting
				jp SySystem_EXIT        ; Exit the program

END_OF_LOADER:





								; Symbos stuff Again

;------------------------------------------------------------------------------
;### LIBRARIES ################################################################
;------------------------------------------------------------------------------

				 ; Add custom libraries here:

				 ; System libraries:
				 ; All individual routines in these system libraries are included
				 ; to project ONLY if they are used ABOWE, so normally there
				 ; should be no reason to comment these lines out.

				 include "LIB/SymbOS_Lib-NetworkDaemon.asm"
				 include "LIB/SymbOS_Lib-SymShell.asm"
				 include "LIB/SymbOS_Lib-FileManager.asm"
				 include "LIB/SymbOS_Lib-DesktopManager.asm"
				 include "LIB/SymbOS_Lib-SystemManager.asm"
				 include "LIB/SymbOS_Lib-Kernel.asm"

Code_Area_End:
Code_Area_Size: equ Code_Area_End - Code_Area_Start
;==============================================================================
;### DATA AREA ################################################################
;==============================================================================
Data_Area_Start:   ; ; (Will be loaded to 256-byte boundary)

				; Place all data here that needs to be plotted to desktop
				; Even if not needed, every area must have at least 1 byte of data.


				; Optional 16-color application icon (24px x 24px)
App_16C_Icon:
				Graphic_Extended 24,24  ; Macro for 16-color graphics header
				DS .ByteCount           ; Graphics in MSX SCREEN 5/7 format (288 bytes)

Data_Area_End:
Data_Area_Size equ Data_Area_End - Data_Area_Start
;==============================================================================
;### TRANSFER AREA ############################################################
;==============================================================================
Transfer_Area_Start:  ; (Will be loaded to 256-byte boundary)

				; Data area for the stack, the message buffer and all window data records,
				; control data records and their control variables (radio button status,
				; selected tab etc.)

				;--- Main process stack definition  ---
				ds STACKSIZE            ; Your app default stack space, increase if needed
App_Stack:  	ds 6*2                  ; Fixed space for register storage
				dw App_Start            ; The stack content defines your applications start address
App_Process_ID:
				db 0                    ; process ID (Filled by kernel, alternative address for Main_Proces_ID)
App_Stack_Offset: equ App_Stack - Transfer_Area_Start
				;--- End of main process stack ---

				; You can add more stacks here if needed for other processes

				;--- Message buffer ---
Message_Buffer:
				ds 14

				; Other possible data you need to be on Transfer area

Transfer_Area_End:
Transfer_Area_Size equ Transfer_Area_End - Transfer_Area_Start
;==============================================================================
;### RELOCATION TABLE #########################################################
;==============================================================================

				; Relocation table will be placed here
				; by SjAsmPlus and handled by OS, do not modify.
				;
				; Please note: Don't break this system by
				; using coding style like:
				;   LD H,EXAMPLE / 256
				;   LD L,A
				; Write instead:
				;   LD HL,EXAMPLE
				;   LD L,A

ADDR_BUFFERS:

				relocate_table
				relocate_end

The_End:   		; This random label is placed here just to catch errors if assembly
				; can't be done on 3 passes. (Reorder your code properly.)
			
								; END OF Symbos stuff

