;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                 S Y M B O S   S Y S T E M   L I B R A R Y                  @
;@                        - NETWORK DAEMON FUNCTIONS -                        @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author     Prodatron / SymbiosiS
;Date       18.10.2021

;Converted to SjAsmPlus by NYYRIKKI
;Download the original from https://symbos.de

;This library supports you in using all network daemon functions.

;The existance of
;- "App_Process_ID" (a byte, where the ID of the applications process is stored)
;- "Message_Buffer" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;- "App_Bank_Number" (a byte, where the number of the applications' ram bank (0-15)
;  is stored)
;is required.


;### SUMMARY ##################################################################

; call SyNet_NETINI         ;Initialize network routines
; call SyNet_NETEVT         ;check for network events
; call SyNet_CFGGET         ;Config get data
; call SyNet_CFGSET         ;Config set data
; call SyNet_CFGSCK         ;Config socket status
; call SyNet_TCPOPN         ;TCP open connection
; call SyNet_TCPCLO         ;TCP close connecton
; call SyNet_TCPSTA         ;TCP status of connection
; call SyNet_TCPRCV         ;TCP receive from connection
; call SyNet_TCPSND         ;TCP send to connection
; call SyNet_TCPSKP         ;TCP skip received data
; call SyNet_TCPFLS         ;TCP flush send buffer
; call SyNet_TCPDIS         ;TCP disconnect connection
; call SyNet_TCPRLN         ;TCP receive textline from connection
; call SyNet_UDPOPN         ;UDP open
; call SyNet_UDPCLO         ;UDP close
; call SyNet_UDPSTA         ;UDP status
; call SyNet_UDPRCV         ;UDP receive
; call SyNet_UDPSND         ;UDP send
; call SyNet_UDPSKP         ;UDP skip received data
; call SyNet_DNSRSV         ;DNS resolve
; call SyNet_DNSVFY         ;DNS verify



;### GENERAL FUNCTIONS ########################################################
      ifused SyNet_NETINI
SyNet_NETINI
;******************************************************************************
;*** Name           Network_Init
;*** Input          -
;*** Output         CF   = Error state (0 = ok, 1 = Network daemon not running)
;***                - if CF is 0:
;***                (SyNet_PrcID) = Network daemon process ID
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Before using any user functions of this library you have to
;***                call this first. It will check, if a network daemon is running
;***                and will store its process ID if found.
;******************************************************************************
        ld e,0
        ld hl,snwdmnt
        ld a,(App_Bank_Number)
        call SySystem_PRGSRV
        or a
        scf
        ret nz
        ld a,h
        ld (SyNet_PrcID),a
        or a
        ret
snwdmnt db "Network Daem"
      endif

      ifused SyNet_NETEVT
SyNet_NETEVT
;******************************************************************************
;*** Name           Network_Event
;*** Input          -
;*** Output         CF   = Flag, if network event occured (1=no)
;***                - if CF is 0:
;***                A    = Handle
;***                L    = Status (1=TCP opening, 2=TCP established, 3=TCP
;***                       close waiting, 4=TCP close,
;***                       16=UDP sending,
;***                       128=data received)
;***                IX,IY= Remote IP
;***                DE   = Remote port
;***                BC   = Received bytes
;*** Destroyed      F,HL
;*** Description    This checks, if an event from the network daemon came in.
;***                This maybe a TCP or an UDP event.
;***                For more information see SyNet_TCPSTA and SyNet_UDPSTA.
;******************************************************************************
        ld a,(App_Process_ID)
        ld ixl,a
        ld a,(SyNet_PrcID)
        ld ixh,a
        ld iy,Message_Buffer
        rst #18                 ;check for message
        db #dd:dec l
        scf
        ret nz                  ;no message available
        ld a,(Message_Buffer)
        cp MSR_NET_TCPEVT
        jp z,snwmsgo_afbcdehlixiy
        cp MSR_NET_UDPEVT
        jp z,snwmsgo_afbcdehlixiy
        scf                     ;senseless message
        ret
      endif


;### CONFIG FUNCTIONS #########################################################

      ifused SyNet_CFGSET
SyNet_CFGGET
;******************************************************************************
;*** ID             001 (CFGGET)
;*** Name           Config_GetData
;*** Input          A    = Type
;***                HL   = Config data buffer
;*** Output         CF   = status (CF=1 invalid type)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    ...
;******************************************************************************
        ld de,(App_Bank_Number)
        call snwmsgi_afdehl
        db FNC_NET_CFGGET
        jp snwmsgo_afhl
      endif

      ifused SyNet_CFGGET
