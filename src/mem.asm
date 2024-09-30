;#dialect=RASM

								; WARNING NO CODE FROM HERE IN THIS FILE

								; patch data
PatchTable:		dw PatchLevel1, 0

				; API level, jumpblock size in bytes, address of jumpblock
PatchLevel1:	dw 1, (JUMPBLOCKLEVEL1END - JUMPBLOCKLEVEL1), JUMPBLOCKLEVEL1

JumpBlock:						; jumpblock to be patched

JUMPBLOCKLEVEL1:				; API Level 1

SysCharIn:		jp 0
SysCharOut:		jp 0
SysCharWait:	jp 0
SysDI:			jp 0
SysEI:			jp 0
SysFileDelete:	jp 0
SysFileExists:	jp 0
SysFileLoad:	jp 0
SysFileSave:	jp 0
SysFileSize:	jp 0
SysStrInput:	jp 0
SysStrOutHL:	jp 0
SystemRestore:	jp 0
SystemSave:		jp 0
SysTerminate:	jp 0

SysBuild:		jp 0
SysCheckPrimal:	jp 0
SysCommandLine:	jp 0
SysCopyBuffer: 	jp 0
SysCopyBufferSize: jp 0
SysDecompress:	jp 0
SysDriverList:	jp 0
SysError: 		jp 0
SysHeapAlloc:	jp 0
SysHeapFree:	jp 0
SysHeapInit:	jp 0
SysHeapList:	jp 0
SysLDRPCFile:	jp 0
SysListAppend:	jp 0
SysListDelete:	jp 0
SysListInit:	jp 0
SysListPrepend:	jp 0
SysListSearch:	jp 0
SysListSort:	jp 0
SysListTraverse: jp 0
SysMathMinDEHL:	jp 0
SysMemTable:	jp 0
SysPatch:		jp 0
SysPropertyPC:	jp 0
SysRAMSize:		jp 0
SysRelocate:	jp 0
SysStrCompare:	jp 0
SysStrLen:		jp 0
SysStrOutPC:	jp 0
SysStrSkip:		jp 0

PATCHBACKDESTINATION:

SysBank:		jp 0
SysBankCount:	jp 0
SysBankedRAMSize: jp 0
SysBankEnd:		jp 0
SysBankSelect:	jp 0
SysBankSize:	jp 0
SysBankStart:	jp 0
SysBankUnSelect:jp 0
SysMemCopyF2F:	jp 0
SysMemCopyF2N:	jp 0
SysMemCopyN2F:	jp 0

JUMPBLOCKLEVEL1END:	

PATCHBACKSTART:					; API Level 1 (patch back)

				jp MEM_Bank
				jp PS_BankCount
				jp MEM_BankedRAMSize
				jp PS_BankEnd
				jp PS_BankSelect
				jp PS_BankSize
				jp PS_BankStart
				jp PS_BankUnSelect
				jp MEM_MemCopyF2F
				jp MEM_MemCopyF2N
				jp MEM_MemCopyN2F

PATCHBACKEND:
								; WARNING CODE BELOW HERE ONLY IN THIS FILE

ADDR_CURRENTBANK: db 0			; the currently selected bank

					; ------------------------- Bank
					; -- parameters:
					; -- 	none
					; --
					; -- return:
					; -- 	A = the currently selected bank
					; -- 	all other registers preserved

MEM_Bank:		ld a, (ADDR_CURRENTBANK)
				ret

					; ------------------------- BankSize
					; -- parameters:
					; -- 	none
					; -- 
					; -- return:
					; -- 	BCDE = size of all banked RAM
					; -- 	all other registers unknown

MEM_BankedRAMSize:
				ld hl, RAM_SEL_PORT_COUNT

				ld bc, 0
				ld de, 0
				
