#SingleInstance, force
#NoEnv

#Include, %A_ScriptDir%\lib\JSON.ahk

; Set common config options
AutoStartKomorebi := true
global IconPath := A_ScriptDir . "/assets/icons/"
global KomorebiConfig := A_ScriptDir . "/komorebi-config/komorebi.json"

; ======================================================================
; Initialization
; ======================================================================

; Set up tray menu
Menu, Tray, NoStandard
Menu, Tray, add, Pause Komorebi, PauseKomorebi
Menu, Tray, add, Restart Komorebi, StartKomorebi
Menu, Tray, add  ; separator line
Menu, Tray, add, Reload Tray, ReloadTray
Menu, Tray, add, Exit Tray, ExitTray

; Define default action and activate it with single click
Menu, Tray, Default, Pause Komorebi
Menu, Tray, Click, 1

; Initialize internal states
IconState := -1
global Screen := 0
global LastTaskbarScroll := 0

; Start the komorebi server
Process, Exist, komorebi.exe
if (!ErrorLevel && AutoStartKomorebi)
    StartKomorebi(false)

; ======================================================================
; Event Handler
; ======================================================================

; Set up pipe
PipeName := "komotray"
PipePath := "\\.\pipe\" . PipeName
OpenMode := 0x01  ; access_inbound
PipeMode := 0x04 | 0x02 | 0x01  ; type_message | readmode_message | nowait
BufferSize := 64 * 1024

; Create named pipe instance
Pipe := DllCall("CreateNamedPipe", "Str", PipePath, "UInt", OpenMode, "UInt", PipeMode
    , "UInt", 1, "UInt", BufferSize, "UInt", BufferSize, "UInt", 0, "Ptr", 0, "Ptr")
if (Pipe = -1) {
    MsgBox, % "CreateNamedPipe: " A_LastError
    ExitTray()
}

; Wait for Komorebi to connect
Komorebi("subscribe " . PipeName)
DllCall("ConnectNamedPipe", "Ptr", Pipe, "Ptr", 0) ; set PipeMode = nowait to avoid getting stuck when paused

; Subscribe to Komorebi events
Loop {
    ; Continue if buffer is empty
    ExitCode := DllCall("PeekNamedPipe", "Ptr", Pipe, "Ptr", 0, "UInt", 1
        , "Ptr", 0, "UintP", BytesToRead, "Ptr", 0)
    if (!ExitCode || !BytesToRead) {
        Sleep, 50
        Continue
    }

    ; Read the buffer
    VarSetCapacity(Data, BufferSize, 0 )
    DllCall("ReadFile", "Ptr", Pipe, "Str", Data, "UInt", BufferSize
        , "PtrP", Bytes, "Ptr", 0)

    ; Strip new lines
    if (Bytes <= 1)
        Continue

    State := JSON.Load(StrGet(&Data, Bytes, "UTF-8")).state
    Paused := State.is_paused
    Screen := State.Monitors.focused
    ScreenQ := State.Monitors.elements[Screen + 1]
    Workspace := ScreenQ.workspaces.focused
    WorkspaceQ := ScreenQ.workspaces.elements[Workspace + 1]

    ; Update tray icon
    if (Paused | Screen << 1 | Workspace << 4 != IconState) {
        UpdateIcon(Paused, Screen, Workspace, ScreenQ.name, WorkspaceQ.name)
        IconState := Paused | Screen << 1 | Workspace << 4 ; use 3 bits for monitor (i.e. up to 8 monitors)
    }
}
Return

; ======================================================================
; Key Bindings
; ======================================================================

; Load key bindings
#Include, %A_ScriptDir%\komorebi-config\bindings.ahk

; Alt + scroll to cycle workspaces
!WheelUp::ScrollWorkspace("previous")
!WheelDown::ScrollWorkspace("next")

; Scroll taskbar to cycle workspaces
#if MouseIsOver("ahk_class Shell_TrayWnd") || MouseIsOver("ahk_class Shell_SecondaryTrayWnd")
    WheelUp::ScrollWorkspace("previous")
    WheelDown::ScrollWorkspace("next")
#if

; ======================================================================
; Functions
; ======================================================================

Komorebi(arg) {
    RunWait % "komorebic.exe " . arg,, Hide
}

StartKomorebi(reloadTray:=true) {
    Komorebi("stop")
    Komorebi("start -c " . KomorebiConfig)
    Komorebi("focus-follows-mouse enable")  ; fix bug where option is ignored when server is restarted
    if (reloadTray)
        ReloadTray()
}

PauseKomorebi() {
    Komorebi("toggle-pause")
}

SwapScreens() {
    ; Swap monitors on a 2 screen setup. ToDo: Add safeguard for 3+ monitors
    Komorebi("swap-workspaces-with-monitor " . 1 - Screen)
}

UpdateIcon(paused, screen, workspace, screenName, workspaceName) {
    Menu, Tray, Tip, % workspaceName . " on " . screenName
    icon := IconPath . workspace + 1 . "-" . screen + 1 . ".ico"
    if (!paused && FileExist(icon))
        Menu, Tray, Icon, %icon%
    else
        Menu, Tray, Icon, % IconPath . "pause.ico" ; also used as fallback
}

ReloadTray() {
    DllCall("CloseHandle", "Ptr", Pipe)
    Reload
}

ExitTray() {
    DllCall("CloseHandle", "Ptr", Pipe)
    Komorebi("stop")
    ExitApp
}

ScrollWorkspace(dir) {
    ; This adds a state-dependent debounce timer to adress an issue where a single wheel
    ; click spawns multiple clicks when a web browser is in focus.
    _isBrowser := WinActive("ahk_class Chrome_WidgetWin_1") || WinActive("ahk_class MozillaWindowClass")
    _t := _isBrowser ? 800 : 100
    ; Total debounce time = _t[this_call] + _t[last_call] to address interim focus changes
    if (A_PriorKey != A_ThisHotkey) || (A_TickCount - LastTaskbarScroll > _t) {
        LastTaskbarScroll := A_TickCount + _t
        Komorebi("mouse-follows-focus disable")
        Komorebi("cycle-workspace " . dir)
        ; ToDo: only re-enable if it was enabled before
        Komorebi("mouse-follows-focus enable")
    }
}

; ======================================================================
; Auxiliary Functions
; ======================================================================

MouseIsOver(WinTitle) {
    MouseGetPos,,, Win
    return WinExist(WinTitle . " ahk_id " . Win)
}