SyNet_CFGSET
;******************************************************************************
;*** ID             002 (CFGSET)
;*** Name           Config_SetData
;*** Input          A    = Type
;***                HL   = New config data
;*** Output         CF   = status (CF=1 invalid type)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    ...
;******************************************************************************
        ld de,(App_Bank_Number)
        call snwmsgi_afdehl
        db FNC_NET_CFGSET
        jp snwmsgo_afhl
      endif

      ifused SyNet_CFGSCK
SyNet_CFGSCK
;******************************************************************************
;*** ID             003 (CFGSCK)
;*** Name           Config_SocketStatus
;*** Input          A    = first socket
;***                C    = number of sockets
;***                HL   = data buffer
;*** Output         CF   = status (CF=1 invalid range)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    ...
;******************************************************************************
        ld de,(App_Bank_Number)
        call snwmsgi_afbcdehl
        db FNC_NET_CFGSCK
        jp snwmsgo_afhl
      endif


;### TCP FUNCTIONS ############################################################

      ifused SyNet_TCPOPN
;******************************************************************************
;*** ID             016 (TCPOPN)
;*** Name           TCP_Open
;*** Input          A    = Type (0=active/client, 1=passive/server)
;***                HL   = Local port (-1=dynamic client port)
;***                - if A is 0:
;***                IX,IY= Remote IP
;***                DE   = Remote port
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens a TCP connection as a client (active) or as a server
;***                (passive). If it's an active connection you have to specify
;***                the remote IP address and port number as well.
;***                The local port number always has to be set. For client
;***                network applications you should set HL to -1 (65535) to get
;***                a dynamic port number. This will automaticaly generated by
;***                the network daemon in the range of 49152-65535 (official
;***                range for dynamic ports).
;***                This function will fail, if there is no free socket left.
;***                It returns the connection handle if it was successful.
;******************************************************************************
SyNet_TCPOPN
        call snwmsgi_afbcdehlixiy
        db FNC_NET_TCPOPN
        jp snwmsgo_afhl
      endif

      ifused SyNet_TCPCLO
;******************************************************************************
;*** ID             017 (TCPCLO)
;*** Name           TCP_Close
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Closes a TCP connection and releases the used socket. It
;***                will not send a disconnect signal to the remote host (see
;***                TCPDIS). Use this, after the remote host already
;***                closed the connection.
;******************************************************************************
SyNet_TCPCLO
        call snwmsgi_af
        db FNC_NET_TCPCLO
        jp snwmsgo_afhl
      endif

      ifused SyNet_TCPSTA
;******************************************************************************
;*** ID             018 (TCPSTA)
;*** Name           TCP_Status
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                L    = Status (1=TCP opening, 2=TCP established, 3=TCP
;***                       close waiting, 4=TCP close; +128=data received)
;***                - if L is >1:
;***                IX,IY= Remote IP
;***                DE   = Remote port
;***                - if L is >=128:
;***                BC   = Received bytes (which are available in the RX
;***                       buffer)
;*** Destroyed      F,H
;*** Description    Returns the actual status of the TCP connection. Usually
;***                this is exactly the same as received in the last event
;***                message (see TCPEVT). The number of received bytes in BC
;***                may have been increased during the last event, if it was
;***                already larger than 0.
;******************************************************************************
SyNet_TCPSTA
        call snwmsgi_af
        db FNC_NET_TCPSTA
        jp snwmsgo_afbcdehlixiy
      endif

      ifused SyNet_TCPRCV
;******************************************************************************
;*** ID             019 (TCPRCV)
;*** Name           TCP_Receive
;*** Input          A    = Handle
;***                E    = Destination bank
;***                HL   = Destination address
;***                BC   = Length (has to be >0)
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                BC   = Number of transfered bytes (which have been copied
;***                       to the destination)
;***                HL   = Number of remaining bytes (which are still left in
;***                       the RX buffer)
;***                ZF   = 1 -> no remaining bytes (RX buffer is empty)
;*** Destroyed      F,DE,HL,IX,IY
;*** Description    Copies data, which has been received from the remote host,
;***                to a specified destination in memory. The length of the
;***                requested data is not limited, but this function will only
;***                receive the available one.
;***                Please note, that a new TCPEVT event only occurs on new
;***                incoming bytes, if this function returned HL=0 (no
;***                remaining bytes). It may happen, that during the last
;***                TCPEVT/TCPSTA status the number of remaining bytes has been
;***                increased, so you always have to check HL, even if you
;***                requested all incoming bytes known from the last status.
;******************************************************************************
SyNet_TCPRCV
        call snwmsgi_afbcdehl
        db FNC_NET_TCPRCV
        jp snwmsgo_afbchl
      endif

      ifused SyNet_TCPSND
