;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                 S Y M B O S   S Y S T E M   L I B R A R Y                  @
;@                    - SYMSHELL TEXT TERMINAL FUNCTIONS -                    @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author     Prodatron / Symbiosis
;Date       18.10.2021

;Converted to SjAsmPlus by NYYRIKKI
;Download the original from https://symbos.de

;SymShell provides a program environment with a text terminal. The input and
;output can be redirected from and to different sources and destinations.
;This library supports you in using the SymShell functions.

;The existance of
;- "App_Process_ID" (a byte, where the ID of the applications process is stored)
;- "Message_Buffer" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;- "App_Bank_Number" (a byte, where the number of the applications' ram bank (0-15)
;  is stored)
;- "Code_Area_Start" (the first byte/word of the header/code area, which also
;  includes the total length of the code area)
;is required.


;### SUMMARY ##################################################################

; call SyShell_PARALL       ;Fetches parameters/switches from command line
; call SyShell_PARSHL       ;Parses SymShell info switch
; call SyShell_PARFLG       ;Validates present switches
; call SyShell_CHRINP       ;Reads a char from the input source
; call SyShell_STRINP       ;Reads a string from the input source
; call SyShell_CHROUT       ;Sends a char to the output destination
; call SyShell_STROUT       ;Sends a string to the output destination
; call SyShell_PTHADD       ;Adds a path component to an existing path
; call SyShell_EXIT         ;Informs SymShell about an exit event


;### MAIN FUNCTIONS ###########################################################
      ifused SyShell_PARALL
SyShell_PARALL
;******************************************************************************
;*** Name           SymShell_Parameters_All
;*** Input          -
;*** Output         (SyShell_CmdParas) = list of parameters; 3 bytes/entry
;***                                     Byte0,1 = pointer
;***                                     Byte2   = length
;***                (SyShell_CmdSwtch) = list of switches (see above; a switch
;***                                     is recognized with a % at the
;***                                     beginning, which is skipped in this
;***                                     list)
;***                D                  = number of parameters
;***                E                  = number of switches
;***                ZF                 = if 1, no parameters and switches
;*** Destroyed      AF,BC,HL,IX,IY
;*** Description    This function fetches all parameters and switches from the
;***                command line and generates two pointer tables. A switch is
;***                recognized with a leading "%" char. A pointer to a switch
;***                links to the first char behind the %. All parameters and
;***                switches are zero terminated.
;*** Example        A\>EXAMPLE.COM filename.ext %x %all hello123
;***                This will generate two entries in the parameter table:
;***                - pointer to "filename.ext", length=12
;***                - pointer to "hello123", length=8
;***                And two entries in the switch table:
;***                - pointer to "x", length=1
;***                - pointer to "all", length=3
;***                Please note, that SymShell itself will add an own switch to
;***                the command line (see "SymShell_Parameters_Shell").
;******************************************************************************
        ld hl,(Code_Area_Start)
        ld de,Code_Area_Start
        dec h
        add hl,de                   ;HL = CodeEnd = Command line
        ld ix,SyShell_CmdParas      ;IX = Parameter List
        ld iy,SyShell_CmdSwtch      ;IY = Switch    List
        ld bc,8*256+8       ;B=8-number of parameters, C=8-number of switches
SyHPAl1 push bc
        call SyHPAl2
        pop bc
        jr z,SyHPAl7
        ld a,(hl)
        cp "%"
        jr z,SyHPAl6
        ld (ix+0),l         ;Parameter
        ld (ix+1),h
        push hl
        call SyHPAl4
        pop hl
        ld (ix+2),e
        ld de,3
        add ix,de
        dec b
        jr nz,SyHPAl1
        jr SyHPAl7
SyHPAl6 inc hl              ;Switch
        ld (iy+0),l
        ld (iy+1),h
        push hl
        call SyHPAl4
        pop hl
        ld (iy+2),e
        ld de,3
        add iy,de
        dec c
        jr nz,SyHPAl1
SyHPAl7 ld a,8
        sub c
        ld e,a
        ld a,8
        sub b
        ld d,a
        or e
        ret
;HL=position inside the string -> jump to next string -> HL=next string, ZF=1 end reached
SyHPAl2 ld a,(hl)
        inc hl
        or a
        ret z
        cp " "
        jr nz,SyHPAl2
        dec hl
        ld (hl),0
