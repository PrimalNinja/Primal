;#dialect=RASM

								; WARNING NO CODE FROM HERE IN THIS FILE

								; patch data
PatchTable:		dw PatchLevel1, PatchLevel2, 0

				; API level, jumpblock size in bytes, address of jumpblock
PatchLevel1:	dw 1, (JUMPBLOCKLEVEL2 - JUMPBLOCKLEVEL1), JUMPBLOCKLEVEL1
PatchLevel2:	dw 2, (JUMPBLOCKEND - JUMPBLOCKLEVEL2), JUMPBLOCKLEVEL2

JumpBlock:						; jumpblock to be patched

JUMPBLOCKLEVEL1:				; API Level 1

SysError:		jp 0
SysMemTable:	jp 0
SysRAMSize:		jp 0
SysCommandLine:	jp 0
SysTerminate:	jp 0
SysFileExists:	jp 0
SysFileSize:	jp 0
SysFileDelete:	jp 0
SysFileLoad:	jp 0
SysDecompress:	jp 0
SysCheckPrimal:	jp 0
SysRelocate:	jp 0
SysPatch:		jp 0
SysLDRPCFile:	jp 0
SysCanSave:		jp 0
SysFileSave:	jp 0
SysBuild:		jp 0
SystemRestore:	jp 0
SystemSave:		jp 0
SysCharOut:		jp 0
SysStrOutHL:	jp 0
SysStrOutPC:	jp 0
SysCharIn:		jp 0
SysCharWait:	jp 0
SysStrIn:		jp 0
SysStrCompare:	jp 0
SysStrLen:		jp 0
SysStrSkip:		jp 0

JUMPBLOCKLEVEL2:				; API Level 2

SysDI:			jp MEM_DI
SysEI:			jp MEM_EI
SysBankCount:	jp PS_BankCount
SysBankSelect:	jp PS_BankSelect
SysBankUnSelect:jp PS_BankUnSelect
SysBankStart:	jp PS_BankStart
SysBankEnd:		jp PS_BankEnd
SysBankSize:	jp PS_BankSize
SysBankedRAMSize: jp MEM_BankedRAMSize

JUMPBLOCKEND:

								; WARNING CODE BELOW HERE ONLY IN THIS FILE

ADDR_EIDI:		db 0;

					; ------------------------- disable interrupts (supports nesting)
MEM_DI:			di
				push hl
				ld hl, ADDR_EIDI
				inc (hl)
				;push af
				;ld a, #c9
				;ld (adr_isr_intercept), a
				;pop af
				pop hl
				ret

MEM_EI:			push af
				push hl
				ld hl, ADDR_EIDI
				dec (hl)
				ld a, (ADDR_EIDI)
				and a
				jr nz, MEM_EIEND
				ei
				;ld a, #43
				;ld (adr_isr_intercept), a

MEM_EIEND:		pop hl
				pop af
				ret

MEM_BankedRAMSize:
				ld hl,RAM_SEL_PORT_COUNT

				ld bc,0
				ld de,0
				
MEM_BankedRAMSizeLoop:			
				ld a,l
				or h
				ret z
				
				push hl
				
				; add length HL to BCDE
				ld hl,RAM_BANK_SIZE
				add hl,de
				ex de,hl
				ld hl,0
				adc hl,bc
				ld c,l
				ld b,h

				pop hl
				dec hl
				jr MEM_BankedRAMSizeLoop

Main:			call PS_Initialise
				ret	