;******************************************************************************
;*** ID             020 (TCPSND)
;*** Name           TCP_Send
;*** Input          A    = Handle
;***                E    = Source bank
;***                HL   = Source address
;***                BC   = Length
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                BC   = Number of transfered bytes
;***                HL   = Number of remaining bytes (which couldn't be
;***                       transfered, as the TX buffer is full at the moment)
;***                ZF   = 1 -> no remaining bytes
;*** Destroyed      F,DE,IX,IY
;*** Description    Sends data to the remote host. The length of the data is
;***                not limited, but this function may send only a part of it.
;***                In case that not all data have been send, the application
;***                should idle for a short time and send the remaining part
;***                at another attempt.
;******************************************************************************
SyNet_TCPSND
        call snwmsgi_afbcdehl
        db FNC_NET_TCPSND
        jp snwmsgo_afbchl
      endif

      ifused SyNet_TCPSKP
;******************************************************************************
;*** ID             021 (TCPSKP)
;*** Name           TCP_Skip
;*** Input          A    = Handle
;***                BC   = Length
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Skips data, which has been received from the remote host.
;***                This can be used if the application is sure, that the
;***                following bytes are not needed and the data transfer can be
;***                skipped to save resources. The amount of bytes must be
;***                equal or smaller than the total amount of received data.
;******************************************************************************
SyNet_TCPSKP
        call snwmsgi_afbcdehl
        db FNC_NET_TCPSKP
        jp snwmsgo_afhl
      endif

      ifused SyNet_TCPFLS
;******************************************************************************
;*** ID             022 (TCPFLS)
;*** Name           TCP_Flush
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Flushes the send buffer. This maybe used to send data
;***                immediately, as some network hardware or software
;***                implementations may store it first in the send buffer for a
;***                while until it is full or a special amount of time has
;***                passed.
;******************************************************************************
SyNet_TCPFLS
        call snwmsgi_af
        db FNC_NET_TCPFLS
        jp snwmsgo_afhl
      endif

      ifused SyNet_TCPDIS
;******************************************************************************
;*** ID             023 (TCPDIS)
;*** Name           TCP_Disconnect
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a disconnect signal to the remote host, closes the
;***                TCP connection and releases the used socket. Use this, if
;***                you want to close the connection by yourself.
;******************************************************************************
SyNet_TCPDIS
        call snwmsgi_af
        db FNC_NET_TCPDIS
        jp snwmsgo_afhl
      endif

      ifused SyNet_TCPRLN
;******************************************************************************
;*** ID             024 (TCPRLN)
;*** Name           TCP_ReceiveLine
;*** Input          A    = Handle
;***                E    = Destination bank
;***                HL   = Destination address
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                D    = Line length (-1=no complete line received, ZF)
;***                ZF   = 1 -> no complete line received
;*** Destroyed      AF,E,HL,IX,IY
;*** Description    Copies up to one complete line of ASCII data, which has
;***                been received from the remote host, to a specified
;***                destination in memory. A line is terminated with 13+10 or only
;***                with 13. The 13 and 10 linefeed codes will not be copied to
;***                the destination buffer, but the line will be 0-terminated.
;***                If a line received from the network is larger than 254 bytes
;***                you will receive an "incomplete" status and have to fetch
;***                the remaining parts of the line by calling this function again
;***                until a linefeed code is found.
;***                Internally this function is using the SyNet_TCPRCV function.
;***                You should only call this function, when you know, that
;***                there was data coming in. For additional information see
;***                SyNet_TCPRCV.
;******************************************************************************
SyNet_TCPRLN_Buffer ds 256      ;buffer
SyNet_TCPRLN_Length db 0        ;length (always <255)
SyNet_TCPRLN
        ld (snwrln3+1),a
        ld a,e
        add a:add a:add a:add a
        ld (snwrlnb+1),a
        ld (snwrlna+1),hl
        call snwrln0
        ld a,d
        inc a
        jr z,snwrln8
snwrln9 ld a,d
        inc a
        or a
snwrlnc ld a,(snwrln3+1)
        ret
snwrln8 ld a,(SyNet_TCPRLN_Length)
        ld c,a
        ld b,0
        cpl                     ;A=255-buflen
        ld hl,SyNet_TCPRLN_Buffer
        add hl,bc
        ld c,a