SyHPAl3 inc hl
        ld a,(hl)
        cp " "
        jr z,SyHPAl3
        ld a,1
        or a
        ret
;HL=position inside the string -> E=length until the end
SyHPAl4 ld e,0
SyHPAl5 ld a,(hl)
        or a
        ret z
        cp " "
        ret z
        inc e
        inc hl
        jr SyHPAl5
      endif

      ifused SyShell_PARSHL
SyShell_PARSHL
;******************************************************************************
;*** Name           SymShell_Parameters_Shell
;*** Input          (SyShell_CmdSwtch) = list of switches
;***                E                  = number of switches
;*** Output         CF     = error state (0 = ok, 1 = no valid shell parameters
;***                         found; application should quit itself at once)
;***                (SyShell_PrcID) = shell process ID
;***                (SyShell_TermX) = width in chars of the terminal window
;***                (SyShell_TermY) = height in chars of the terminal window
;***                (SyShell_Vers)  = shell version (e.g. 21 decimal for 2.1)
;*** Destroyed      AF,BC,DE,HL,IX
;*** Description    This function parses the SymShell info switch from the
;***                command line. The info switch is built like this:
;***                %spPPXXYYVV
;***                PP is the process ID of SymShell itself, XX and YY is the
;***                size of the text terminal window and VV is the version of
;***                SymShell. If VV is not present, it is a version below 2.0
;***                and (SyShell_Vers) will stay 0.
;***                Every SymShell-based application has to parse this switch
;***                with the help of this function, as at least the process ID
;***                is required for any communication with SymShell. You have
;***                to call SyShell_PARALL first before you call this function,
;***                as the switch table already has to be present.
;***                For additional information see also "Symshell Command Line
;***                Information" in the chapter "SymShell Text Terminal" of the
;***                Symbos Developer Documentation.
;******************************************************************************
        ld a,e
        or a
        jr z,SyHPSh6            ;no switches -> error
        ld ix,SyShell_CmdSwtch
        ld bc,3
SyHPSh1 ld l,(ix+0)
        ld h,(ix+1)
        ld a,(hl)
        cp "s"
        jr nz,SyHPSh2
        inc hl
        ld a,(hl)
        cp "p"
        jr  z,SyHPSh3
SyHPSh2 add ix,bc
        dec e
        jr nz,SyHPSh1
SyHPSh6 scf                     ;no Shell-Data -> error
        ret
SyHPSh3 inc hl
        call SyHPSh4
        ld (SyShell_PrcID),a
        call SyHPSh4
        ld (SyShell_TermX),a
        call SyHPSh4
        ld (SyShell_TermY),a
        ld a,(hl)
        or a
        ret z
        call SyHPSh4
        ld (SyShell_Vers),a
        or a
        ret
;(HL)=2digit number -> A=number, HL=HL+2
SyHPSh4 call SyHPSh5
        add a
        ld d,a
        add a:add a
        add d
        ld d,a
        call SyHPSh5
        add d
        ret
SyHPSh5 ld a,(hl)
        sub "0"
        cp 10
        inc hl
        ret c
        pop hl      ;clear stack
        pop hl
        scf         ;wrong number -> error
        ret
      endif

      ifused SyShell_PARFLG
SyShell_PARFLG
;******************************************************************************
;*** Name           SymShell_Parameters_Switches
;*** Input          (SyShell_CmdSwtch) = list of switches
;***                E                  = number of present switches
;***                IY                 = list with allowed switches
;***                                     word 0 = points to valid switch string
;***                                              (terminated by 0 or colon)
;***                                     word 1 = will be filled with pointer
;***                                              behind colon, if found
;***                                     list is terminated by a 0-word
;*** Output         CF = 0 -> all switches are valid; HL = bitfield of detected
;***                          switches
;***                CF = 1 -> invalid switch found; HL points to invalid switch
;***                          string (including the % char)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    This function validates the present switches with a list of
;***                allowed switches. Switches can have a parameter attached
;***                which is separated by a colon from the switch. If such a
;***                switch is found, the function will insert the pointer to
;***                its parameter into the validation list. If only valid
;***                switches have been found the function returns with a
;***                bitfield in HL of the present switches (bit0=1 -> first
;***                switch in the validation list is present), therefore the
;***                maximum amount of switches is 16.
;***                The function returns with an error, if an invalid switch
;***                has been found.
;******************************************************************************
        ld hl,0
        ld (SyHPFlb),hl
        ld a,e
        or a
        ret z
        ld b,e              ;b=number of present switches
        ld ix,SyShell_CmdSwtch
