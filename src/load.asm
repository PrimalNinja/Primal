;#dialect=RASM

								; WARNING NO CODE FROM HERE IN THIS FILE

MEM_NONPAGEABLE	equ 1
MEM_PAGEABLE	equ 2
MEM_EXTENSION	equ 255

								; patch data
PatchTable:		dw PatchLevel1, 0

				; API level, jumpblock size in bytes, address of jumpblock
PatchLevel1:	dw 1, (JUMPBLOCKLEVEL1END - JUMPBLOCKLEVEL1), JUMPBLOCKLEVEL1

JumpBlock:

JUMPBLOCKLEVEL1:				; API Level 1

SysCharIn:		jp PS_CharIn
SysCharOut:		jp PS_CharOut
SysCharWait:	jp PS_CharWait
SysDI:			jp PS_DI
SysEI:			jp PS_EI
SysFileDelete:	jp PS_FileDelete
SysFileExists:	jp PS_FileExists
SysFileLoad:	jp PS_FileLoad
SysFileSave:	jp PS_FileSave
SysFileSize:	jp PS_FileSize
SysStrIn:		jp PS_StrIn
SysStrOutHL:	jp PS_StrOutHL
SystemRestore:	jp LOADER_Error			; NOT YET IMPLEMENTED
SystemSave:		jp LOADER_Error			; NOT YET IMPLEMENTED
SysTerminate:	jp PS_Terminate

SysBuild:		jp LOADER_Error			; NOT YET IMPLEMENTED
SysCheckPrimal:	jp LOADER_CheckPrimal
SysCommandLine:	jp LOADER_CommandLine
SysCopyBuffer: 	jp LOADER_CopyBuffer
SysCopyBufferSize: jp LOADER_CopyBufferSize
SysDecompress:	jp LOADER_Decompress
SysError: 		jp LOADER_Error
SysLDRPCFile:	jp LOADER_LDRPCFile
SysMemTable:	jp LOADER_MemTable
SysPatch:		jp LOADER_Patch
SysPropertyPC:	jp LOADER_PropertyPC
SysRAMSize:		jp LOADER_RAMSize
SysRelocate:	jp LOADER_Relocate
SysStrCompare:	jp LOADER_StrCompare
SysStrLen:		jp LOADER_StrLen
SysStrOutPC:	jp LOADER_StrOutPC
SysStrSkip:		jp LOADER_StrSkip

SysBankCount:	jp LOADER_BankCount
SysBankedRAMSize: jp LOADER_BankedRAMSize
SysBankEnd:		jp LOADER_BankEnd
SysBankSelect:	jp LOADER_BankSelect
SysBankSize:	jp LOADER_BankSize
SysBankStart:	jp LOADER_BankStart
SysBankUnSelect:jp LOADER_BankUnSelect

JUMPBLOCKLEVEL1END:
		
								; WARNING CODE BELOW HERE ONLY IN THIS FILE
								
								; helper functions

CopyBufferInit:		; initialise the copy buffer
				xor a
				ld hl, COPYBUFFER
				ld de, COPYBUFFER + 1
				ld bc, COPYBUFFERSIZE - 1
				ldir
				ret

					; ------------------------- GetPatchTableAddr
					; -- parameters:
					; -- HL = address of the code to patch
					; -- return:
					; -- HL = address of loader of the code
					; -- corrupt:
					; -- all other registers unknown

GetLoaderAddr:					; hl = code to patch
				ld bc,(ADDR_LOADER - LOADER)
				add hl, bc
				ret
			
					; ------------------------- GetPatchTableAddr
					; -- parameters:
					; -- HL = address of the code to patch
					; -- return:
					; -- HL = address of the patch table
					; -- corrupt:
					; -- all other registers unknown

GetPatchTableAddr:				; hl = code to patch
				ld bc,(ADDR_PATCHTABLE - LOADER)
				add hl, bc
				ret
				
					; ------------------------- GetPatchTableLevel
					; -- parameters:
					; -- HL = patched table, A = level to find (non-zero)
					; -- return:
					; -- Z = false (i.e. NZ)
					; -- Z = true (i.e. Z), BC = patch size, DE = jumpblock to patch
					; -- corrupt:
					; -- all other registers unknown

GetPatchTableLevel:
				cp 0				; return if we try to find level 0
				jp z, SysError
				
