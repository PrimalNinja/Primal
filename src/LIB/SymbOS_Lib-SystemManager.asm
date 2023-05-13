;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                 S Y M B O S   S Y S T E M   L I B R A R Y                  @
;@                        - SYSTEM MANAGER FUNCTIONS -                        @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author     Prodatron / Symbiosis
;Date       18.10.2021

;Converted to SjAsmPlus by NYYRIKKI
;Download the original from https://symbos.de

;The system manager is responsible for starting and stopping applications and
;it also provides several dialogue services.
;This library supports you in using the system manager functions.

;The existance of
;- "App_Process_ID" (a byte, where the ID of the applications process is stored)
;- "Message_Buffer" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;is required.


;### SUMMARY ##################################################################

; call SySystem_PRGRUN      ;Starts an application or opens a document
; call SySystem_PRGEND      ;Stops an application and frees its resources
; call SySystem_EXIT        ;Stops your own application and frees its resources
; call SySystem_PRGSRV      ;Manages shared services or finds applications
; call SySystem_SYSWRN      ;Opens an info, warning or confirm box
; call SySystem_SELOPN      ;Opens the file selection dialogue
; call SySystem_HLPOPN      ;Opens the help file for this application (##!!## missing doc)


;### MAIN FUNCTIONS ###########################################################

      ifused SySystem_PRGRUN
SySystem_PRGRUN
;******************************************************************************
;*** Name           Program_Run_Command
;*** Input          HL = File path and name address
;***                A  = [Bit0-3] File path and name ram bank (0-15)
;***                     [Bit7  ] Flag, if system error message should be
;***                              suppressed
;*** Output         A  = Success status
;***                     0 = OK
;***                     1 = File does not exist
;***                     2 = File is not an executable and its type is not
;***                         associated with an application
;***                     3 = Error while loading (see P8 for error code)
;***                     4 = Memory full
;***                - If success status is 0:
;***                L  = Application ID
;***                H  = Process ID (the applications main process)
;***                - If success status is 3:
;***                L  = File manager error code
;*** Destroyed      F,BC,DE,IX,IY
;*** Description    Loads and starts an application or opens a document with a
;***                known type by loading the associated application first.
;***                If Bit7 of A is not set, the system will open a message box,
;***                if an error occurs during the loading process.
;***                If the operation was successful, you will find the
;***                application ID and the process ID in L and H. If it failed
;***                because of loading problems L contains the file manager
;***                error code.
;******************************************************************************
        ld c,MSC_SYS_PRGRUN
        call SySystem_SendMessage
SySPRn1 call SySystem_WaitMessage
        cp MSR_SYS_PRGRUN
        jr nz,SySPRn1
        ld a,(Message_Buffer+1)
        ld hl,(Message_Buffer+8)
        ret
      endif

      ifused SySystem_PRGEND
SySystem_PRGEND
;******************************************************************************
;*** Name           Program_End_Command
;*** Input          L  = Application ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Stops an application and releases all its used system
;***                resources. This command first stops all processes of the
;***                application. After this all open windows will be closed and the
;***                reserved memory will be released.
;***                Please note, that this command can't release memory, stop
;***                processes and timers or close windows, which are not
;***                registered for the application. Such resources first have
;***                to be released by the application itself.
;******************************************************************************
        ld c,MSC_SYS_PRGEND
        jp SySystem_SendMessage
      endif

      ifused SySystem_EXIT
SySystem_EXIT ; (Added by: NYYRIKKI)
;******************************************************************************
;*** Name           Program_Exit_Command
;*** Input          -
;*** Output         No
;*** Destroyed      All
;*** Description    Stops your own application and releases all its used system
;***                resources. This command first stops all processes of the
;***                application. After this all open windows will be closed and
;***                the reserved memory will be released.
;***                Please note, that this command can't release memory, stop
;***                processes and timers or close windows, which are not
;***                registered for the application. Such resources first have
;***                to be released by the application itself.
;******************************************************************************
        ld a,(App_Process_ID)
        ld l,a
        ld c,MSC_SYS_PRGEND
        call SySystem_SendMessage
.Death_Spiral
        rst #30
        jr .Death_Spiral
      endif

      ifused SySystem_PRGSRV
SySystem_PRGSRV
;******************************************************************************
;*** Name           Program_SharedService_Command
;*** Input          E  = Command type
;***                     0 = search application or shared service
;***                     1 = search, start and use shared service
;***                     2 = release shared service
;***                - if E is 0 or 1:
;***                HL = Address of the 12byte application ID string
;***                - if E is 0 or 1:
;***                A  = Ram bank (0-15) of the 12byte application ID string
;***                - if E is 2:
;*** Output         A  = Result status
;***                     0 = OK
;***                     5 = application or shared service not found (can only
;***                         occur on command type 0)
;***                     1-4=error while starting shared service; same codes
;***                         like in MSR_SYS_PRGRUN, please read there for a
;***                         detailed description
;***                - If command type was 0 or 1, and result status is 0:
;***                L  = Application ID
;***                H  = Process ID (the applications main process)
;***                - If result status is 3:
;***                L  = File manager error code
;*** Destroyed      F,BC,DE,IX,IY
;*** Description    This function can be used to find, start and release shared
;***                services or to find applications.
;***                For a detailed description please read chapter "System
;***                Manager", "Program_SharedService_Command" in the SymbOS
;***                Developer Documentation.
;******************************************************************************
        ld c,MSC_SYS_PRGSRV
        call SySystem_SendMessage
SySPSr1 call SySystem_WaitMessage
        cp MSR_SYS_PRGSRV
        jr nz,SySPSr1
        ld a,(Message_Buffer+1)
        ld hl,(Message_Buffer+8)
        ret
      endif

      ifused SySystem_SYSWRN
SySystem_SYSWRN
;******************************************************************************
;*** Name           Dialogue_Infobox_Command
;*** Input          HL = Content data address (#C000-#FFFF)
;***                A  = Content data ram bank (0-15)
;***                B  = [Bit0-2] Number of buttons (1-3)
;***                              1 = "OK" button
;***                              2 = "Yes", "No" buttons
;***                              3 = "Yes", "No", "Cancel" buttons
;***                     [Bit3-5] Titletext
;***                              0 = default (bit7=[0]"Error!"/[1]"Info")
;***                              1 = "Error!"
;***                              2 = "Info"
;***                              3 = "Warning"
;***                              4 = "Confirmation"
;***                     [Bit6  ] Flag, if window should be modal window
;***                     [Bit7  ] Box type
;***                              0 = default (warning [!] symbol)
;***                              1 = info (own symbol will be used)
;***                DE = 0 or data record of the caller window; the dialogue
;***                     window will be a modal window of it, during its open
;*** Content data   00  1W  Address of text line 1
;***                02  1W  4 * [text line 1 pen] + 2
;***                04  1W  Address of text line 2
;***                06  1W  4 * [text line 2 pen] + 2
;***                08  1W  Address of text line 3
;***                10  1W  4 * [text line 3 pen] + 2
;***                - if E[bit7] is 1:
;***                12  1W  Address of symbol (24x24 pixel SymbOS graphic format)
;*** Output         A  = Result status
;***                     0 -> The infobox is currently used by another
;***                          application. It can only be opened once at the
;***                          same time, if it's not a pure info message (one
;***                          button, not a modal window). The user should
;***                          close the other infobox first before it can be
;***                          opened again by the application.
;***                     2 -> The user clicked "OK".
;***                     3 -> The user clicked "Yes".
;***                     4 -> The user clicked "No".
;***                     5 -> The user clicked "Cancel" or the close button.
;***                     Please note -> if the alert is no modal window and
;***                              contains only one button, it will always return 0
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens an info, warning or confirm box and displays three line
;***                of text and up to three click buttons.
;***                If Bit7 of B is set to 1, you can specify an own symbol, which
;***                will be showed left to the text. If this bit is not set, a "!"-
;***                warning symbol will be displayed.
;***                If Bit6 of B is set to 1, the window will be opened as a modal
;***                window, and you will receive a message with its window number
;***                (see MSR_SYS_SYSWRN).
;***                Please note, that the content data must always be placed in the
;***                transfer ram area (#C000-#FFFF). The texts itself and the
;***                optional graphic must always be placed inside a 16K (data ram
;***                area).
;***                As the text line pen, you should choose 1, so 6 would be the
;***                correct value.
;***                For more information about the mentioned memory types (data,
;***                transfer) see the "applications" chapter.
;***                For more information about the SymbOS graphic format see the
;***                "desktop manager data records" chapter.
;******************************************************************************
        ld (SySWrnW),de
        ld e,b
        ld c,MSC_SYS_SYSWRN
        push bc
        call SySystem_SendMessage
        pop af
        and 7+64
        dec a
        ret z
SySWrn1 call SySystem_WaitMessage
        cp MSR_SYS_SYSWRN
        jr nz,SySWrn1
        ld ix,(SySWrnW)
        db #dd:ld a,l
        db #dd:or h
        ld c,0
        jr z,SySWrn2
        ld (ix+51),c
        inc c
SySWrn2 ld a,(Message_Buffer+1)
        cp 1
        ret nz
        dec c
        jr nz,SySWrn1
        ld a,(Message_Buffer+2)
        ld (ix+51),a
        jr SySWrn1
SySWrnW dw 0
      endif

      ifused SySystem_SELOPN
SySystem_SELOPN
;******************************************************************************
;*** Name           Dialogue_FileSelector_Command
;*** Input          HL = File mask, path and name address (#C000-#FFFF)
;***                     00  3B  File extension filter (e.g. "*  ")
;***                     03  1B  0
;***                     04 256B path and filename
;***                A  = [Bit0-3] File mask, path and name ram bank (0-15)
;***                     [Bit6  ] Flag, if "open" (0) or "save" (1) dialogue
;***                     [Bit7  ] Flag, if file (0) or directory (1) selection
;***                C  = Attribute filter
;***                     Bit0 = 1 -> don't show read only files
;***                     Bit1 = 1 -> don't show hidden files
;***                     Bit2 = 1 -> don't show system files
;***                     Bit3 = 1 -> don't show volume ID entries
;***                     Bit4 = 1 -> don't show directories
;***                     Bit5 = 1 -> don't show archive files
;***                IX = Maximum number of directory entries
;***                IY = Maximum size of directory data buffer
;***                DE = Data record of the caller window; the file selector
;***                     window will be a modal window of it, during its open)
;*** Output         A  = Success status
;***                     0 -> The user choosed a file and closed the dialogue
;***                          with "OK". The complete file path and name can be
;***                          found in the filepath buffer of the application.
;***                     1 -> The user aborted the file selection. The content
;***                          of the applications filepath buffer is unchanged.
;***                     2 -> The file selection dialogue is currently used by
;***                          another application. It can only be opened once
;***                          at the same time. The user should close the
;***                          dialogue first before it can be opened again by
;***                          the application.
;***                     3 -> Memory full. There was not enough memory
;***                          available for the directory buffer and/or the
;***                          list data structure.
;***                     4 -> No window available. The desktop manager couldn't
;***                          open a new window for the dialogue, as the
;***                          maximum number of windows (32) has already been
;***                          reached.
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens the file selection dialogue. In this dialogue the user
;***                can move through the directory structure, change the drive and
;***                search and select a file or a directory for opening or saving.
;***                If you specify a path, the dialogue will start directly in the
;***                directory. If you append a filename, too, it will be used as
;***                the preselected file.
;***                You can filter the entries of the directory by attributes and
;***                filename extension. We recommend always to set Bit3 of the
;***                attribute filter byte.
;***                The File mask/path/name string (260 bytes) must always be
;***                placed in the transfer ram area (#C000-#FFFF). For more
;***                information about this memory types see the "applications"
;***                chapter.
;***                Please note, that the system will reserve memory to store the
;***                listed directory entries and the data structure of the list.
;***                With IX and IY you can choose, how much memory should be used.
;***                We recommend to set the number of entries between 100 and 200
;***                (Amsdos supports a maximum amount of 64 entries) and to set the
;***                data buffer between 5000 and 10000.
;******************************************************************************
        ld (SySSOpW+2),de
        push iy
        ld iy,Message_Buffer
        ld (Message_Buffer+6),a
        ld (iy+7),c
        ld (Message_Buffer+8),hl
        db #dd:ld a,l
        ld (Message_Buffer+10),a
        db #dd:ld a,h
        ld (Message_Buffer+11),a
        pop de
        ld (Message_Buffer+12),de
        ld c,MSC_SYS_SELOPN
        call SySystem_SendMessage
SySSOp1 call SySystem_WaitMessage
        cp MSR_SYS_SELOPN
        jr nz,SySSOp1
SySSOpW ld ix,0
        ld (ix+51),0
        ld a,(Message_Buffer+1)
        cp -1
        ret nz
        ld a,(Message_Buffer+2)
        ld (ix+51),a
        jr SySSOp1
      endif

      ifused SySystem_HLPOPN
;******************************************************************************
;*** Name           Help_Init
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Initializes the path for the help file. This has to be called
;***                before using the Help_Open function (see SySystem_HLPOPN).
;***                As it accesses the applications path string at the end of the
;***                code area you should call this function after the application
;***                started in case you use additional memory behind the code area
;***                later for other stuff.
;***                For more information see SySystem_HLPOPN.
;******************************************************************************
SySystem_HLPFLG db 0    ;flag, if HLP-path is valid
SySystem_HLPPTH db "%help.exe "
SySystem_HLPPTH1 ds 128
SySHInX db ".HLP",0

SySystem_HLPINI
        ld hl,(Code_Area_Start)
        ld de,Code_Area_Start
        dec h
        add hl,de                   ;HL = CodeEnd = Command line
        ld de,SySystem_HLPPTH1
        ld bc,0
        ld ixl,128
SySHIn1 ld a,(hl)
        or a
        jr z,SySHIn3
        cp " "
        jr z,SySHIn3
        cp "."
        jr nz,SySHIn2
        ld c,e
        ld b,d
SySHIn2 ld (de),a
        inc hl
        inc de
        db #dd:dec l
        ret z
        jr SySHIn1
SySHIn3 ld a,c
        or b
        ret z
        ld e,c
        ld d,b
        ld hl,SySHInX
        ld bc,5
        ldir
        ld a,1
        ld (SySystem_HLPFLG),a
        ret

;******************************************************************************
;*** Name           Help_Open
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Opens the applications help file and displays it in the
;***                SymbOS help document browser.
;***                The help file has to have the same filename like the
;***                applications main EXE file with the file extension HLP, and
;***                it has to be located in the same directory.
;***                You have to call SySystem_HLPINI once when starting the
;***                application before you can use SySystem_HLPOPN.
;******************************************************************************
SySystem_HLPOPN
        ld a,(SySystem_HLPFLG)
        or a
        ret z
        ld hl,SySystem_HLPPTH
        ld a,(App_Bank_Number)
        jp SySystem_PRGRUN
      endif


;### SUB ROUTINES #############################################################
      ifused SySystem_SendMessage
SySystem_SendMessage
;******************************************************************************
;*** Input          C       = Command
;***                HL,A,DE = additional Parameters
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the system manager
;******************************************************************************
        ld iy,Message_Buffer
        ld (iy+0),c
        ld (Message_Buffer+1),hl
        ld (Message_Buffer+3),a
        ld (Message_Buffer+4),de
        ld ixh,PRC_ID_SYSTEM
        ld a,(App_Process_ID)
        ld ixl,a
        rst #10
        ret
      endif

SySystem_WaitMessage
      ifused SySystem_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,Message_Buffer
.SySWMs1
        ld ixh,PRC_ID_SYSTEM
        ld a,(App_Process_ID)
        ld ixl,a
        rst #08             ;wait for a system manager message
        db #dd:dec l
        jr nz,.SySWMs1
        ld a,(Message_Buffer+0)
        ret
      endif