SyHPFl1 push iy         ;** present switch loop
        ld c,0              ;iy=validation list, c=number of valid switch
SyHPFl2 ld l,(iy+0)     ;** valid switch loop
        ld h,(iy+1)         ;hl=next valid switch
        ld e,(ix+0)         ;de=next present switch
        ld d,(ix+1)
        ld a,l
        or h
        jr nz,SyHPFl3
        pop hl
        dec de              ;switch not found in validation switch -> error
        ex de,hl
        scf
        ret
SyHPFl3 ld a,(de)           ;test, if shell switch
        cp "s"
        jr nz,SyHPFl9
        inc de
        ld a,(de)
        dec de
        cp "p"
        jr z,SyHPFla        ;yes -> ignore
SyHPFl8 ld a,(de)           ;compare switches
SyHPFl9 cp "A"
        jr c,SyHPFlc
        cp "Z"+1
        jr nc,SyHPFlc
        add "a"-"A"
SyHPFlc cp (hl)
        jr nz,SyHPFl7       ;not equal, compare with next valid
        inc hl
        inc de
        or a
        jr z,SyHPFl4
        cp ":"
        jr nz,SyHPFl8
        ld (iy+2),e         ;switch contains colon -> set pointer to parameter
        ld (iy+3),d
SyHPFl4 ld hl,1             ;switch found -> set bit
        inc c
SyHPFl5 dec c
        jr z,SyHPFl6
        add hl,hl
        jr SyHPFl5
SyHPFl6 ld de,(SyHPFlb)
        add hl,de
        ld (SyHPFlb),hl
SyHPFla ld de,3
        add ix,de
        pop iy
        djnz SyHPFl1
        ld hl,(SyHPFlb)
        ret                 ;all present switches are valid -> CF=0, HL=switch-bitfield
SyHPFl7 ld de,4             ;continue with next valid
        add iy,de
        inc c
        jr SyHPFl2

SyHPFlb dw 0                ;recognized switches
      endif

      ifused SyShell_CHRINP0
SyShell_CHRINP0 ld e,SyShell_CHRINP and 0
      endif
      ifused SyShell_CHRINP
SyShell_CHRINP
;******************************************************************************
;*** Name           SymShell_CharInput_Command
;*** Input          E  = Channel (0=Standard, 1=Keyboard)
;*** Output         CF = Error state (0 = ok, 1 = error; A = error code)
;***                - If error status is 0
;***                ZF = EOF status (0=EOF)
;***                - If error status is 0 and there is no EOF:
;***                A  = Char
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Reads a char from an input source. The input source can be
;***                the standard channel or the console keyboard. Usually the
;***                standard channel is the console keyboard, too, but it can also
;***                be a textfile or another source, if redirection or piping is
;***                active.
;***                If the keyboard is used, this function won't return as long as
;***                no key is pressed. If the user pressed Control+C or if the end
;***                of the file (EOF) has been reached, the EOF flag will be set.
;******************************************************************************
        ld bc,MSR_SHL_CHRINP*256+MSC_SHL_CHRINP
        call SyShell_DoCommand
        ret c
        ld a,(iy+2)
        ret
      endif

      ifused SyShell_STRINP0
SyShell_STRINP0 ld e,SyShell_STRINP and 0
      endif
      ifused SyShell_STRINP