GetPatchTableLevelLoop:	
				ld c, a
				ld e, (hl)			; de = patch level table
				inc hl
				ld d, (hl)
				inc hl
				ld a, e
				or d
				ld a, c
				jp z, SysError	; return if we didn't find our level

				ex de, hl

				ld c, (hl)
				cp c
				jr z, GetPatchTableLevelFound

				ex de, hl
				
				inc hl
				inc hl
				inc hl
				inc hl
				jr GetPatchTableLevelLoop
				
GetPatchTableLevelFound:	
				xor a
				inc hl
				ld c, (hl)
				inc hl
				ld b, (hl)
				inc hl
				ld e, (hl)
				inc hl
				ld d, (hl)
				ret

					; ------------------------- MathMinDEHL
					; -- parameters:
					; -- HL = number 1, DE = number 2
					; -- return:
					; -- HL = the minimum
					; -- corrupt:
					; -- all other registers unknown

MathMinDEHL:
				ld a, h
				cp d
				jr c, MathMinHL
				jr nc, MathMinDE
				ld a, l
				cp e
				jr c, MathMinHL
				jr nc, MathMinDE

MathMinDE:		ex de, hl
MathMinHL:		ret

					; ------------------------- Error
					; -- parameters:
					; -- none
					; -- return:
					; -- Z = false (i.e. NZ), E might contain the reason
					; -- corrupt:
					; -- all other registers unknown

LOADER_Error:
				ld a, 1
				or a
				ret
				
LOADER_BankCount:
				ld a, 0			; returns number of banks
				ret

LOADER_BankSelect:				; selects memory bank
				ret

LOADER_BankUnSelect:			; deselects memory bank (same as selecting bank 0)
				ret

LOADER_BankStart:
				ld hl, 0		; start of current memory bank
				ret

LOADER_BankEnd:	ld de, 0		; end of current memory bank
				ret

LOADER_BankSize:
				ld bc, 0		; size of current memory bank
				ret
				
LOADER_BankedRAMSize:
				ld bc, 0
				ld de, 0
				ret

					; ------------------------- MemTable
					; -- parameters:
					; -- none
					; -- return:
					; -- HL = address of the memory table
					; -- corrupt:
					; -- all other registers unknown

LOADER_MemTable:
				ld hl, MemTable
				ret				; platform specific memory table 

					; ------------------------- RAMSize
					; -- parameters:
					; -- HL = none
					; -- return:
					; -- BCDE = double word containing the size of avaialble RAM
					; -- corrupt:
					; -- all other registers unknown

LOADER_RAMSize:					; gets the total RAM size
				ld hl, MemTable	; HL = table position (start of table)
				ld bc, 0
				ld de, 0
				
LOADER_RAMSizeLoop:				; sum is in BCDE double-word
				ld a, (hl)		; get memory type
				or a
				ret z			; return if end of table
				
				cp MEM_EXTENSION
				jr z, LOADER_RAMSizeExtension
				
				cp MEM_NONPAGEABLE
				jr z, LOADER_RAMSizeAddTo
				
				cp MEM_PAGEABLE
				jr z, LOADER_RAMSizeAddTo
				
				inc hl			; table position to next block
				inc hl
				inc hl
				inc hl
				jr LOADER_RAMSizeLoop

LOADER_RAMSizeAddTo:
				push bc			; preserve sum so far
				push de			; preserve sum so far

				; start = (HL)
				ld c, (hl)
				inc hl
				ld b, (hl)
				inc hl
				; end = (HL)
				ld e, (hl)
				inc hl
				ld d, (hl)
				inc hl
				push hl			;preserve table position
				
				; HL = end - start
				ld l, e
				ld h, d
				xor a
				sbc hl, bc
				
				pop ix
				pop de
				pop bc
				push ix
				
				; add length HL to BCDE
				add hl, de
				ex de, hl
				ld hl, 0
				adc hl, bc
				ld c, l
				ld b, h

				pop hl
				jr LOADER_RAMSizeLoop

LOADER_RAMSizeExtension:
				push bc			; preserve sum so far
				push de			; preserve sum so far
				
				inc hl			; table position HL = new table address
				ld e, (hl)
				inc hl
				ld d, (hl)
				ld l, e
				ld h, d
				
				pop de
				pop bc
				jr LOADER_RAMSizeLoop
				
					; ------------------------- CheckPrimal
					; -- parameters:
					; -- HL = address of code to check
					; -- return:
					; -- Z = true if the file is a PRIMAL file, NZ if not
					; -- corrupt:
					; -- all other registers unknown

