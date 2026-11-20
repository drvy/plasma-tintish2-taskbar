# Tintish2 Taskbar

A KDE Plasma 6 task manager for horizontal panels, inspired by tint2 and CrunchBang++: one block per virtual
desktop, a strip of pinned launchers, window grouping and drag and drop.

## Features

- One block per virtual desktop, with the desktop name; click a block to switch to it.
- Pinned launcher strip (start or end of the bar) with the application's jump-list actions in the context menu.
- Window grouping with a popup, configurable middle click and mouse wheel actions.
- Drag to reorder tasks, or drop a window onto another desktop's block to move it.
- Filters: current screen, current activity, minimized only, hide empty desktops.
- Appearance: follows the Plasma theme (`widgets/tasks`, prefixes `taskbar` and `taskbar-active`) or custom colours.

## Requirements

Plasma 6. The jump-list actions use `org.kde.plasma.private.kicker`, a private API that may change between Plasma
releases. Horizontal panels only.

## Install

```sh
./install.sh            # installs to ~/.local/share/plasma/plasmoids
./install.sh --uninstall
```

Then add **Tintish2 Taskbar** to a panel.

## Optional desktop menu integration

If a service on the session bus exposes `/Menu` with the methods `popupFor(s)` and `takeLaunchDesktop(s)` on an
interface named like the service, set the `desktopMenuService` config key to its name. Right-clicking empty
taskbar space then opens that menu. Empty by default (disabled).

## Licence

GPL-2.0-or-later, see `LICENSE`. Modelled on plasma-desktop's taskmanager.
