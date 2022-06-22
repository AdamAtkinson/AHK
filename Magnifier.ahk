
; {{ <----  This script was written in Notepad++ employing a semicolon and double curley braces for folding
; }} <----  these braces are comments and are not interpreted by the compiler, they can be safely omitted

; IMPORTANT - Single curley braces are not preceded by a semicolon and must not be omitted

; {{  This portion of the script runs uncondiciontally...
    OnExit handle_exit
    CoordMode, Mouse, Screen    

    antialize:=4            ; antialias for better results, 4 (recommended) or 0
    titlebar:=32            ; height of title bar
    toolbar_def:=50         ; default toolbar height (restore height)
    toolbar := toolbar_def  ; current toolbar height
    l :=20                  ; length of crosshair leg (1/2 total length)
    xhwidth :=8             ; line width of crosshair
    ccx := 1                ; index for GUI controls
    cs := 40                ; spacer for GUI controls
    defaultw := 740         ; default/starting window width
    defaulth := 250         ; default/starting window height
    defaultx := 1           ; default/starting left window edge location
    defaulty := 1           ; default/starting top window edge location
    hide_gui_timer :=20     ; number of seconds to hide magnifier before reshowing
    auto_exit_timer := 0    ; number of seconds before window is automatically closed, 0 is disabled

    ; convert timer values to seconds (positive repeating timer, negative timer only runs once)
    hide_gui_timer := hide_gui_timer * -1000
    auto_exit_timer := auto_exit_timer * -1000

    ; the auto exit timer is disabled by default but can be helpful
    ; NOTE - this timer can be used to automatically break out of most infinite loops
    if auto_exit_timer != 0
        settimer, debugexit, %auto_exit_timer% 
    
    ; define GUI
    Gui, +AlwaysOnTop +Owner +Resize                            ; window properties
    Gui, Add, DropDownList, vzoom y10 w%cs%, 0.5|1|2||4|8|16    ; zoom levels
    ccx := cs*2
    Gui, Add, Button, x%ccx% y10 w15 gmovelr, <                 ; move left button
    ccx := ccx+15
    Gui, Add, Button, x%ccx% y1 w20 gmoveud, /\                 ; move up button
    Gui, Add, Button, x%ccx% y20 w20 gmoveud, \/                ; move down button
    ccx := ccx+20
    Gui, Add, Button, x%ccx% y10 w15 gmovelr, >                 ; move right button
    ccx := ccx+cs
    Gui, Add, checkbox, y5 x%ccx% vpermamove, Auto              ; allow automatic window movement
    Gui, Add, Button, x%ccx% y20 w40 gtogglemoveoff, Off        ; disable and reset auto movement settings
    ccx := ccX + cs + 10
    Gui, Add, Radio, y5 x%ccx% vlr, Left/Right                  ; use left/right movement behavior
    Gui, Add, Radio, y22 x%ccx% vud, Up/Down                    ; use up/down movement behavior
    ccx := ccX + cs*3
    Gui, Add, Button, x%ccx% y1 gHideMagnifier, Hide            ; temporarily hide the window
    Gui, Add, Button, x%ccx% y20 gForceReload, Reload           ; close and reload window
    ccx := ccX + cs*2
    ccx := ccX + cs*2
    Gui, Add, Slider, vdelay x%ccx% y10 Range15-200             ; repaint delay skuder (lower is smoother but uses more resources)
    ccx := ccX + cs*2
    ccx := ccX + cs*2
    Gui, Add, Text, x%ccx% y15 w80 vdelay2                      ; repaint delay time in ms (set by slider)
    ccx := cs*2
    
    ; show GUI
    Gui, Show, NoActivate w%defaultw% h%defaulth% x%defaultx% y%defaulty% , AHKMagnifier

    ; get GUI handle, set subwindow, get subwindow handle
    WinGet ScreenID, id ,AHKMagnifier ;
    WinSet, Transparent , 255, AHKMagnifier
    WinGet, SourceID, id

    ; create screen/image objects
    hdd_frame := DllCall( "GetDC", UInt, SourceID )
    hdc_frame := DllCall( "GetDC", UInt, ScreenID )
    hdc_buffer := DllCall("gdi32.dll\CreateCompatibleDC", UInt, hdc_frame) ; buffer
    hbm_buffer := DllCall("gdi32.dll\CreateCompatibleBitmap", UInt,hdc_frame, Int,A_ScreenWidth, Int,A_ScreenHeight)
    
    ;specify the style, thickness and color of the crosshair lines
    h_pen := DllCall( "gdi32.dll\CreatePen", "int", 0, "int", xhwidth, "uint", 0x00FF00)
    h1_pen := DllCall( "gdi32.dll\CreatePen", "int", 0, "int", 2, "uint", 0x0000FF)

    Gosub, Repaint
    return
; }} end of unconditional execution segment


togglemoveoff:
; {{
    permamove := 0
    GuiControl,, permamove, %permamove%
    GuiControl,, lr, %permamove%
    GuiControl,, ud, %permamove%
    Return
; }}


movelr:
; {{
    CoordMode, Mouse, Screen
    SetTimer, Repaint , Off
    WinGetPos, wx, wy, ww, wh , AHKMagnifier
    if (wx > defaultx)
        wx := defaultx
    else
        wx := A_ScreenWidth - ww
    GuiControl,, lr, %permamove%
    WinMove, AHKMagnifier, , wx, wy
    SetTimer, Repaint , %delay%
    Return
; }}


