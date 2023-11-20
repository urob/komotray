# komo*Tray*

A system tray status indicator for [komorebi](https://github.com/LGUG2Z/komorebi/). It shows the focused workspace and monitor and can be used to interact with komorebi.

![](assets/screenshot.png =x48)

## Status indicator

The icon indicates the currently focused monitor using ![](assets/icons/0-1.ico =16x) and ![](assets/icons/0-2.ico =16x) for the left and right monitor. The number at the center of the icon is the currently focused workspace *on the active monitor*.

For instance, the first of the following icons indicates that workspace 1 on the left monitor is focused. The second icon indicates that workspace 1 on the right monitor is focused, etc. The last icon indicates that komorebi is currently paused.

![](assets/icons/1-1.ico =48x)
![](assets/icons/1-2.ico =48x)
![](assets/icons/2-1.ico =48x)
![](assets/icons/2-2.ico =48x)
![](assets/icons/pause.ico =48x)

Setups with more than two monitors are supported but require adding a suitable collection of icons.

## Interaction

A single click on the tray icon will toggle komorebi to pause. A right click opens a menu with additional options to start/restart komorebi or to exit the application. Additional menu options can be configured using the AHK script.

I haven't yet decided whether I want to use komo*Tray* as a one-stop-shop for all interactions with komorebi. For now, I have most of my shortcuts set up in [whkd](https://github.com/LGUG2Z/whkd), and only use komo*Tray* to set up more complex actions such as swapping screens with a single shortcut or swapping workspaces when scrolling the mousewheel over the taskbar.

## Usage

To start the tray, simply run the AHK script or the bundled binary. If the komorebi server is already running (and isn't paused), then everything should be set. If the komorebi serves hasn't been started yet, then one can start by selecting "Restart Komorebi" from the tray's right-click menu.

***Note:*** The first time komo*Tray* is started, the tray icon may eventual disappear in the overflow menu. If this happens simply drag & drop it back to the tray area. After doing this once, Windows should remember the position of komo*Tray* and always show it.

