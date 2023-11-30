; Hotkey bindings for Colemak layout

; Focus windows
 !m::       Komorebi("cycle-focus previous")
 !n::       Komorebi("cycle-focus next")
 !e::       Komorebi("cycle-monitor next")
 !o::       Komorebi("promote-focus")

; Move windows
+!m::       Komorebi("cycle-move previous")
+!n::       Komorebi("cycle-move next")
+!e::       Komorebi("cycle-move-to-monitor next")
+!o::
            Komorebi("manage")
            Komorebi("promote")
return

; Manipulate windows
 !f::       Komorebi("toggle-monocle")
 !t::       Komorebi("toggle-float")

 !x::       WinMinimize, A
+!c::       WinClose, A
+!t::       WinSet, Style, ^0xC00000, A  ; Toggle titlebar

; Window manager options
+!r::       Komorebi("retile")
 !p::       Komorebi("toggle-pause")

; Layouts
 !'::       Komorebi("cycle-layout next")
+!'::       Komorebi("cycle-layout previous")

 !y::       Komorebi("flip-layout horizontal")
+!y::       Komorebi("flip-layout vertical")

 !?::   SwapScreens()

; Resize
 !l::       Komorebi("resize-axis horizontal increase")
 !j::       Komorebi("resize-axis horizontal decrease")
+!l::       Komorebi("resize-axis vertical increase")
+!j::       Komorebi("resize-axis vertical decrease")

; Workspaces
 !k::       Komorebi("cycle-workspace previous")
 !h::       Komorebi("cycle-workspace next")

+!k::       Komorebi("cycle-move-to-workspace previous")
+!h::       Komorebi("cycle-move-to-workspace next")