LOADER_CheckPrimal:				; validates if the file is primal after loaded
				ld bc, (MSG_PRIMAL - LOADER)
				add hl, bc
				ex de, hl
				ld hl, MSG_PRIMAL
				call SysStrCompare
				ret

LOADER_CommandLine:				; gets commandline parameters
				ret

LOADER_CopyBuffer:
				ld hl, COPYBUFFER
				ret

LOADER_CopyBufferSize:
				ld bc, COPYBUFFERSIZE
				ret

LOADER_Decompress:				; until it supports any decompression, it must at least accept uncompressed
				ld e, l
				ld d, h
				xor a			; by simply returning Z = true
				ret
								
					; ------------------------- Relocate
					; -- parameters:
					; -- HL = address of relocation table
					; -- DE = address of code to relocate
					; -- BC = original build address of code to relocate
					; -- return:
					; -- none
					; -- corrupt:
					; -- all other registers unknown

LOADER_Relocate:				; relocator
				push bc			; put original build address into ix
				pop ix
				ld c, (hl)		; get table entries to process into BC
				inc hl
				ld b, (hl)
				inc hl
				ld a, b			; return if nothing to relocate
				or c
				ret z

LOADER_RelocateLoop:
				push bc			; preserve table entries to process
				
								; HL = table entry
								; DE = start of code to relocate
								; BC = table entries (preserved)

				ld c, (hl)		; BC = address to relocate
				inc hl
				ld b, (hl)
				inc hl
				push hl			; preserve next table entry
				push de			; preserve start of code to relocate
				
				ld l, e			; na = BC+DE
				ld h, d
				add hl, bc
				
				push hl			; preserve new address, HL = new address of which to add DE to
				ld c, (hl)		; r = (na)
				inc hl
				ld b, (hl)
				ld l, e
				ld h, d
				add hl, bc		; r = r+DE

				push ix			; subtract the original build address here to cater for builds that are not 0000
				pop bc
				xor a
				sbc hl, bc

				ld c, l
				ld b, h
				pop hl			; restore new address
				ld (hl), c		; (na) = r
				inc hl
				ld (hl), b
								
				pop de			; restore start of code to relocate
				pop hl			; restore next table entry
				pop bc			; restore table entries to process
				dec bc
				jp nz, LOADER_RelocateLoop
				ret	

					; ------------------------- Patch
					; -- parameters:
					; -- HL = patcher, DE = to be patched (aka patched)
					; -- return:
					; -- Z = false (i.e. NZ), E might contain the reason
					; -- Z = true (i.e. Z)
					; -- corrupt:
					; -- all other registers unknown

LOADER_Patch:					; jumpblock patcher
								; hl = patcher, de = to be patched (aka patched)
				push hl			; check patched is a PRIMAL file
				push de
				ex de, hl
				call SysCheckPrimal
				pop de
				pop hl
				ret nz

				push hl			; check patcher is a PRIMAL file
				push de
				call SysCheckPrimal
				pop de
				pop hl
				ret nz

				push hl			; patcher*, we will need this later to make the patched point to the patcher
				push de			; patched*

				push hl
				ld l, e			; de = patched
				ld h, d			;
				call GetPatchTableAddr	; de = patchtable of patched
				ex de, hl			;
				pop hl			; hl = patcher
				call GetPatchTableAddr	; hl = patch table of patcher	