SyShell_STRINP
;******************************************************************************
;*** Name           SymShell_StringInput_Command
;*** Input          E  = Channel (0=Standard, 1=Keyboard)
;***                HL = String buffer address (must have a size of 256 bytes)
;*** Output         CF = Error state (0 = ok, 1 = error; A = error code)
;***                - If error status is 0
;***                ZF = EOF status (0=EOF)
;***                - If error status is 0 and there is no EOF, the string
;***                  buffer contains the read line.
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Reads a string from an input source. The input source can be
;***                the standard channel or the console keyboard. Usually the
;***                standard channel is the console keyboard, too, but it can also
;***                be a textfile or another source, if redirection or piping is
;***                active.
;***                The maximum lenght of a string is 255 chars, so the buffer must
;***                have a size of 256 bytes (255 + terminator). A string is always
;***                terminated by 0.
;***                If the keyboard is used, this function won't return until the
;***                user typed in a text line and pressed the Return key. If the
;***                user pressed Control+C or if the end of the file (EOF) has been
;***                reached, the EOF flag will be set.
;******************************************************************************
        ld bc,MSR_SHL_STRINP*256+MSC_SHL_STRINP
        ld a,(App_Bank_Number)
        ld d,a
        jp SyShell_DoCommand
      endif

      ifused SyShell_CHROUT0
SyShell_CHROUT0 ld e,SyShell_CHROUT and 0
      endif
      ifused SyShell_CHROUT
SyShell_CHROUT
;******************************************************************************
;*** Name           SymShell_CharOutput_Command
;*** Input          E  = Channel (0=Standard, 1=Screen)
;***                D  = Char
;*** Output         CF = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a char to the output destination. The output destination
;***                can be the standard channel or the console text screen. Usually
;***                the standard channel is the console text screen, too, but it
;***                can also be a textfile or another destination, if redirection
;***                or piping is active.
;******************************************************************************
        ld bc,MSR_SHL_CHROUT*256+MSC_SHL_CHROUT
        jp SyShell_DoCommand
      endif


      ifused SyShell_STROUT0
SyShell_STROUT0 ld e,SyShell_STROUT and 0
      endif
      ifused SyShell_STROUT
SyShell_STROUT
;******************************************************************************
;*** Name           SymShell_StringOutput_Command
;*** Input          E  = Channel (0=Standard, 1=Screen)
;***                HL = String address (terminated by 0)
;*** Output         CF = Error state (0 = ok, 1 = error; A = error code)
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a string to the output destination. The output
;***                destination can be the standard channel or the console text
;***                screen. Usually the standard channel is the console text
;***                screen, too, but it can also be a textfile or another
;***                destination, if redirection or piping is active.
;***                A string has always to be terminated by 0.
;******************************************************************************
        ld a,(App_Bank_Number)
        ld d,a
        push hl
        xor a
        ld bc,255
        cpir
        ld a,254
        sub c       ;A=string length
        pop hl
        ret z
        ld bc,MSR_SHL_STROUT*256+MSC_SHL_STROUT
        jp SyShell_DoCommand
      endif

      ifused SyShell_PTHADD
SyShell_PTHADD
;******************************************************************************
;*** Name           SymShell_PathAdd_Command
;*** Input          DE = address of base path (0=actual shell path)
;***                HL = address of additional path component
;***                BC = buffer address for new full path
;***                     (must have a size of 256 bytes)
;*** Output         DE = position behind last char in new path (0-terminator)
;***                HL = position behind last / in new path
;***                A  = Bit[0]=1 -> new path ends with /
;***                     Bit[1]=1 -> new path contains wildcards
;*** Destroyed      F,BC,IX,IY
;*** Description    Adds a path component to a base path. The base path can be the
;***                current one, where the application has been started from, or
;***                another defined path. It should not end with a "/".
;***                The added path component can even start at the root directory
;***                or is consisting of a complete stand-alone path.
;***                Examples:
;***                base: "c:\symbos\apps", add: "..\music\mp3\lalala.mp3"
;***                   -> "c:\symbos\music\mp3\lalala.mp3"
;***                base: "a:\graphics\nature", add: "\symbos"
;***                   -> "a:\symbos"
;***                base: "c:\archive", add: "*.zip"
;***                   -> "c:\archive\*.zip"
;***                base: "a:\archive", add: "c:\symbos"
;***                   -> "c:\symbos"
;***                Both strings have to be 0-terminated as usual.
;***                After building the new path in the specified 256 byte buffer
;***                SymShell will return some useful information about the new
;***                path. You will receive the position of the 0-terminator as well
;***                as the position of the last "/" in the path. It may also be
;***                usefull to know, if the file at the end of the path contains
;***                wildcards ("*" and "?" chars).
;******************************************************************************
        ld a,(App_Bank_Number)
        ld (Message_Buffer+7),a
        ld a,b
        ld (Message_Buffer+6),a
        ld b,c
        ld c,MSC_SHL_PTHADD
        call SyShell_SendMessage