snwrln3 ld a,0
        ld de,(App_Bank_Number)
        call snwmsgi_afbcdehl   ;receive data
        db FNC_NET_TCPRCV
        call snwmsgo_afbchl
        ret c
        ld hl,SyNet_TCPRLN_Length
        ld a,(hl)
        add c
        ld (hl),a               ;update buffer length
        call snwrln0
        jr snwrln9

snwrln0 ld a,(SyNet_TCPRLN_Length)
        cp 255
        ccf
        sbc 0
        ld d,-1
        ret z
        ld e,a                  ;e,bc=search length (max 254)
        ld c,a
        ld b,0
        ld hl,SyNet_TCPRLN_Buffer
        ld a,13
        cpir
        jr z,snwrln5
        ld a,e
        cp 254
        ret c                   ;** not found and <254 chars -> no complete line received
        inc d
snwrln4 call snwrln7            ;** not found and =254 chars -> send line anyway
        ld d,254
        ret
snwrln5 ld a,c                  ;** found -> HL=behind 13-char, BC=remaining length
        or b
        ld d,-1
        ret z                   ;found at the last position -> no complete line received
        ld d,1
        ld a,10
        cp (hl)
        jr nz,snwrln6
        inc d
snwrln6 ld bc,SyNet_TCPRLN_Buffer+1
        or a
        sbc hl,bc
        ld e,l
        push de
        call snwrln7
        pop de
        ld d,e
        ret

;e=line length, d=bytes to skip -> copy line to destination and remove it from the buffer
snwrln7 push de
        ld d,0
        ld hl,SyNet_TCPRLN_Buffer
        push hl
        add hl,de
        ld (hl),0
        pop hl
        ld c,e
        inc c
        ld b,0
        ld a,(App_Bank_Number)
snwrlnb add 0
snwrlna ld de,0
        rst #20:dw jmp_bnkcop
        pop de
        ld hl,SyNet_TCPRLN_Length
        ld a,(hl)
        sub e
        sub d
        ld (hl),a
        ret z
        ld c,a
        ld b,0
        ld a,e
        add d
        ld e,a
        ld d,0
        ld hl,SyNet_TCPRLN_Buffer
        add hl,de
        ld de,SyNet_TCPRLN_Buffer
        ldir
        ret
      endif

;### UDP FUNCTIONS ############################################################

      ifused SyNet_UDPOPN
;******************************************************************************
;*** ID             032 (UDPOPN)
;*** Name           UDP_Open
;*** Input          A    = Type
;***                HL   = Local port
;***                E    = Source/destination bank for receive/send
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Opens an UDP session. Already with this functions you have
;***                to specify the ram bank number of the source and
;***                destination memory areas for upcoming data transfer.
;***                This function will fail, if there is no free socket left.
;***                It returns the session handle if it was successful.
;******************************************************************************
SyNet_UDPOPN
        call snwmsgi_afdehl
        db FNC_NET_UDPOPN
        jp snwmsgo_afhl
      endif

      ifused SyNet_UDPCLO
;******************************************************************************
;*** ID             033 (UDPCLO)
;*** Name           UDP_Close
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Closes an UDP session and releases the used socket.
;******************************************************************************
SyNet_UDPCLO
        call snwmsgi_af
        db FNC_NET_UDPCLO
        jp snwmsgo_afhl
      endif

      ifused SyNet_UDPSTA
;******************************************************************************
;*** ID             034 (UDPSTA)
;*** Name           UDP_Status
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;***                L    = Status
;***                - if L is ???:
;***                BC   = Received bytes
;***                IX,IY= Remote IP
;***                DE   = Remote port
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Returns the actual status of the UDP session. This is
;***                always exactly the same as received in the last event
;***                message (see UDPEVT).
;******************************************************************************
SyNet_UDPSTA
        call snwmsgi_af
        db FNC_NET_UDPSTA
        jp snwmsgo_afbcdehlixiy
      endif

      ifused SyNet_UDPRCV
;******************************************************************************
;*** ID             035 (UDPRCV)
;*** Name           UDP_Receive
;*** Input          A    = Handle
;***                HL   = Destination address
;***                       (bank has been specified by the UDPOPN function)
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Copies the package data, which has been received from a
;***                remote host, to a specified destination in memory. Please
;***                note, that this function will always transfer the whole
;***                data at once, so there should be enough place at the
;***                destination address. The destination ram bank number has
;***                already been specified with the UDPOPN function.
;******************************************************************************
SyNet_UDPRCV
        call snwmsgi_afhl
        db FNC_NET_UDPRCV
        jp snwmsgo_afhl
      endif

      ifused SyNet_UDPSND