MEM_BankedRAMSizeLoop:			
				ld a, l
				or h
				ret z
				
				push hl
				
				; add length HL to BCDE
				ld hl, RAM_BANK_SIZE
				add hl, de
				ex de, hl
				ld hl,0
				adc hl, bc
				ld c, l
				ld b, h

				pop hl
				dec hl
				jr MEM_BankedRAMSizeLoop

					; ------------------------- Copy Far to Far (via copy buffer)
					; -- parameters:
					; -- 	D = source bank
					; -- 	IX = source address
					; -- 	E = destination bank
					; -- 	IY = destination address
					; -- 	BC = number of bytes to copy
					; -- 
					; -- return:
					; -- 	all other registers unknown
					
MEM_MemCopyF2F:	ld a, d		; if both source and destination banks are the same, just go to the fast near copy
				or e
				jp z, MEM_MemCopyF2FNear
				
				call SysDI
				call SysBank
				push af		; preserve current bank
MEM_MemCopyF2FLoop:
				ld a, c		; end if BC = 0
				or b
				jr z, MEM_MemCopyF2FEnd

				push bc		; preserve total size to copy
				
							; iteration bc = min(copybuffersize, bc)
				push de
				call SysCopyBufferSize
				ld de, bc
				call SysMathMinDEHL
				ld bc, hl
				pop de		; de = bank numbers
				
							; select source bank
				push bc
				push de
				push ix
				push iy
				ld a, d
				call SysBankSelect
				pop iy		; iy = destination
				pop ix		; ix = source
				pop de		; de = bank numbers
				pop bc		; bc = iteration copysize
				
							; copy from source to copybuffer size iteration copysize
				push bc
				push de

				call SysCopyBuffer
				ld de, ix
				ex de, hl
				ldir
				
				pop de		; de = bank numbers
				pop bc		; bc = iteration copysize
				
							; select destination bank
				push bc
				push de
				push ix
				push iy
				ld a, e
				call SysBankSelect
				pop iy		; iy = destination
				pop ix		; ix = source
				pop de		; de = bank numbers
				pop bc		; bc = iteration copysize

							; copy from copybuffer to destination size iteration copysize
				push bc
				push de

				call SysCopyBuffer
				ld de, iy
				ldir

				pop de		; de = bank numbers
				pop bc		; bc = iteration copysize
				
							; add iteration copysize to ix
				ld hl, bc	; hl = copybuffersize
				add hl, ix
				ld ix, hl
							; add iteration copysize to iy
				ld hl, bc	; hl = copybuffersize
				add hl, iy
				ld iy, hl
							; subtract copysize from bc
				pop hl		; hl = total iteration copysize
				add hl, bc
				ld bc, hl

				jr MEM_MemCopyF2FLoop
				
MEM_MemCopyF2FEnd:
				pop af		; restore current bank
				call SysBankSelect
				call SysEI
				ret
				
MEM_MemCopyF2FNear:
				ld hl, ix
				ld de, iy
				ldir
				ret

					; ------------------------- Copy Far to Near (via copy buffer)
					; -- parameters:
					; -- 	A = source bank
					; -- 	HL = source address
					; -- 	DE = destination address
					; -- 	BC = number of bytes to copy
					; --
					; -- return:
					; -- 	all other registers unknown
					
MEM_MemCopyF2N:	push hl
				pop ix
				
				push de
				pop iy

				ld d, a
				call SysBank
				ld e, a
				
				jp MEM_MemCopyF2F
				
					; ------------------------- Copy Near to Far (via copy buffer) 
					; -- parameters:
					; -- 	HL = source address
					; -- 	A = destination bank
					; -- 	DE = destination address
					; -- 	BC = number of bytes to copy
					; --
					; -- return:
					; -- 	all other registers unknown
					
MEM_MemCopyN2F:	push hl
				pop ix
				
				push de
				pop iy
				
				ld e, a
				call SysBank
				ld d, a
				
				jp MEM_MemCopyF2F


Main:
								; patch this component as the loader patched it already
				ld hl, PATCHBACKSTART
				ld bc, PATCHBACKEND - PATCHBACKSTART
				ld de, PATCHBACKDESTINATION
				ldir

				call PS_Initialise
				ret	
