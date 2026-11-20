/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Task handling modelled on Plasma's own task manager (plasma-desktop, applets/taskmanager).
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.workspace.dbus as DBus

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration
    readonly property alias vdi: virtualDesktopInfo
    readonly property alias activityInfo: activityInfo
    readonly property alias launcherModel: launcherModel
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Shared interaction state
    property Item dragSource
    property Item menuOwner
    property var groupPopup: null

    preferredRepresentation: fullRepresentation
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    // widthMode 0 = take all the free space, 1 = grow only up to maxWidth
    readonly property bool limited: !vertical && cfg.widthMode === 1
    // The limit is either pixels or a percentage of the screen width
    readonly property real maxPx: cfg.maxWidthUnit === 1
        ? Math.round(Plasmoid.containment.screenGeometry.width * cfg.maxPercent / 100) : cfg.maxWidth

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.maximumWidth: limited ? maxPx : Number.POSITIVE_INFINITY
    Layout.minimumWidth: vertical ? 0 : Kirigami.Units.gridUnit * 6
    Layout.minimumHeight: vertical ? Kirigami.Units.gridUnit * 6 : 0
    Layout.preferredWidth: vertical ? Kirigami.Units.gridUnit * 10
                                    : (limited ? maxPx : Kirigami.Units.gridUnit * 60)
    Layout.preferredHeight: vertical ? Kirigami.Units.gridUnit * 30 : Kirigami.Units.gridUnit * 2

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // Only pinned launchers: the screen filter points at an area no window can be in
    TaskManager.TasksModel {
        id: launcherModel
        filterByScreen: true
        screenGeometry: Qt.rect(-65536, -65536, 1, 1)
        hideActivatedLaunchers: false
        sortMode: TaskManager.TasksModel.SortManual
        groupMode: TaskManager.TasksModel.GroupDisabled
        activity: activityInfo.currentActivity
        filterByActivity: true

        onLauncherListChanged: Plasmoid.configuration.launchers = launcherList
        Component.onCompleted: launcherList = Plasmoid.configuration.launchers
    }

    Connections {
        target: Plasmoid.configuration
        function onLaunchersChanged(): void {
            if (JSON.stringify(launcherModel.launcherList) !== JSON.stringify(Plasmoid.configuration.launchers)) {
                launcherModel.launcherList = Plasmoid.configuration.launchers;
            }
        }
    }

    // --- Launchers -------------------------------------------------------------------------------

    function isPinned(url: url): bool {
        return launcherModel.launcherPosition(url) !== -1;
    }

    function pin(url: url): void {
        launcherModel.requestAddLauncher(url);
    }

    function unpin(url: url): void {
        launcherModel.requestRemoveLauncher(url);
    }

    // --- Application actions (jump list) ---------------------------------------------------------
    // The kicker favourites model already exposes the .desktop actions of an application.

    Kicker.SimpleFavoritesModel {
        id: appModel
    }

    Repeater {
        id: appRepeater
        model: appModel
        delegate: Item {
            visible: false
            required property var model
            readonly property var actions: model.actionList ?? []
        }
    }

    function storageId(url: url): string {
        const s = url.toString();
        if (s.startsWith("applications:")) {
            return s.slice("applications:".length);
        }
        return s.endsWith(".desktop") ? s.slice(s.lastIndexOf("/") + 1) : "";
    }

    /** @return {Array} actions of the application, without kicker's own entries */
    function appActions(url: url): var {
        const id = storageId(url);
        if (id === "") {
            return [];
        }
        appModel.favorites = [id];
        const item = appRepeater.itemAt(0);
        if (!item) {
            return [];
        }
        // Drop kicker's own entries (edit, uninstall, add to panel...) and tidy the separators
        const own = ["editApplication", "manageApplication", "addToDesktop", "addToPanel"];
        const kept = item.actions.filter(a => a.separator || (a.actionId && own.indexOf(String(a.actionId)) === -1
                                                              && (a.actionId === "_kicker_jumpListAction"
                                                                  || !String(a.actionId).startsWith("_kicker_"))));
        return kept.filter((a, i) => !(a.separator && (i === 0 || i === kept.length - 1 || kept[i - 1].separator)));
    }

    function runAppAction(actionId: var, argument: var): void {
        appModel.trigger(0, actionId, argument);
    }

    // --- Task interaction ------------------------------------------------------------------------

    function closePopup(): void {
        if (groupPopup) {
            groupPopup.visible = false;
        }
    }

    function togglePopup(task: Item): void {
        if (groupPopup && groupPopup.visualParent === task) {
            closePopup();
            return;
        }
        closePopup();
        groupPopup = popupComponent.createObject(root, {
            visualParent: task,
            bar: root,
            tasksModel: task.tasksModel,
            parentRow: task.index
        });
        groupPopup.visible = true;
    }

    function cycleGroup(task: Item): void {
        const tm = task.tasksModel;
        const count = tm.rowCount(task.modelIndex());
        let next = 0;
        for (let i = 0; i < count; ++i) {
            if (tm.data(tm.makeModelIndex(task.index, i), TaskManager.AbstractTasksModel.IsActive)) {
                next = (i + 1) % count;
                break;
            }
        }
        tm.requestActivate(tm.makeModelIndex(task.index, next));
    }

    function activateTask(task: Item, modifiers: int): void {
        const tm = task.tasksModel;
        const idx = task.modelIndex();
        if (modifiers & Qt.ShiftModifier || task.isLauncher) {
            tm.requestNewInstance(idx);
            return;
        }
        if (task.isGroup) {
            if (cfg.groupClickAction === 0) {
                togglePopup(task);
            } else {
                cycleGroup(task);
            }
            return;
        }
        if (task.isActive && cfg.minimizeActiveOnClick && task.model.IsMinimizable) {
            tm.requestToggleMinimized(idx);
        } else {
            tm.requestActivate(idx);
        }
        if (task.inPopup) {
            closePopup();
        }
    }

    function middleClick(task: Item): void {
        const tm = task.tasksModel;
        const idx = task.modelIndex();
        switch (cfg.middleClickAction) {
        case 1: tm.requestClose(idx); break;
        case 2: tm.requestNewInstance(idx); break;
        case 3: tm.requestToggleMinimized(idx); break;
        }
    }

    function showMenu(task: Item): void {
        menuOwner = task;
        const menu = menuComponent.createObject(task, {
            visualParent: task,
            bar: root,
            tasksModel: task.tasksModel,
            modelIndex: task.modelIndex()
        });
        menu.show();
    }

    function switchDesktop(id: var): void {
        const n = virtualDesktopInfo.desktopIds.indexOf(id) + 1;
        if (n > 0) {
            DBus.SessionBus.asyncCall({service: "org.kde.KWin", path: "/KWin", iface: "org.kde.KWin",
                                       member: "setCurrentDesktop", arguments: [n], signature: "(i)"});
        }
    }

    // --- Launch desktop --------------------------------------------------------------------------
    // A new window belongs to the desktop it was started from (or the one a menu entry was launched for),
    // not to every desktop, and is moved there when KWin put it elsewhere.

    // app key -> {desktop, stamp}
    property var homes: ({})

    TaskManager.TasksModel {
        id: allTasks
        groupMode: TaskManager.TasksModel.GroupDisabled
    }

    Connections {
        target: allTasks
        function onRowsInserted(parent: var, first: int, last: int): void {
            for (let i = first; i <= last; ++i) {
                root.taskAppeared(allTasks.makeModelIndex(i));
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: Object.keys(root.homes).length > 0
        onTriggered: {
            const now = Date.now();
            const kept = {};
            Object.keys(root.homes).forEach(k => {
                if (now - root.homes[k].stamp < 45000) {
                    kept[k] = root.homes[k];
                }
            });
            root.homes = kept;
        }
    }

    /** @return {string} key shared by a launcher, its startup feedback and its windows */
    function keyOf(appId: string, url: url): string {
        const id = appId !== "" ? appId : storageId(url);
        return id.endsWith(".desktop") ? id.slice(0, -8) : id;
    }

    /** @return {string} desktop a pending (startup / not yet placed) task belongs to */
    function homeOf(key: string): string {
        const e = homes[key];
        return e ? e.desktop : virtualDesktopInfo.currentDesktop;
    }

    function setHome(key: string, desktop: string): void {
        const h = Object.assign({}, homes);
        h[key] = { desktop: desktop, stamp: Date.now() };
        homes = h;
    }

    function dropHome(key: string): void {
        const h = Object.assign({}, homes);
        delete h[key];
        homes = h;
    }

    function moveWindow(idx: var, desktop: string): void {
        const t = TaskManager.AbstractTasksModel;
        const ds = allTasks.data(idx, t.VirtualDesktops) ?? [];
        if (allTasks.data(idx, t.IsOnAllVirtualDesktops) || (ds.length === 1 && ds[0] === desktop)) {
            return;
        }
        allTasks.requestVirtualDesktops(idx, [desktop]);
    }

    /** Asks the desktop menu whether it launched this application for a given desktop. */
    function askLaunchDesktop(key: string, winId: var): void {
        if (!cfg.desktopMenuService) {
            return;
        }
        DBus.SessionBus.asyncCall({service: cfg.desktopMenuService, path: "/Menu", iface: cfg.desktopMenuService,
                                   member: "takeLaunchDesktop", arguments: [key], signature: "(s)"},
            reply => {
                const desktop = String(Array.isArray(reply) ? reply[0] : (reply?.value ?? reply ?? ""));
                if (desktop === "" || virtualDesktopInfo.desktopIds.indexOf(desktop) < 0) {
                    return;
                }
                setHome(key, desktop);
                if (winId === undefined) {
                    return;
                }
                // Only the window that just appeared: older windows of the same app stay where they are
                const t = TaskManager.AbstractTasksModel;
                for (let i = 0; i < allTasks.count; ++i) {
                    const idx = allTasks.makeModelIndex(i);
                    if (allTasks.data(idx, t.IsWindow) && String(allTasks.data(idx, t.WinIdList)) === winId) {
                        moveWindow(idx, desktop);
                        dropHome(key);
                        break;
                    }
                }
            }, () => {});
    }

    function taskAppeared(idx: var): void {
        const t = TaskManager.AbstractTasksModel;
        const startup = allTasks.data(idx, t.IsStartup);
        const window = allTasks.data(idx, t.IsWindow);
        if (!startup && !window) {
            return;
        }
        const key = keyOf(allTasks.data(idx, t.AppId) ?? "", allTasks.data(idx, t.LauncherUrlWithoutIcon) ?? "");
        if (key === "") {
            return;
        }
        if (startup) {
            if (!homes[key]) {
                setHome(key, virtualDesktopInfo.currentDesktop);
                askLaunchDesktop(key, undefined);
            }
        } else if (homes[key]) {
            moveWindow(idx, homes[key].desktop);
            dropHome(key);
        } else {
            askLaunchDesktop(key, String(allTasks.data(idx, t.WinIdList)));
        }
    }

    // direction: true = next
    function wheel(block: Item, next: bool): void {
        if (cfg.wheelAction === 2) {
            const ids = virtualDesktopInfo.desktopIds;
            const i = ids.indexOf(virtualDesktopInfo.currentDesktop);
            switchDesktop(ids[(i + (next ? 1 : -1) + ids.length) % ids.length]);
            return;
        }
        const tm = block.tasksModel;
        if (!tm || tm.count === 0) {
            return;
        }
        const current = tm.activeTask;
        let target = next ? 0 : tm.count - 1;
        const currentRow = current.parent.valid ? current.parent.row : current.row;
        for (let i = 0; i < tm.count; ++i) {
            if (i === currentRow) {
                target = (i + (next ? 1 : -1) + tm.count) % tm.count;
                break;
            }
        }
        tm.requestActivate(tm.makeModelIndex(target));
    }

    // --- Drag and drop ---------------------------------------------------------------------------

    function startDrag(task: Item, imageUrl: url): void {
        dragSource = task;
        dragHelper.Drag.imageSource = imageUrl;
        dragHelper.Drag.mimeData = {
            "text/x-orgkdeplasmataskmanager_taskurl": task.model.LauncherUrlWithoutIcon.toString(),
            "application/x-orgkdeplasmataskmanager_taskbuttonitem": task.model.MimeData
        };
        dragHelper.Drag.active = true;
    }

    function endDrag(): void {
        dragHelper.Drag.active = false;
    }

    Item {
        id: dragHelper
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
        Drag.onDragFinished: root.dragSource = null
    }

    Component {
        id: menuComponent
        TaskMenu {}
    }

    Component {
        id: popupComponent
        GroupPopup {}
    }

    // --- Layout ----------------------------------------------------------------------------------

    // One entry per virtual desktop, or a single entry when the desktops are not split
    readonly property var blocks: {
        if (cfg.layoutMode === 0) {
            return virtualDesktopInfo.desktopIds.map((id, i) => ({
                id: id,
                name: virtualDesktopInfo.desktopNames[i] ?? ""
            }));
        }
        return [{ id: "", name: "" }];
    }

    fullRepresentation: RowLayout {
        spacing: 0

        Block {
            bar: root
            launchers: true
            visible: !root.cfg.launchersAtEnd && root.cfg.showLaunchers && count > 0
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            uniformCellSizes: root.cfg.equalBlocks && root.cfg.layoutMode === 0

            Repeater {
                model: root.blocks
                delegate: Block {
                    required property var modelData
                    required property int index
                    position: index
                    bar: root
                    desktopId: modelData.id
                    desktopName: modelData.name
                    scope: root.cfg.layoutMode
                }
            }

            Item {
                visible: !parent.uniformCellSizes && !root.limited
                Layout.fillWidth: true
            }
        }

        Block {
            bar: root
            launchers: true
            visible: root.cfg.launchersAtEnd && root.cfg.showLaunchers && count > 0
        }
    }
}
