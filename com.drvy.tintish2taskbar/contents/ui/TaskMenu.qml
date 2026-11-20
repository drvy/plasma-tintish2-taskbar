/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager

// Context menu of a task: app actions (jump list), pinning, window state, desktops.
PlasmaExtras.Menu {
    id: menu

    required property Item bar
    required property var tasksModel
    required property var modelIndex

    readonly property var atm: TaskManager.AbstractTasksModel
    readonly property bool isWindow: get(atm.IsWindow) === true
    readonly property bool isLauncher: get(atm.IsLauncher) === true
    readonly property url launcherUrl: get(atm.LauncherUrlWithoutIcon)
    // Apps that list their own "New Window" action do not need the generic entry as well
    property bool hasJumpList: false

    placement: {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.LeftEdge: return PlasmaExtras.Menu.RightPosedTopAlignedPopup;
        case PlasmaCore.Types.TopEdge: return PlasmaExtras.Menu.BottomPosedLeftAlignedPopup;
        case PlasmaCore.Types.RightEdge: return PlasmaExtras.Menu.LeftPosedTopAlignedPopup;
        default: return PlasmaExtras.Menu.TopPosedLeftAlignedPopup;
        }
    }

    onStatusChanged: {
        if (status === PlasmaExtras.Menu.Closed) {
            if (bar.menuOwner === visualParent) {
                bar.menuOwner = null;
            }
            destroy();
        }
    }

    function get(role: int): var {
        return tasksModel.data(modelIndex, role);
    }

    function newItem(parent: QtObject): PlasmaExtras.MenuItem {
        return Qt.createQmlObject(`
            import org.kde.plasma.extras as PlasmaExtras
            PlasmaExtras.MenuItem {}
        `, parent) as PlasmaExtras.MenuItem;
    }

    function newSeparator(parent: QtObject): PlasmaExtras.MenuItem {
        return Qt.createQmlObject(`
            import org.kde.plasma.extras as PlasmaExtras
            PlasmaExtras.MenuItem { separator: true }
        `, parent) as PlasmaExtras.MenuItem;
    }

    function show(): void {
        const actions = isWindow || isLauncher ? bar.appActions(launcherUrl) : [];
        hasJumpList = actions.some(a => a.actionId === "_kicker_jumpListAction");
        actions.forEach(a => {
            if (a.separator) {
                menu.addMenuItem(newSeparator(menu), newInstanceItem);
                return;
            }
            const item = newItem(menu);
            item.text = a.text;
            item.icon = a.icon ?? "";
            item.clicked.connect(() => bar.runAppAction(a.actionId, a.actionArgument));
            menu.addMenuItem(item, newInstanceItem);
        });
        if (actions.length > 0) {
            menu.addMenuItem(newSeparator(menu), newInstanceItem);
        }
        desktopsMenu.refresh();
        openRelative();
    }

    PlasmaExtras.MenuItem {
        id: newInstanceItem
        visible: menu.launcherUrl.toString() !== "" && !menu.hasJumpList
        text: i18n("Open New Window")
        icon: "window-new"
        onClicked: menu.tasksModel.requestNewInstance(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: menu.launcherUrl.toString() !== ""
        readonly property bool pinned: menu.bar.isPinned(menu.launcherUrl)
        text: pinned ? i18n("Unpin from Taskbar") : i18n("Pin to Taskbar")
        icon: pinned ? "window-unpin" : "window-pin"
        onClicked: pinned ? menu.bar.unpin(menu.launcherUrl) : menu.bar.pin(menu.launcherUrl)
    }

    PlasmaExtras.MenuItem {
        separator: true
        visible: menu.isWindow
    }

    PlasmaExtras.MenuItem {
        id: desktopsItem
        visible: menu.isWindow && menu.bar.vdi.numberOfDesktops > 1
                 && menu.get(menu.atm.IsVirtualDesktopsChangeable) === true
        text: i18n("Move to Desktop")
        icon: "virtual-desktops"

        readonly property PlasmaExtras.Menu submenu: PlasmaExtras.Menu {
            id: desktopsMenu
            visualParent: desktopsItem.action

            function refresh(): void {
                clearMenuItems();
                const vdi = menu.bar.vdi;
                if (vdi.numberOfDesktops <= 1) {
                    return;
                }
                const current = menu.get(menu.atm.VirtualDesktops) ?? [];
                let item = menu.newItem(desktopsMenu);
                item.text = i18n("All Desktops");
                item.checkable = true;
                item.checked = menu.get(menu.atm.IsOnAllVirtualDesktops) === true;
                item.clicked.connect(() => menu.tasksModel.requestVirtualDesktops(menu.modelIndex, []));
                menu.newSeparator(desktopsMenu);
                vdi.desktopIds.forEach((id, i) => {
                    const entry = menu.newItem(desktopsMenu);
                    entry.text = vdi.desktopNames[i];
                    entry.checkable = true;
                    entry.checked = current.indexOf(id) > -1;
                    entry.clicked.connect(() => menu.tasksModel.requestVirtualDesktops(menu.modelIndex, [id]));
                });
                menu.newSeparator(desktopsMenu);
                item = menu.newItem(desktopsMenu);
                item.text = i18n("New Desktop");
                item.icon = "list-add";
                item.clicked.connect(() => menu.tasksModel.requestNewVirtualDesktop(menu.modelIndex));
            }
        }
    }

    PlasmaExtras.MenuItem {
        visible: menu.isWindow
        enabled: menu.get(menu.atm.IsMaximizable) === true
        checkable: true
        checked: menu.get(menu.atm.IsMaximized) === true
        text: i18n("Maximize")
        icon: "window-maximize"
        onClicked: menu.tasksModel.requestToggleMaximized(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: menu.isWindow
        enabled: menu.get(menu.atm.IsMinimizable) === true
        checkable: true
        checked: menu.get(menu.atm.IsMinimized) === true
        text: i18n("Minimize")
        icon: "window-minimize"
        onClicked: menu.tasksModel.requestToggleMinimized(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: menu.isWindow
        checkable: true
        checked: menu.get(menu.atm.IsKeepAbove) === true
        text: i18n("Keep Above Others")
        icon: "window-keep-above"
        onClicked: menu.tasksModel.requestToggleKeepAbove(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: menu.isWindow
        checkable: true
        checked: menu.get(menu.atm.IsKeepBelow) === true
        text: i18n("Keep Below Others")
        icon: "window-keep-below"
        onClicked: menu.tasksModel.requestToggleKeepBelow(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: menu.isWindow
        enabled: menu.get(menu.atm.IsFullScreenable) === true
        checkable: true
        checked: menu.get(menu.atm.IsFullScreen) === true
        text: i18n("Fullscreen")
        icon: "view-fullscreen"
        onClicked: menu.tasksModel.requestToggleFullScreen(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        visible: menu.isWindow && Plasmoid.configuration.groupingStrategy !== 0
        checkable: true
        checked: menu.get(menu.atm.IsGroupable) === true
        text: i18n("Allow this program to be grouped")
        icon: "view-group"
        onClicked: menu.tasksModel.requestToggleGrouping(menu.modelIndex)
    }

    PlasmaExtras.MenuItem {
        separator: true
    }

    PlasmaExtras.MenuItem {
        property PlasmaCore.Action configureAction: Plasmoid.internalAction("configure")
        enabled: configureAction && configureAction.enabled
        visible: configureAction && configureAction.visible
        text: configureAction ? configureAction.text : ""
        icon: configureAction ? configureAction.icon : ""
        onClicked: configureAction.trigger()
    }

    PlasmaExtras.MenuItem {
        separator: true
        visible: menu.isWindow
    }

    PlasmaExtras.MenuItem {
        visible: menu.isWindow
        enabled: menu.get(menu.atm.IsClosable) === true
        text: menu.get(menu.atm.IsGroupParent) ? i18n("Close All") : i18n("Close")
        icon: "window-close"
        onClicked: menu.tasksModel.requestClose(menu.modelIndex)
    }
}