LOADER_PatchLevelLoop:	
				; for each PatchLevel in hl.PatchTable
				; {
				ld e, (hl)		; de = patch level table
				inc hl
				ld d, (hl)
				inc hl
				ld a, e
				or d
				jr z, LOADER_PatchLevelLoopEnd		; return if at the end of the level list
				
				push hl				; for next iteration**
				
				; 	A = PatchLevel.Level;
				ld a, (hl)
				inc hl
				push hl
				call GetPatchTableLevel		; DE = destination of ldir, BC = potential length of ldir
				pop hl
				jp nz, LOADER_PatchNext			; if not found in patched then next

				push de				; push destination of ldir***
				ld e, (hl)			; DE is a anotherpotential length
				inc hl				;
				ld d, (hl)			;
				inc hl				;
				push hl
				call MathMinDEHL				; BC = min(PatchLevel.JumpBlockSize, PatchedLevel.JumpBlockSize);
				ld c, l				; BC = length of ldir
				ld b, h
				pop hl
				ld e, (hl)			; HL = start of ldir
				inc hl
				ld d, (hl)
				ex de, hl
				pop de				; DE = destination of ldir***
				ldir
				
LOADER_PatchNext:
				pop hl			; **
				jr LOADER_PatchLevelLoop

LOADER_PatchLevelLoopEnd:
				pop de			; *
				pop hl			; *
			
				push hl			; hl = patcher, de = patched
				ex de, hl			; hl = patched, de = patcher
				call GetLoaderAddr
				pop de
				ex de, hl

				ld (hl), e			; make the patched point to the patcher
				inc hl
				ld (hl), d

				xor a
				ret
		
					; ------------------------- LDRPCFile
					; -- parameters:
					; -- HL = filename address
					; -- DE = file load destination
					; -- BC = address of code to patch with
					; -- return:
					; -- bc = address of start of file
					; -- de = first address beyond end of file (for next file to load at)
					; -- Z if TRUE, NZ if FALSE
					; -- corrupt:
					; -- AF, BC, DE, HL

LOADER_LDRPCFile:					; load, decompress, relocate, patch file
									; get bios filesize, hl = address of filename
				push bc				; patcher code*
				push hl
				push de
				call SysFileSize
				; need to make a function to check how much memory left in the required memory type, perhaps a canfit function
				pop de
				pop hl
				; jp nz, OutOfMemory
								
				push de
				call SysFileLoad	; load bios, hl = address of filename, de = address to load file
				pop hl
				pop bc				; *
				jp nz, LoadFailed

				push bc				; *
				call SysDecompress	; decompress bios, hl = address of code to decompress, returns de
				pop bc				; *
				jp nz, DecompressFailed

				push bc				; *
				push de				; de = decompressed code
				ld l, e				; hl = address of relocation table
				ld h, d
				inc hl				; skip the jp to main
				inc hl				;
				inc hl				;
				
				ld e, (hl)			; de = relocation table
				inc hl
				ld d, (hl)
				
				pop hl				; hl = decompressed code

				push hl				; bc = the original build address here to cater for builds that are not 0000
				ld bc, ADDR_BUILD - LOADER
				add hl, bc
				ld c, (hl)
				inc hl
				ld b, (hl)
				inc hl
				
				push bc				; ix = amount to reserve at the end of this file that is loaded and relocated
				ld c, (hl)
				inc hl
				ld b, (hl)
				push bc
				pop ix
				pop bc
				pop hl
												
				ex de,hl			; de = decompressed code, hl = relocation table
				push hl				; push this for later returning as de** NEXT
				push de				; push this for later returning as bc*** PATCHED
				
				push ix
				call SysRelocate	; relocate bios, hl = address of relocation table, de = address of code to relocate, bc = original build address
				pop ix
				pop de				; ***
				pop hl				; **
				pop bc				; *
				jp nz, RelocationFailed

				push hl				; **
				push de				; ***
				push bc				; *
				pop hl				; *
				call SysPatch		; hl = address of code to patch with, de = address of code to patch
				pop bc				; ***
				pop de				; **
				jp nz, PatchFailed
				
				push ix				; put the amount to reserve into hl
				pop hl
				
				ld a, h				; skip initialisation and reservation if we have 0 to reserve
				or l
				jr z, LOADER_LDRPCFileSkip

									; initialise the reserved memory
				push de				; **
				push bc				; ***
				
				xor a
				ld c, l
				ld b, h
				ld h, d
				ld l, e
				ld (hl), a
				inc de
				ldir
								
				pop bc				; ***
				pop de				; **

				push ix				; add the reserved amount to de
				pop hl
				add hl, de
				ex de, hl

LOADER_LDRPCFileSkip:
				
				push de				; **
				push bc				; ***

									; call main but return to LOADER_LDRPCFileEnd
				ld hl, LOADER_LDRPCFileEnd
				push hl
				ld l, c
				ld h, b
				jp (hl)				

LOADER_LDRPCFileEnd:
				pop bc				; ***
				pop de				; **
				ret

				; ------------------------- PropertyPC
				; -- parameters:
				; -- none, but the zero-terminated string must be directly after the call
				; -- return:
				; -- PC points to the next instruction after the string terminator
				; -- HL contains the property value
				; -- corrupt:
				; -- all other registers unknown

LOADER_PropertyPC:
				pop hl
				ld e, l			; de = property to find
				ld d, h
				push de
				call LOADER_StrSkip
				pop de
				push hl			; new return address on the stack after the string
				
				ld hl, PropertyTable

LOADER_PropertyPCLoop1:			; for each sub table
				ld c, (hl)
				inc hl
				ld b, (hl)
				inc hl
				ld a, c
				or b
				jr z, LOADER_PropertyPCNotFound1
				
				push de			; *
				push hl			; **

				ex de, hl		; hl = property to find, de = table of property names
				
LOADER_PropertyPCLoop2:			; for each property to compare

				ld a, (de)		; check if end of property list
				or a
				jr z, LOADER_PropertyPCNextSubList
				
				push hl
				push de
				call LOADER_StrCompare
				pop de
				pop hl
				jr z, LOADER_PropertyPCFound
				
				ex de, hl
				push de
				call LOADER_StrSkip
				pop de
				ex de, hl
				inc de			; skip over the property value
				inc de
				
				jr LOADER_PropertyPCLoop2

LOADER_PropertyPCNextSubList:
				pop hl			; **
				pop de			; *
				jr LOADER_PropertyPCLoop1

LOADER_PropertyPCFound:
				pop de			; **
				pop de			; *
				ld e, (hl)		; de = property value
				inc hl
				ld d, (hl)
				ex de, hl		; hl = property value
				xor a
				ret

LOADER_PropertyPCNotFound1:
				ld a, 1
				or a
				ret
				
				; ------------------------- StrOutPC
				; -- parameters:
				; -- none, but the zero-terminated string must be directly after the call
				; -- return:
				; -- PC points to the next instruction after the string terminator
				; -- corrupt:
				; -- all other registers unknown

LOADER_StrOutPC:				; outputs a string pointed to by on the stack PC
				pop hl
				jp SysStrOutHL	
				inc hl	
				push hl	
				ret	
		
				; ------------------------- StrCompare
				; -- parameters:
				; -- HL = zero terminated string source of truth
				; -- DE = string to compare
				; -- return:
				; -- Z if true, NZ if not true
				; -- corrupt:
				; -- all other registers unknown

LOADER_StrCompare:	
				ex de, hl
				ld a, (de)
				cp (hl)
				ret nz						; false match return
				and a
				ret z						; end of string return
				inc hl
				inc de
				jr LOADER_StrCompare
			
				; ------------------------- StrLen
				; -- parameters:
				; -- HL = zero terminated string
				; -- return:
				; -- BC = length
				; -- corrupt:
					; -- all other registers unknown

LOADER_StrLen:	ld bc, 0

LOADER_StrLenLoop1:	
				ld a, (hl)
				and a
				ret z
				inc bc
				inc hl
				jr LOADER_StrLenLoop1

				; ------------------------- StrSkip
				; -- parameters:
				; -- HL = zero terminated string
				; -- return:
				; -- HL = address following the zero of the zero-terminated string
				; -- corrupt:
				; -- all other registers unknown

LOADER_StrSkip:	xor a
				cpir
				inc hl
				ret

Main:
				call PS_RAMInit		; initialise MemoryTable
				call CopyBufferInit	; initialise the Copy Buffer

				ld de, END_OF_LOADER ; location to put first loaded file
				ld bc, LOADER		; code to patch with initially

				ld hl, FILENAME_MEM
				call LOADER_LDRPCFile	; load, decompress, relocate, patch, call MEM
				jr nz, MainEnd

				ld hl, FILENAME_BIOS
				call LOADER_LDRPCFile	; load, decompress, relocate, patch, call BIOS
				jr nz, MainEnd

				ld hl, FILENAME_KERNEL
				call LOADER_LDRPCFile	; load, decompress, relocate, patch, call KERNEL
				jr nz, MainEnd

				ld hl, FILENAME_SHELL
				call LOADER_LDRPCFile	; load, decompress, relocate, patch, call SHELL
				jr nz, MainEnd
				
				call SysPropertyPC
				db "HASCLIPARAMS", 0
				jr nz, MainEnd
				cp "Y"
				jr nz, MainEnd
					; we have CLI parameters

MainEnd:
				ret	
				
DecompressFailed:
				call SysStrOutPC
				db "Decompress Failed.", 0
				ret

LoadFailed:		call SysStrOutPC
				db "Load Failed.", 0
				ret

OutOfMemory:	call SysStrOutPC
				db "Out Of Memory.", 0
				ret

PatchFailed:	call SysStrOutPC
				db "Patch Failed.", 0
				ret

RelocationFailed:
				call SysStrOutPC
				db "Relocation Failed.", 0
				ret

FILENAME_MEM:	db "MEM.PRM", 0
FILENAME_BIOS:	db "BIOS.PRM", 0
FILENAME_KERNEL:db "KERNEL.PRM", 0
FILENAME_SHELL:	db "SHELL.PRM", 0