;******************************************************************************
;*** ID             036 (UDPSND)
;*** Name           UDP_Send
;*** Input          A    = Handle
;***                HL   = Source address
;***                       (bank has been specified by the UDPOPN function)
;***                BC   = Length
;***                IX,IY= Remote IP
;***                DE   = Remote port
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Sends a data package to a remote host. It may happen, that
;***                the send buffer is currently full, and this function will
;***                the return the appropriate error code. In this case the
;***                application should idle for a short time and try to send
;***                the package again at another attempt.
;******************************************************************************
SyNet_UDPSND
        call snwmsgi_afbcdehlixiy
        db FNC_NET_UDPSND
        jp snwmsgo_afhl
      endif

      ifused SyNet_UDPSKP
;******************************************************************************
;*** ID             037 (UDPSKP)
;*** Name           UDP_Skip
;*** Input          A    = Handle
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                A    = Handle
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Skips a received data package. This can be used if the
;***                application is sure, that the data is not needed or has
;***                sent from the wrong remote host, so the data transfer can
;***                be skipped to save resources.
;******************************************************************************
SyNet_UDPSKP
        call snwmsgi_af
        db FNC_NET_UDPSKP
        jp snwmsgo_afhl
      endif


;### DNS FUNCTIONS ############################################################

      ifused SyNet_DNSRSV
;******************************************************************************
;*** ID             112 (DNSRSV)
;*** Name           DNS_Resolve
;*** Input          HL = string address (0-terminated)
;*** Output         CF   = Error state (0 = ok, 1 = error; A = error code)
;***                - if CF is 0:
;***                IX,IY= IP
;*** Destroyed      AF,BC,DE,HL
;*** Description    Makes a DNS look up and tries to resolve an IP address.
;******************************************************************************
SyNet_DNSRSV
        ld de,(App_Bank_Number)
        call snwmsgi_afdehl
        db FNC_NET_DNSRSV
        jp snwmsgo_afbcdehlixiy
      endif

      ifused SyNet_DNSVFY
;******************************************************************************
;*** ID             113 (DNSVFY)
;*** Name           DNS_Verify
;*** Input          HL = string address (0-terminated)
;*** Output         L    = type of address (0=no valid address, 1=IP address,
;***                                        2=domain address)
;***                - if L is 1:
;***                IX,IY= IP
;*** Destroyed      F,BC,DE,HL
;*** Description    Checks, if a string is a valid IP or domain address.
;***                This won't do any activity with the network hardware but
;***                you can use this to test, if an entered IP number or domain
;***                address seems to be typed correctly.
;******************************************************************************
SyNet_DNSVFY
        ld de,(App_Bank_Number)
        call snwmsgi_afdehl
        db FNC_NET_DNSVFY
        jp snwmsgo_afbcdehlixiy
      endif


;### SUB ROUTINES #############################################################
      ifused SyNet_PrcID
snwmsgi_afbcdehlixiy
        ld (Message_Buffer+10),ix   ;store registers to message buffer
        ld (Message_Buffer+12),iy
snwmsgi_afbcdehl
        ld (Message_Buffer+04),bc
snwmsgi_afdehl
        ld (Message_Buffer+06),de
snwmsgi_afhl
        ld (Message_Buffer+08),hl
snwmsgi_af
        push af:pop hl
        ld (Message_Buffer+02),hl
        pop hl
        ld a,(hl)               ;set command
        inc hl
        push hl
        ld (Message_Buffer+0),a
        ld (snwmsg2+1),a
        ld iy,Message_Buffer
        ld a,(App_Process_ID)
        ld ixl,a
        ld a,(SyNet_PrcID)
        ld ixh,a
        ld (snwmsg1+2),ix
        rst #10                 ;send message
snwmsg1 ld ix,0                 ;wait for response
        rst #08
        db #dd:dec l
        jr nz,snwmsg1
        ld a,(Message_Buffer)
        sub 128
snwmsg2 cp 0
        ret z
        ld a,(App_Process_ID)        ;wrong response code -> re-send and wait for correct one
        ld ixh,a
        ld a,(SyNet_PrcID)
        ld ixl,a
        rst #10
        rst #30
        jr snwmsg1
snwmsgo_afbcdehlixiy
        ld ix,(Message_Buffer+10)   ;get registers from the message buffer
        ld iy,(Message_Buffer+12)
        ld de,(Message_Buffer+06)
snwmsgo_afbchl
        ld bc,(Message_Buffer+04)
snwmsgo_afhl
        ld hl,(Message_Buffer+02)
        push hl
        pop af
        ld hl,(Message_Buffer+08)
        ret
        

;### GLOBAL VARIABLES #########################################################

SyNet_PrcID db 0    ;network daemon process ID
      endif