moveud:
; {{
    CoordMode, Mouse, Screen
    SetTimer, Repaint , Off
    WinGetPos, wx, wy, ww, wh , AHKMagnifier
    if (wy > defaulty)
        wy := defaulty
    else
        wy := A_ScreenHeight - wh
    GuiControl,, ud, %permamove%
    WinMove, AHKMagnifier, , wx, wy
    SetTimer, Repaint , %delay%
    Return
; }}


HideMagnifier:
toggle_gui_off:
; {{
    SetTimer, Repaint , Off
    Gui, Hide
    SetTimer, toggle_gui_on , %hide_gui_timer%
    Return
; }}


toggle_gui_on:
; {{
    Gui, Show, NoActivate
    SetTimer, Repaint, %delay%
    Return
; }}    


Repaint:
; {{
    CoordMode, Mouse, Screen                    ; set again because this sub can be called asynchrously without focus
    MouseGetPos, start_x, start_y, cwid,        ; get mouse position, the trailing comma is required
    WinGetTitle, cwtitle, ahk_id %cwid%         ; get title of window under mouse
    Gui, Submit, NoHide                         ; puts GUI controls into readable state
    GuiControl,, delay2 , delay %delay% ms      ; reads GUI controls
    WinGetPos, wx, wy, ww, wh , AHKMagnifier    ; gets window dimensions
    wh2 := wh - toolbar                         ; calculates height of subwindow
    
    ; repainting when the cursor is in the magnification area causes a disorienting feedback loop
    ; avoid this by setting flag 1 if the cursor is on the magnification area of the magnifier
    ; and only repainting if the flag is 0
    
    ; test if cursor is not on the magnifier window
    if cwtitle != AHKMagnifier                  
        iscursorfault := 0
    ; test if cursor is on the magnifier but not on the magnification area
    else
        if (start_y < (wy+toolbar+titlebar+30)) 
            iscursorfault := 0
    ; cursor must be on the magnifier and in the magnification area, set flag 1 - do not repaint
    else                                       
        iscursorfault := 1
        
    ; repaint if flag is 0 - the cursor is not on the magnification area of the magnifier
    if iscursorfault = 0
    {
        DllCall( "gdi32.dll\SetStretchBltMode", "uint", hdc_frame, "int", antialize )  ; Halftone better quality with stretch

        DllCall("gdi32.dll\StretchBlt", UInt,hdc_frame, Int,0, Int,toolbar, Int,ww, Int,wh - toolbar
                 , UInt,hdd_frame, Int
                 , start_x-(ww / 2 / zoom)
                 , Int,start_y -( wh2 / 2/zoom), Int,ww / zoom, Int,wh2 / zoom ,UInt,0xCC0020) ; SRCCOPY

        ; find center of window to draw Crosshair
        cx := round( ww / 2 )
        cy := round( ( wh + toolbar ) / 2 )
        ; select the correct pen into DC
        DllCall( "gdi32.dll\SelectObject", "uint", hdc_frame, "uint", h_pen )         
        ; update the current position to specified point
        DllCall( "gdi32.dll\MoveToEx", "uint", hdc_frame, "int", cx, "int", cy-l, "uint", 0)
        ; draw a line from the current position up to, but not including, the specified point.
        DllCall( "gdi32.dll\LineTo", "uint", hdc_frame, "int", cx, "int", cy + l )
        ; update the current position to specified point
        DllCall( "gdi32.dll\MoveToEx", "uint", hdc_frame, "int", cx-l, "int", cy, "uint", 0)
        ; draw a line from the current position up to, but not including, the specified point.
        DllCall( "gdi32.dll\LineTo", "uint", hdc_frame, "int", cx+l, "int", cy)
        ; change the pen
        DllCall( "gdi32.dll\SelectObject", "uint", hdc_frame, "uint", h1_pen )         
        ; update the current position to specified point
        DllCall( "gdi32.dll\MoveToEx", "uint", hdc_frame, "int", cx, "int", cy-l, "uint", 0)
        ; draw a line from the current position up to, but not including, the specified point.
        DllCall( "gdi32.dll\LineTo", "uint", hdc_frame, "int", cx, "int", cy + l )
        ; update the current position to specified point
        DllCall( "gdi32.dll\MoveToEx", "uint", hdc_frame, "int", cx-l, "int", cy, "uint", 0)
        ; draw a line from the current position up to, but not including, the specified point.
        DllCall( "gdi32.dll\LineTo", "uint", hdc_frame, "int", cx+l, "int", cy)            
    }
    ; the cursor was in the magnification area so call the window relocation subroutines
    else
    {
        if lr = 1
            gosub, movelr
        else
            if ud = 1
            gosub, moveud
    }
    SetTimer, Repaint , %delay%
    Return
; }}


ForceReload:
; {{
Reload
Sleep 1000 ; If successful, the reload will close this instance during the Sleep, so the line below will never be reached.
MsgBox The script could not be reloaded.
return
; }}


debugexit:
GuiClose:
handle_exit:
; {{
    DllCall("gdi32.dll\DeleteObject", UInt,hbm_buffer)
    DllCall("gdi32.dll\DeleteObject", UInt,h_pen)
    DllCall("gdi32.dll\DeleteObject", UInt,h1_pen)
    DllCall("gdi32.dll\DeleteDC", UInt,hdc_frame )
    DllCall("gdi32.dll\DeleteDC", UInt,hdd_frame )
    DllCall("gdi32.dll\DeleteDC", UInt,hdc_buffer)
    ExitApp
; }}
