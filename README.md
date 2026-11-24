<h1 align="center">Tintish2 Taskbar</h1>

<p align="center">
  A task manager for KDE Plasma 6 panels, inspired by tint2 and CrunchBang++.<br>
  One block per virtual desktop, pinned launchers, window grouping and drag and drop.
</p>

<p align="center">
  <img alt="Plasma 6" src="https://img.shields.io/badge/Plasma-6-1d99f3">
  <img alt="Licence GPL-2.0-or-later" src="https://img.shields.io/badge/licence-GPL--2.0--or--later-blue">
</p>

<p align="center">
  <img alt="Tintish2 Taskbar with three desktop blocks" src="docs/screenshots/taskbar.png">
</p>

## Why

The stock task manager mixes the windows of every desktop into one list, and a pager takes extra panel space. Tintish2 Taskbar puts both in one widget: each virtual desktop gets its own block of tasks, so you see at a glance what lives where.

## Features

- One block per virtual desktop, labelled with the desktop name. Click a block to switch to that desktop.
- A strip of pinned launchers, at the start or the end of the bar. The context menu offers the application's jump-list actions.
- Window grouping by application, with a popup that lists the grouped windows.
- Drag tasks to reorder them, or drop a window on another desktop's block to move it there.
- Filters for the current screen, the current activity and minimized windows, plus an option to hide empty desktops.
- Colours come from the Plasma theme or from custom colours set in the config dialog.

## Requirements

Plasma 6, in a horizontal or vertical panel.

The jump-list actions use `org.kde.plasma.private.kicker`, a private Plasma API that can change between releases.

## Install

```sh
git clone git@github.com:drvy/plasma-tintish2-taskbar.git
cd plasma-tintish2-taskbar
./install.sh
```

This copies the plasmoid to `~/.local/share/plasma/plasmoids`. Restart plasmashell, then add Tintish2 Taskbar to a panel:

```sh
kquitapp6 plasmashell; kstart plasmashell
```

To remove it, run `./install.sh --uninstall`.

## Settings

Right-click the widget and choose Configure. The dialog has three pages.

| Page | What you can set |
|------|------------------|
| Layout | Desktops as one block each, current desktop only, or all windows together. Desktop names, equal block widths, divider between blocks, hiding empty desktops. Window titles and their width, icon size, panel width (fill the free space or a maximum in pixels or percent). Pinned launchers: show them, and place them after the desktops. |
| Behavior | Filters (current screen, current activity, minimized only). Grouping and what clicking a group does. Sorting (none, manual, alphabetical). Click, middle-click and mouse-wheel actions. Tooltips. |
| Appearance | Style: Plasma theme or custom colours. Dimming of inactive tasks, active task highlight, space between tasks, corner radius, and the colours for desktop blocks, hovered, active and attention-needing tasks and text. |

When the style is Plasma theme, the widget reads the `taskbar` and `taskbar-active` prefixes of `widgets/tasks`. A theme that does not define them falls back to the generic task look.

## Desktop menu integration

If another program on the session bus provides a desktop menu, the taskbar can open it when you right-click empty space. The program must expose `/Menu` with `popupFor(s)` and `takeLaunchDesktop(s)` on an interface named like the service. Set the `desktopMenuService` config key to the service name to turn this on. It is empty by default, which disables it.

## Troubleshooting

- The widget does not appear in the list: restart plasmashell after installing.
- Launcher actions are missing: they depend on a private Plasma API, so a Plasma update can break them. Open an issue with your Plasma version.
- Clicking a desktop block does nothing: switching goes through KWin's D-Bus interface (`org.kde.KWin`), so it needs KWin running.

## Licence

GPL-2.0-or-later, see `LICENSE`. The code is modelled on plasma-desktop's taskmanager.
