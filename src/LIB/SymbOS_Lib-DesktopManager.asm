;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@                                                                            @
;@                 S Y M B O S   S Y S T E M   L I B R A R Y                  @
;@                       - DESKTOP MANAGER FUNCTIONS -                        @
;@                                                                            @
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;Author     Prodatron / Symbiosis
;Date       19.10.2021

;Converted to SjAsmPlus by NYYRIKKI
;Download the original from https://symbos.de

;The desktop manager is responsible for all actions, which are taking place on
;the video screen. Especially the handling of the application windows is done
;by the desktop manager.
;This library supports you in using the desktop manager functions.

;The existance of
;- "App_Process_ID" (a byte, where the ID of the applications process is stored)
;- "Message_Buffer" (the message buffer, 14 bytes, which are placed in the transfer
;  ram area)
;is required.


;### SUMMARY ##################################################################

; call SyDesktop_WINOPN     ;Opens a new window
; call SyDesktop_WINMEN     ;Redraws the menu bar of a window
; call SyDesktop_WININH     ;Redraws the content of a window
; call SyDesktop_WINTOL     ;Redraws the content of the window toolbar
; call SyDesktop_WINTIT     ;Redraws the title bar of a window
; call SyDesktop_WINSTA     ;Redraws the status bar of a window
; call SyDesktop_WINMVX     ;Sets the X offset of a window content
; call SyDesktop_WINMVY     ;Sets the Y offset of a window content
; call SyDesktop_WINTOP     ;Takes a window to the front position
; call SyDesktop_WINMAX     ;Maximizes a window
; call SyDesktop_WINMIN     ;Minimizes a window
; call SyDesktop_WINMID     ;Restores a window or the size of a window
; call SyDesktop_WINMOV     ;Moves a window to another position
; call SyDesktop_WINSIZ     ;Resizes a window
; call SyDesktop_WINCLS     ;Closes a window
; call SyDesktop_WINDIN     ;Redraws the content of a window (always)
; call SyDesktop_WINSLD     ;Redraws the two slider of a window
; call SyDesktop_WINPIN     ;Redraws the content of a window (clipped)
; call SyDesktop_WINSIN     ;Redraws the content of a control collection
; call SyDesktop_MENCTX     ;Opens a context menu
; call SyDesktop_STIADD     ;Adds an icon to the systray
; call SyDesktop_STIREM     ;Removes an icon from the systray
; call SyDesktop_CONPOS     ;Moves a virtual control
; call SyDesktop_CONSIZ     ;Resizes a virtual control
; call SyDesktop_MODGET     ;Returns the current screen mode
; call SyDesktop_MODSET     ;Sets the current screen
; call SyDesktop_COLGET     ;Returns the definition of a colours
; call SyDesktop_COLSET     ;Defines one colours
; call SyDesktop_DSKSTP     ;Stops the Desktop Manager
; call SyDesktop_DSKCNT     ;Continues the Desktop Manager
; call SyDesktop_DSKPNT     ;Fills the screen
; call SyDesktop_DSKBGR     ;Redraws the desktop background
; call SyDesktop_DSKPLT     ;Redraws the complete screen
; call SyDesktop_SCRCNV     ;Converts 4 colour graphics to 4/16 indexed


;### MAIN FUNCTIONS ###########################################################

      ifused SyDesktop_WINOPN
