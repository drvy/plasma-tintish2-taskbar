# Tintish2 Taskbar

A task manager for horizontal KDE Plasma 6 panels, inspired by tint2 and CrunchBang++. It shows one block per virtual desktop, a strip of pinned launchers, grouped windows and drag and drop.

## Features

- One block per virtual desktop, labelled with the desktop name. Click a block to switch to that desktop.
- A strip of pinned launchers, at the start or the end of the bar. The context menu offers the application's jump-list actions.
- Window grouping with a popup, and configurable middle-click and mouse-wheel actions.
- Drag tasks to reorder them, or drop a window on another desktop's block to move it there.
- Filters for the current screen, the current activity and minimized windows, plus an option to hide empty desktops.
- Colours come from the Plasma theme (the `taskbar` and `taskbar-active` prefixes of `widgets/tasks`) or from custom colours set in the config dialog.

## Requirements

Plasma 6 and a horizontal panel. Vertical panels are not supported.

The jump-list actions use `org.kde.plasma.private.kicker`, a private Plasma API that can change between releases.

## Install

```sh
./install.sh
```

This copies the plasmoid to `~/.local/share/plasma/plasmoids`. Restart plasmashell, then add Tintish2 Taskbar to a panel. To remove it, run `./install.sh --uninstall`.

## Desktop menu integration

If another program on the session bus provides a desktop menu, the taskbar can open it when you right-click empty space. The program must expose `/Menu` with `popupFor(s)` and `takeLaunchDesktop(s)` on an interface named like the service. Set `desktopMenuService` to the service name to turn this on. It is empty by default, which disables it.

## Licence

GPL-2.0-or-later, see `LICENSE`. The code is modelled on plasma-desktop's taskmanager.
