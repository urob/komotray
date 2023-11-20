#SingleInstance, force
#HotkeyInterval 20
#MaxHotkeysPerInterval 20000

#Include, %A_ScriptDir%\lib\JSON.ahk

; Set common config options
global IconPath = A_ScriptDir . "/assets/icons/"

; ======================================================================
; Auto Execute
; ======================================================================

; Set up tray menu
Menu, Tray, NoStandard
Menu, Tray, add, Pause Komorebi, PauseKomorebi
Menu, Tray, add, Restart Komorebi, StartKomorebi
Menu, Tray, add                         ; separator line
Menu, Tray, add, Reload Tray, Reload
Menu, Tray, add, Exit Tray, Exit

; Define default action and activate it with single click
Menu, Tray, Default, Pause Komorebi
Menu, Tray, Click, 1

; Initialize internal states
IconState := -1
global Screen := 0
global TaskbarPrimaryID = 0
global TaskbarSecondaryID = 0

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
    Exit()
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
        IconState := Paused | Screen << 1 | Workspace << 4 ; # of screens must be <= 2**3
    }
}
MsgBox, An unexpected error has occured.
Exit()

; ======================================================================
; Functions
; ======================================================================

Komorebi(arg) {
    RunWait % "komorebic.exe " . arg,, Hide
}

StartKomorebi() {
    Komorebi("stop --whkd")
    Komorebi("start -c " . A_ScriptDir . "\..\komorebi\komorebi.json --whkd")
    Reload()
}

PauseKomorebi() {
    Komorebi("toggle-pause")
}

SwapScreen() {
    ; Swaps monitors. ToDo: Add safeguard for 3+ monitors
    Komorebi("swap-workspaces-with-monitor " . 1 - Screen)
}

UpdateIcon(paused, screen, workspace, screenName, workspaceName) {
    Menu, Tray, Tip, % workspaceName . " on " . screenName
    icon := IconPath . workspace + 1 . "-" . screen + 1 . ".ico"
    if (!paused && FileExist(icon))
        Menu, Tray, Icon, %icon%
    else
        Menu, Tray, Icon, % IconPath . "pause.ico" ; also acts as fallback
}

Reload() {
    DllCall("CloseHandle", "Ptr", Pipe)
    Reload
}

Exit() {
    DllCall("CloseHandle", "Ptr", Pipe)
    Komorebi("stop --whkd")
    ExitApp
}

OnTaskbarScroll(dir) {
    if (IsCursorHoveringTaskbar()) {
        Komorebi("cycle-workspace " . dir)
        Sleep, 500
    }
}

IsCursorHoveringTaskbar() {
    MouseGetPos,,, mouseHoveringID
    if (!TaskbarPrimaryID) {
        WinGet, TaskbarPrimaryID, ID, ahk_class Shell_TrayWnd
    }
    if (!TaskbarSecondaryID) {
        WinGet, TaskbarSecondaryID, ID, ahk_class Shell_SecondaryTrayWnd
    }
    return (mouseHoveringID == taskbarPrimaryID || mouseHoveringID == TaskbarSecondaryID)
}

; ======================================================================
; Key Bindings
; ======================================================================

!x::WinMinimize, A
!+c::WinClose, A
!SC033::SwapScreen() ; SC033 = ,

~WheelUp::OnTaskbarScroll("previous") ; ~ makes hotkey available to other apps
~WheelDown::OnTaskbarScroll("next")