SyDesktop_WINOPN
;******************************************************************************
;*** Name           Window_Open_Command
;*** Input          A  = Window data record ram bank (0-15)
;***                DE = Window data record address (#C000-#FFFF)
;*** Output         A  = Window ID (only, if CF=0)
;***                CF = Success status
;***                     0 = OK
;***                     1 = window couldn't be opened, as the maximum number
;***                         of windows (32) has been reached
;*** Destroyed      BC,DE,HL,IX,IY
;*** Description    Opens a new window. Its data record must be placed in the
;***                transfer ram area (between #c000 and #ffff).
;***                For more information about the window data record see the
;***                chapter "desktop manager data records".
;***                For more information about the transfer ram memory types see
;***                the "applications" chapter.
;******************************************************************************
        ld b,a
        ld ixl,e
        ld ixh,d
        ld a,(App_Process_ID)    ;register window for the application process
        ld (ix+3),a
        ld a,b
        ld c,MSC_DSK_WINOPN
        call SyDesktop_SendMessage
SyWOpn1 call SyDesktop_WaitMessage
        cp MSR_DSK_WOPNER
        scf
        ret z               ;return with set carry flag, if window couldn't be opened
        cp MSR_DSK_WOPNOK
        jr nz,SyWOpn1       ;different message than "open ok" -> continue waiting
        ld a,(Message_Buffer+4) ;get window ID and return with cleared carry flag
        ret
      endif

      ifused SyDesktop_WINMEN
SyDesktop_WINMEN
;******************************************************************************
;*** Name           Window_Redraw_Menu_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the menu bar of a window. If you changed your menus you
;***                should call this command to update the screen display.
;******************************************************************************
        ld c,MSC_DSK_WINMEN
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WININH
SyDesktop_WININH
;******************************************************************************
;*** Name           Window_Redraw_Content_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -E controls, starting from
;***                                  control D. As an example, if E is -3
;***                                  (253) and D is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  content.
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws one, all or a specified number of controls inside the
;***                window content. This command is very important, if you make
;***                changes and want to display them.
;***                This command is identical with MSC_DSK_WINDIN with the
;***                exception, that it only works, if the window has focus. Because
;***                of this, it is a little bit faster, as the desktop manager
;***                doesn't need to take care about other windows, which could hide
;***                some parts of the window.
;******************************************************************************
        ld c,MSC_DSK_WININH
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINTOL
SyDesktop_WINTOL
;******************************************************************************
;*** Name           Window_Redraw_Toolbar_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -E controls, starting from
;***                                  control D. As an example, if E is -3
;***                                  (253) and D is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  toolbar.
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws one, all or a specified number of controls inside the
;***                window toolbar. Use this command to update the screen display,
;***                if you made changes in the toolbar.
;******************************************************************************
        ld c,MSC_DSK_WINTOL
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINTIT
SyDesktop_WINTIT
;******************************************************************************
;*** Name           Window_Redraw_Title_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the title bar of a window. Use this command to update
;***                the screen display, if you changed the text of the window
;***                title.
;******************************************************************************
        ld c,MSC_DSK_WINTIT
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINSTA
SyDesktop_WINSTA
;******************************************************************************
;*** Name           Window_Redraw_Statusbar_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the status bar of a window. Use this command to update
;***                the screen display, if you changed the text of the status bar.
;******************************************************************************
        ld c,MSC_DSK_WINSTA
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINMVX
SyDesktop_WINMVX
;******************************************************************************
;*** Name           Window_Set_ContentX_Command
;*** Input          A  = Window ID
;***                DE = new X offset of the visible window content
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    If the size of the window content is larger than the visible
;***                part, you can scroll its X offset with this command. The
;***                command works also, if the window is not resizeable by the
;***                user.
;******************************************************************************
        ld c,MSC_DSK_WINMVX
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINMVY
SyDesktop_WINMVY
;******************************************************************************
;*** Name           Window_Set_ContentY_Command
;*** Input          A  = Window ID
;***                DE = new Y offset of the visible window content
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    If the size of the window content is larger than the visible
;***                part, you can scroll its Y offset with this command. The
;***                command works also, if the window is not resizeable by the
;***                user.
;******************************************************************************
        ld c,MSC_DSK_WINMVY
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINTOP
SyDesktop_WINTOP
;******************************************************************************
;*** Name           Window_Focus_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Takes the window to the front position on the screen.
;******************************************************************************
        ld c,MSC_DSK_WINTOP
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINMAX
SyDesktop_WINMAX
;******************************************************************************
;*** Name           Window_Size_Maximize_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is minimized or restored
;*** Description    Maximizes a window. A maximized window has a special status,
;***                where it can't be moved to another screen position.
;******************************************************************************
        ld c,MSC_DSK_WINMAX
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINMIN
SyDesktop_WINMIN
;******************************************************************************
;*** Name           Window_Size_Minimize_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is maximized or restored
;*** Description    Minimizes a window. It will disappear from the screen and can
;***                only be accessed by the user via the task bar.
;******************************************************************************
        ld c,MSC_DSK_WINMIN
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINMID
SyDesktop_WINMID
;******************************************************************************
;*** Name           Window_Size_Restore_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is maximized or minimized
;*** Description    Restores the window or the size of the window, if it was
;***                minimized or maximized before.
;******************************************************************************
        ld c,MSC_DSK_WINMID
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINMOV
SyDesktop_WINMOV
;******************************************************************************
;*** Name           Window_Set_Position_Command
;*** Input          A  = Window ID
;***                DE = new X window position
;***                HL = new Y window position
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if the window is not maximized
;*** Description    Moves a window to another position on the screen. This will
;***                not work, if the window is maximized.
;******************************************************************************
        ld c,MSC_DSK_WINMOV
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINSIZ
SyDesktop_WINSIZ
;******************************************************************************
;*** Name           Window_Set_Size_Command
;*** Input          A  = Window ID
;***                DE = new window width
;***                HL = new window height
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Resizes a window. This command will always work, even if the
;***                window is not resizeable by the user.
;***                Please note, that the size always refers to the visible content
;***                of the window, not to the whole window including the control
;***                elements. So with title bar, scroll bars etc. a window can have
;***                a bigger size on the screen.
;******************************************************************************
        ld c,MSC_DSK_WINSIZ
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINCLS
SyDesktop_WINCLS
;******************************************************************************
;*** Name           Window_Close_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Closes the window. The desktop manager will remove it from the
;***                screen.
;******************************************************************************
        ld c,MSC_DSK_WINCLS
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINDIN
SyDesktop_WINDIN
;******************************************************************************
;*** Name           Window_Redraw_ContentExtended_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -E controls, starting from
;***                                  control D. As an example, if E is -3
;***                                  (253) and D is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  content.
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    Redraws one, all or a specified number of controls inside the
;***                window content. This command is identical with MSC_DSK_WININH
;***                with the exception, that it always works but with less speed.
;***                For more information see MSC_DSK_WININH.
;******************************************************************************
        ld c,MSC_DSK_WINDIN
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINSLD
SyDesktop_WINSLD
;******************************************************************************
;*** Name           Window_Redraw_Slider_Command
;*** Input          A  = Window ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works only, if window has focus
;*** Description    Redraws the two slider of the window, with which the user can
;***                scroll the content. Sliders will only be displayed, if the
;***                window is resizeable.
;***                Usally you should use MSC_DSK_WINMVX and MSC_DSK_WINMVY to
;***                scroll the content of the window. These commands will update
;***                the sliders by themself.
;***                If you manipulate the content position in the window data
;***                record by yourself, you can use this command to update the
;***                screen display.
;******************************************************************************
        ld c,MSC_DSK_WINSLD
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINPIN
SyDesktop_WINPIN
;******************************************************************************
;*** Name           Window_Redraw_ContentArea_Command
;*** Input          A  = Window ID
;***                E  = -1, control ID or negative number of controls
;***                     000 - 239 -> the control with the specified ID will be
;***                                  redrawed.
;***                     240 - 254 -> redraws -E controls, starting from
;***                                  control D. As an example, if E is -3
;***                                  (253) and D is 5, the controls 5, 6 and 7
;***                                  will be redrawed.
;***                     255       -> redraws all controls inside the window
;***                                  content.
;***                HL = Area X begin inside the window content
;***                BC = Area Y begin
;***                IX = Area X length
;***                IY = Area Y length
;***                - if E is between 240 and 254:
;***                D = ID of the first control, which should be redrawed.
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    This command works like MSC_DSK_WINDIN, but it updates only a
;***                specified area inside the window content. Changes outside the
;***                area won't be updated. This command is especially useful for
;***                updating large graphics, if only a part of the graphic should
;***                be updated, and you don't want to loose performance with
;***                updating the other parts of it, too.
;***                For more information see MSC_DSK_WINDIN and MSC_DSK_WININH.
;******************************************************************************
        ld (Message_Buffer+06),bc
        ld (Message_Buffer+08),ix
        ld (Message_Buffer+10),iy
        ld c,MSC_DSK_WINPIN
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_WINSIN
SyDesktop_WINSIN
;******************************************************************************
;*** Name           Window_Redraw_SubControl_Command
;*** Input          A  = Window ID
;***                E  = control collection ID
;***                D  = ID of the sub control inside the control collection
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Limitation     works always
;*** Description    This command works like MSC_DSK_WINDIN, but it updates only one
;***                sub control inside a control collection. This command currently
;***                doesn't support the redrawing of multiple sub controls.
;***                For additional information see also MSC_DSK_WINDIN.
;******************************************************************************
        ld c,MSC_DSK_WINSIN
        jp SyDesktop_SendMessage
      endif

      ifused SyDesktop_MENCTX
SyDesktop_MENCTX
;******************************************************************************
;*** Name           Menu_Context_Command
;*** Input          A  = Menu data record ram bank (0-8)
;***                DE = Menu data record address (#C000-#FFFF)
;***                HL = X position (-1=place at mouse position)
;***                BC = Y position
;*** Output         CF = status (0=entry has been clicked, 1=menu canceled)
;***                - if CF is 0:
;***                HL = Menu entry value
;***                C  = Menu entry type (0=normal, 1=checked entry)
;*** Destroyed      AF,B,DE,IX,IY
;*** Description    Opens a context menu at the specified position on the screen
;***                and returns what the user choosed after closing it again.
;***                Its data record must be placed in the transfer ram area
;***                (between #c000 and #ffff).
;***                If -1 is given instead of an x position, the menu will be
;***                placed at the x/y position of the mouse pointer.
;***                For more information about the menu data record see the
;***                chapter "desktop manager data records".
;***                For more information about the transfer ram memory types see
;***                the "applications" chapter.
;******************************************************************************
        ld (Message_Buffer+06),bc
        ld c,MSC_DSK_MENCTX
        call SyDesktop_SendMessage
SyMCtx1 call SyDesktop_WaitMessage
        cp MSR_DSK_MENCTX
        jr nz,SyMCtx1
        ld a,(Message_Buffer+4)     ;menu entry type
        ld c,a
        ld a,(Message_Buffer+1)     ;success state
        ld hl,(Message_Buffer+2)    ;menu entry value
        cp 1                    ;A=1 -> cf=0, A=0 -> cf=1
        ret
      endif
      ifused SyDesktop_STIADD
SyDesktop_STIADD
;******************************************************************************
;*** Name           SystrayIcon_Add_Command
;*** Input          DE = Icon address
;***                A  = Icon ram bank (0-15)
;***                L  = click code
;*** Output         CF = status (0=ok, 1=no more slot available)
;***                - if CF is 0:
;***                A  = Icon ID
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Adds a systray icon to the task bar. These can be clicked
;***                by the user, which will generate an event sent to the
;***                application by the desktop manager (see MSR_DSK_EVTCLK).
;***                The icon is a 8x8 pixel SymbOS standard graphic (see
;***                SymbOS-DesktopDataRecords.txt, Graphics, "Standard graphics").
;***                L defines the click code, which is sent to the application
;***                as the MSR_DSK_EVTCLK event, if the user clicks the systray
;***                icon.
;***                After a systray icon has been added successfully you will
;***                receive its ID in A. This ID has to be used when removing
;***                the icon later again (see use_SyDesktop_STIREM below).
;******************************************************************************
        ld c,MSC_DSK_STIADD
        ld b,a
        ld a,(App_Process_ID)
        ld h,a
        ld a,b
        call SyDesktop_SendMessage
SyDTry1 call SyDesktop_WaitMessage
        cp MSR_DSK_STIADD
        jr nz,SyDTry1
        ld hl,(Message_Buffer+1)
        push hl
        pop af
        ret
      endif

      ifused SyDesktop_STIREM
SyDesktop_STIREM
;******************************************************************************
;*** Name           SystrayIcon_Remove_Command
;*** Input          A  = Icon ID
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Removes a systray icon from the task bar. You have to specify
;***                its ID which you received when adding the icon.
;******************************************************************************
        ld c,MSC_DSK_STIREM
        jp SyDesktop_SendMessage
      endif
      
      ifused SyDesktop_CONPOS
SyDesktop_CONPOS
;******************************************************************************
;*** Name           VirtualControl_Position_Command
;*** Input          DE = current control X position
;***                HL = current control Y position
;***                BC = control width
;***                IX = control height
;*** Output         CF = status (0=ok, 1=canceled)
;***                - if CF is 0:
;***                DE = new control X position
;***                HL = new control Y position
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Starts a mouse session for moving a virtual control over the
;***                screen and place it at a new position. A dotted frame with the
;***                specified size and position will appear and can be moved and
;***                relocated with the mouse.
;***                As soon as the user released the left mouse button the session
;***                is stopped. The dotted frame will disappear again and the new
;***                position is returned.
;***                If the user presses the ESC key during the mouse session, you
;***                will receive a "canceled" status.
;***                This feature doesn't modify an existing control in an opened
;***                window but can be used for situations where the user should
;***                replace something on the screen, which will then be done by the
;***                application itself in real after this session.
;******************************************************************************
        ld (Message_Buffer+06),bc
        ld (Message_Buffer+08),ix
        ld c,MSC_DSK_CONPOS
        call SyDesktop_SendMessage
SyCoPs1 call SyDesktop_WaitMessage
        cp MSR_DSK_CONPOS
        jr nz,SyCoPs1
        ld de,(Message_Buffer+2)
        ld hl,(Message_Buffer+4)
        ld a,(Message_Buffer+1)
        rra
        ccf
        ret
      endif

      ifused SyDesktop_CONSIZ
SyDesktop_CONSIZ
;******************************************************************************
;*** Name           VirtualControl_Size_Command
;*** Input          DE = control X position
;***                HL = control Y position
;***                BC = current control width
;***                IX = current control height
;*** Output         CF = status (0=ok, 1=canceled)
;***                - if CF is 0:
;***                DE = new control width
;***                HL = new control height
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Starts a mouse session for resizing a virtual control on the
;***                screen. A dotted frame with the specified size and position
;***                will appear and can be resized by moving the mouse.
;***                As soon as the user released the left mouse button the session
;***                is stopped. The dotted frame will disappear again and the new
;***                size is sent to the application.
;***                If the user presses the ESC key during the mouse session, you
;***                will receive a "canceled" status.
;***                This feature doesn't modify an existing control in an opened
;***                window but can be used for situations where the user should
;***                resize something on the screen, which will then be done by the
;***                application itself in real after this session.
;******************************************************************************
        ld (Message_Buffer+06),bc
        ld (Message_Buffer+08),ix
        ld c,MSC_DSK_CONSIZ
        call SyDesktop_SendMessage
SyCoSz1 call SyDesktop_WaitMessage
        cp MSR_DSK_CONSIZ
        jr nz,SyCoSz1
        ld de,(Message_Buffer+2)
        ld hl,(Message_Buffer+4)
        ld a,(Message_Buffer+1)
        rra
        ccf
        ret
      endif

      ifused SyDesktop_MODGET
SyDesktop_MODGET
;******************************************************************************
;*** Name           DesktopService_ScreenModeGet
;*** Input          -
;*** Output         E  = Screen mode; the available modes depend on the computer
;***                     platform.
;***                     PCW    0 = 720 x 255,  2 colours (PCW standard mode)
;***                     CPC,EP 1 = 320 x 200,  4 colours (CPC,EP standard mode)
;***                            2 = 640 x 200,  2 colours
;***                     MSX    5 = 256 x 212, 16 colours
;***                            6 = 512 x 212,  4 colours
;***                            7 = 512 x 212, 16 colours (MSX standard mode)
;***                     G9K    8 = 384 x 240, 16 colours
;***                            9 = 512 x 212, 16 colours (G9K standard mode)
;***                           10 = 768 x 240, 16 colours
;***                           11 = 1024x 212, 16 colours
;***                - if G9K:
;***                D  = Virtual desktop width
;***                          0 = no virtual desktop
;***                          1 =  512 
;***                          2 = 1000
;*** Destroyed      F,BC,DE,HL,IX,IY
;*** Description    Returns the current screen resolution and number of possible
;***                colours.
;******************************************************************************
        ld a,DSK_SRV_MODGET
        jp SyDesktop_Service
      endif

      ifused SyDesktop_MODSET
SyDesktop_MODSET
;******************************************************************************
;*** Name           DesktopService_ScreenModeSet
;*** Input          E  = Screen mode; the available modes depend on the computer
;***                     platform.
;***                     PCW  0 = 720 x 255,  2 colours (PCW standard mode)
;***                     CPC  1 = 320 x 200,  4 colours (CPC standard mode)
;***                          2 = 640 x 200,  2 colours
;***                     MSX  5 = 256 x 212, 16 colours
;***                          6 = 512 x 212,  4 colours (MSX standard mode)
;***                          7 = 512 x 212, 16 colours
;***                     G9K  8 = 384 x 240, 16 colours
;***                          9 = 512 x 212, 16 colours (G9K standard mode)
;***                         10 = 768 x 240, 16 colours
;***                         11 = 1024x 212, 16 colours
;***                - if G9K:
;***                D  = Virtual desktop width
;***                          0 = no virtual desktop
;***                          1 =  512 
;***                          2 = 1000
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sets the screen resolution and number of possible colours.
;******************************************************************************
        ld a,DSK_SRV_MODSET
        jp SyDesktop_Service
      endif

      ifused SyDesktop_COLGET
SyDesktop_COLGET
;******************************************************************************
;*** Name           DesktopService_ColourGet
;*** Input          E  = Colour number (0-15)
;*** Output         D  = Bit[0-3] blue  component (0-15)
;***                     Bit[4-7] green component (0-15)
;***                L  = Bit[0-3] red   component (0-15)
;*** Destroyed      AF,BC,E,H,IX,IY
;*** Description    Returns the definition of a colours. Please note, that you
;***                always have a range of 4096, even if the computer is not a CPC
;***                PLUS, as the system recalculates the colour for standard CPCs
;***                (factor 5,33 for each component).
;******************************************************************************
        ld a,DSK_SRV_COLGET
        jp SyDesktop_Service
      endif

      ifused SyDesktop_COLSET
SyDesktop_COLSET
;******************************************************************************
;*** Name           DesktopService_ColourSet
;*** Input          E  = Colour number (0-15)
;***                D  = Bit[0-3] blue  component (0-15)
;***                     Bit[4-7] green component (0-15)
;***                L  = Bit[0-3] red   component (0-15)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Defines one colour. Please note, that you always have a range
;***                of 4096, even if the computer is not a CPC PLUS, as the system
;***                recalculates the colour for standard CPCs (factor 5,33 for each
;***                component).
;******************************************************************************
        ld a,DSK_SRV_COLSET
        jp SyDesktop_Service
      endif

      ifused SyDesktop_DSKSTP
SyDesktop_DSKSTP
;******************************************************************************
;*** Name           DesktopService_DesktopStop
;*** Input          E  = fill type (0=pen 0, 1=raster, 2=background,
;***                               255=no screen modification, switch off mouse)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    [...]
;******************************************************************************
        ld a,DSK_SRV_DSKSTP
        jp SyDesktop_Service
      endif


      ifused SyDesktop_DSKCNT
SyDesktop_DSKCNT
;******************************************************************************
;*** Name           DesktopService_DesktopContinue
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    [...]
;******************************************************************************
        ld a,DSK_SRV_DSKCNT
        jp SyDesktop_Service
      endif

      ifused SyDesktop_DSKPNT
SyDesktop_DSKPNT
;******************************************************************************
;*** Name           DesktopService_DesktopClear
;*** Input          E  = fill type (0=pen 0, 1=raster, 2=background)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    [...]
;******************************************************************************
        ld a,DSK_SRV_DSKPNT
        jp SyDesktop_Service
      endif

      ifused SyDesktop_DSKBGR
SyDesktop_DSKBGR
;******************************************************************************
;*** Name           DesktopService_RedrawBackground
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Redraws the desktop background.
;******************************************************************************
        ld a,DSK_SRV_DSKBGR
        jp SyDesktop_Service
      endif

      ifused SyDesktop_DSKPLT
SyDesktop_DSKPLT
;******************************************************************************
;*** Name           DesktopService_RedrawComplete
;*** Input          -
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Redraws the complete screen. The background, the task bar and
;***                all windows will be updated.
;******************************************************************************
        ld a,DSK_SRV_DSKPLT
        jp SyDesktop_Service
      endif

      ifused SyDesktop_SCRCNV
SyDesktop_SCRCNV
;******************************************************************************
;*** Name           DesktopService_Convert4toIndexed
;*** Input          DE = graphic table address (has to be placed in data area)
;***                L  = graphic table ram bank (0-15)
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Table entry    00  1W  address of original 4colour bitmap data
;***                        (0=end of table)
;***                - if address is >0:
;***                02  1W  address of last header byte (byte 9) of a prepared 4
;***                        colour extended graphic; the empty bitmap data has to
;***                        follow this header directly and must have space for
;***                        the amount of data for a 16 colour bitmap of the same
;***                        graphic
;***                04  1B  graphic width in pixels divided by 2
;***                05  1B  graphic width in pixels
;***                06  1B  graphic height in pixels
;***                07  1B  size of source bitmap data (max 127)
;*** Description    Converts any amount of 4 colour graphics to 4 or 16 colour
;***                graphics depending on the video hardware.
;***                You may have graphics inside your window which act e.g. as
;***                control buttons (for an example Play, Pause, Forward symbols).
;***                These should have the same colour scheme the user configured
;***                for the whole GUI. In this case the application should use
;***                this function for converting these 4 colour bitmaps into 16
;***                colour bitmaps with the fitting colour scheme.
;***                The prepared graphics with extended header have to be in
;***                4 colour format with encoding type 0 (CPC, 4 colour; header
;***                byte 9). The width in bytes (header byte 0) has to be pixel
;***                width divided by 4.
;***                For the bitmap data there must be space for the amount of data
;***                needed for a 16 colour version (double the size of the 4
;***                colour version).
;***                The original 4colour bitmap data is without any header and
;***                must be CPC encoded.
;***                This function now goes through the table and copies and
;***                converts each of the original bitmaps to the prepared extended
;***                graphics.
;***                On systems with 4 colour video hardware the bitmap data is
;***                just copied, nothing else happens.
;***                On systems with 16 colour video hardware the bitmap data is
;***                converted to 16 colour graphic using the colour scheme used for
;***                window content (see Control Panel -> Display -> Colours ->
;***                Elements "Content").
;***                Call this function before opening the window for the first
;***                time.
;*** Example        conv_tab    dw symb_orig        ;original 4 colour bitmap
;***                            dw symb_ext + 9     ;last byte of extended header
;***                            db 8,16,12,12*4     ;xlen/2, xlen, ylen, size
;***                            dw 0                ;we have only one entry
;***
;***                symb_ext    db 4,16,12          ;xlen/4, xlen, ylen
;***                            dw symb_ext+10      ;pointer to bitmap data
;***                            dw symb_ext+9       ;pointer to encoding type
;***                            dw 4*12             ;size of bitmap data, if it
;***                                                ;would be 4 colours
;***                            db 0                ;encoding=cpc, colours=4
;***
;***                            ds 4*12             ;space for bitmap data, if it
;***                                                ;would be 16 colours
;***                            ;as we place the original bitmap data directly
;***                            ;behind, we only need to reserve the half amount
;***
;***                symb_orig   db #FF,#FF,#FF,#CF,#8F,#0F,#0F,#4B
;***                            db #8F,#2D,#0F,#4B,#8F,#69,#0F,#4B
;***                            db #8F,#F0,#E1,#4B,#9E,#F0,#E1,#4B
;***                            db #9E,#F0,#E1,#4B,#8F,#F0,#E1,#4B
;***                            db #8F,#69,#0F,#4B,#8F,#2D,#0F,#4B
;***                            db #8F,#0F,#0F,#4B,#F0,#F0,#F0,#C3
;******************************************************************************
        ld a,DSK_SRV_SCRCNV
        jp SyDesktop_Service
      endif

;DSK_SRV_DSKOPN  equ 11  ;open desktop background window
;DSK_SRC_DSKBIN  equ 13  ;initialize desktop background (no redraw)


;### SUB ROUTINES #############################################################

      ifused SyDesktop_Service
SyDesktop_Service
;******************************************************************************
;*** Input          A     = Function
;***                DE,HL = additional parameters
;*** Output         DE,HL = returned parameters
;*** Destroyed      AF,BC,IX,IY
;*** Description    Sends a service request message to the desktop manager,
;***                waits for the answer and returns with the result
;******************************************************************************
        ld c,MSC_DSK_DSKSRV
        ld (SyDSrvN),a
        push af
        call SyDesktop_SendMessage
        pop af
        cp DSK_SRV_MODGET
        jr z,SyDSrv1
        cp DSK_SRV_COLGET
        jr z,SyDSrv1
        cp DSK_SRV_DSKSTP
        ret nz
SyDSrv1 call SyDesktop_WaitMessage
        cp MSR_DSK_DSKSRV
        jr nz,SyDSrv1
        ld a,(SyDSrvN)
        cp (iy+1)
        jr nz,SyDSrv1
        ld de,(Message_Buffer+2)
        ld hl,(Message_Buffer+4)
        ret
SyDSrvN db 0
      endif

      ifused SyDesktop_SendMessage
SyDesktop_SendMessage
;******************************************************************************
;*** Input          C  = Command
;***                A  = Window ID
;***                DE,HL = additional parameters
;*** Output         -
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Sends a message to the desktop manager, which includes the
;***                window ID and additional parameters
;******************************************************************************
        ld iy,Message_Buffer
        ld b,a
        ld (Message_Buffer+0),bc
        ld (Message_Buffer+2),de
        ld (Message_Buffer+4),hl
        ld ixh,PRC_ID_DESKTOP
        ld a,(App_Process_ID)
        ld ixl,a
        rst #10
        ret
      endif

      ifused SyDesktop_WaitMessage
SyDesktop_WaitMessage
;******************************************************************************
;*** Input          -
;*** Output         IY = message buffer
;***                A  = first byte in the Message buffer (IY+0)
;*** Destroyed      AF,BC,DE,HL,IX,IY
;*** Description    Receives a message from desktop manager
;******************************************************************************
        ld iy,Message_Buffer
.SyDWMs1 ld ixh,PRC_ID_DESKTOP
        ld a,(App_Process_ID)
        ld ixl,a
        rst #08             ;wait for a desktop manager message
        db #dd:dec l
        jr nz,.SyDWMs1
        ld a,(Message_Buffer+0)
        ret
      endif