SyHPtA1 call SyShell_WaitMessage
        cp MSR_SHL_PTHADD
        jr nz,SyHPtA1
        ld de,(Message_Buffer+1)
        ld hl,(Message_Buffer+3)
        ld a,(Message_Buffer+5)
        ret
      endif

      ifused SyShell_EXIT
SyShell_EXIT
;******************************************************************************
;*** Name           SymShell_Exit_Command
;*** Input          E  = Exit type (0 = quit, 1 = blur)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    The application informs SymShell about an exit event.
;***                If an application quits itself, SymShell has to be informed
;***                about that, so that it can remove the application from its
;***                internal management table. In this case the exit type has to be
;***                0 ("quit").
;***                If an application doesn't require the focus inside the text
;***                terminal anymore, it has to send exit type 1 ("blur"). The
;***                background is, that SymShell can run multiple applications in
;***                the same text terminal at the same time. User text inputs will
;***                only be sent to the application which has been started at first
;***                until it releases the focus and goes into blur mode. In this
;***                case the next application or the command line interpreter of
;***                the shell itself will receive the focus (the user can force the
;***                shell to get back focus at once by appending "&" at the end of
;***                the command line).
;******************************************************************************
        ld c,MSC_SHL_EXIT
        jp SyShell_SendMessage
      endif

;### SUB ROUTINES #############################################################
      ifused SyShell_SendMessage
SyShell_SendMessage
;******************************************************************************
;*** Input          C  = Command
;***                DE = Parameter 1/2
;***                HL = Parameter 3/4
;***                B  = Parameter 5
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the SymShell process
;******************************************************************************
        ld iy,Message_Buffer
        ld (iy+0),c
        ld (Message_Buffer+1),de
        ld (Message_Buffer+3),hl
        ld (iy+5),b
        ld a,(SyShell_PrcID)
        ld ixh,a
        ld a,(App_Process_ID)
        ld ixl,a
        rst #10
        ret
      endif

      ifused SyShell_WaitMessage
SyShell_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      F,BC,DE,HL,IX
;*** Description    Waits for a response message from the SymShell process.
;******************************************************************************
        ld iy,Message_Buffer
SyHWMs1 ld a,(SyShell_PrcID)
        ld ixh,a
        ld a,(App_Process_ID)
        ld ixl,a
        rst #08             ;wait for a SymShell message
        db #dd:dec l
        jr nz,SyHWMs1
        ld a,(iy+0)
        ret
      endif

      ifused SyShell_DoCommand
SyShell_DoCommand
;******************************************************************************
;*** Input          C       = Command
;***                DE,HL,A = additional parameters
;***                B       = Response type
;*** Output         CF      = Error state (0 = ok, 1 = error, A = error code)
;***                ZF      = EOF status (0=EOF) [optional]
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Executes a complete SymShell command.
;******************************************************************************
        push bc
        ld b,a
        call SyShell_SendMessage
        pop bc
SyHGRs1 push bc
        call SyShell_WaitMessage
        pop bc
        cp b
        jr nz,SyHGRs2
        ld a,(iy+3)     ;Error state
        ld c,(iy+1)     ;EOF (0=no eof)
        cp 1
        ccf             ;CF=0 no error
        inc c
        dec c           ;ZF=0 EOF
        ret
SyHGRs2 push bc         ;wrong message (from another event) -> re-send
        ld a,(SyShell_PrcID)
        ld ixl,a
        ld a,(App_Process_ID)
        ld ixh,a
        rst #10
        rst #30
        pop bc
        jr SyHGRs1
      endif
      
;### GLOBAL VARIABLES #########################################################
      ifused SyShell_PrcID
SyShell_CmdParas   ds 8*3   ;command line parameters (1W address, 1B length)
SyShell_CmdSwtch   ds 8*3   ;command line switches
SyShell_PrcID      db 0     ;shell process ID
SyShell_TermX      db 0     ;x length in chars of the text terminal window
SyShell_TermY      db 0     ;y length in chars of the text terminal window
SyShell_Vers       db 0     ;SymShell version (e.g. 21 decimal for 2.1)
      endif