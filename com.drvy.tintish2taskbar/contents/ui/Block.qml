/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.plasma.workspace.dbus as DBus

// A group of tasks: the pinned launchers strip, or the windows of one virtual desktop (tint2 "multi_desktop").
Item {
    id: block

    required property Item bar

    property bool launchers: false
    property string desktopId: ""
    property string desktopName: ""
    // 0 = this desktop only, 1 = whatever desktop is current, 2 = every window
    property int scope: 0

    readonly property var cfg: Plasmoid.configuration
    readonly property var tasksModel: launchers ? bar.launcherModel : windows.object
    readonly property int count: tasksModel ? tasksModel.count : 0
    readonly property bool current: !launchers && (scope !== 0 || bar.vdi.currentDesktop === desktopId)
    readonly property int margin: 6
    // 1-based position among the desktop blocks, for the divider
    property int position: 0

    visible: launchers ? (cfg.showLaunchers && count > 0)
                       : (!cfg.hideEmptyDesktops || count > 0 || current)

    Layout.fillHeight: true
    // Limited width: blocks grow in proportion to their content to fill it
    readonly property bool stretch: !launchers && (cfg.equalBlocks || (cfg.widthMode === 1 && bar.limited))
    Layout.fillWidth: stretch
    Layout.horizontalStretchFactor: cfg.equalBlocks ? 1 : Math.max(1, Math.round(row.implicitWidth))
    Layout.minimumWidth: row.implicitWidth + 2 * margin
    Layout.preferredWidth: row.implicitWidth + 2 * margin

    Instantiator {
        id: windows
        active: !block.launchers
        delegate: TaskManager.TasksModel {
            virtualDesktop: block.desktopId
            filterByVirtualDesktop: block.scope === 0
            filterByCurrentVirtualDesktop: block.scope === 1
            screenGeometry: Plasmoid.containment.screenGeometry
            filterByScreen: block.cfg.showOnlyCurrentScreen
            activity: block.bar.activityInfo.currentActivity
            filterByActivity: block.cfg.showOnlyCurrentActivity
            filterNotMinimized: block.cfg.showOnlyMinimized
            sortMode: block.cfg.sortingStrategy === 2 ? TaskManager.TasksModel.SortAlpha
                                                      : TaskManager.TasksModel.SortManual
            groupMode: block.cfg.groupingStrategy === 0 ? TaskManager.TasksModel.GroupDisabled
                                                        : TaskManager.TasksModel.GroupApplications
            groupInline: false
        }
    }

    TaskFrame {
        anchors.fill: parent
        kind: block.current && !block.launchers ? "taskbar-active" : "taskbar"
    }

    // Thin divider between neighbouring blocks (and after the launchers)
    Rectangle {
        visible: block.cfg.showDividers && ((!block.launchers && block.scope === 0 && block.position > 0)
                                            || (block.launchers && !block.cfg.launchersAtEnd))
        anchors {
            top: parent.top
            bottom: parent.bottom
            topMargin: 5
            bottomMargin: 5
            left: block.launchers ? undefined : parent.left
            right: block.launchers ? parent.right : undefined
        }
        width: 1
        color: Kirigami.Theme.textColor
        opacity: 0.12
    }

    RowLayout {
        id: row
        anchors {
            fill: parent
            leftMargin: block.margin
            rightMargin: block.margin
        }
        spacing: Kirigami.Units.largeSpacing

        Text {
            visible: !block.launchers && block.scope === 0 && block.cfg.showDesktopNames
            Layout.alignment: Qt.AlignVCenter
            text: block.desktopName
            elide: Text.ElideRight
            Layout.maximumWidth: Kirigami.Units.gridUnit * 8
            Layout.rightMargin: Kirigami.Units.smallSpacing
            font.family: "Liberation Sans"
            font.pixelSize: 12
            color: block.cfg.styleSource === 0
                 ? (block.current ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor)
                 : (block.current ? block.cfg.colorLabelActive : block.cfg.colorLabel)
        }

        RowLayout {
            id: tasksRow
            Layout.fillHeight: true
            Layout.fillWidth: true
            spacing: block.cfg.spacing

            Repeater {
                model: block.tasksModel
                delegate: TaskButton {
                    bar: block.bar
                    tasksModel: block.tasksModel
                    blockDesktop: !block.launchers && block.scope === 0 ? block.desktopId : ""
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }
    }

    // Left click on empty space switches to this desktop
    TapHandler {
        enabled: !block.launchers && block.scope === 0
        acceptedButtons: Qt.LeftButton
        onTapped: block.bar.switchDesktop(block.desktopId)
    }

    // Right click on empty space opens the desktop (Openbox) menu; Shift keeps the default panel menu
    TapHandler {
        acceptedButtons: Qt.RightButton
        acceptedModifiers: Qt.NoModifier
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: eventPoint => {
            const p = block.mapToItem(tasksRow, eventPoint.position.x, eventPoint.position.y);
            const hit = tasksRow.childAt(p.x, p.y);
            if ((hit && hit.index !== undefined) || !cfg.desktopMenuService) {
                return;
            }
            DBus.SessionBus.asyncCall({service: cfg.desktopMenuService, path: "/Menu",
                                       iface: cfg.desktopMenuService, member: "popupFor",
                                       arguments: [block.launchers ? "" : block.desktopId], signature: "(s)"});
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        enabled: block.cfg.wheelAction !== 0
        onWheel: event => block.bar.wheel(block, event.angleDelta.y < 0)
    }

    DropArea {
        id: drop
        anchors.fill: parent

        property Item ignored

        onEntered: event => {
            if (event.formats.indexOf("text/x-plasmoidservicename") >= 0) {
                event.accepted = false;
            }
        }

        // Live reorder while dragging inside the same block
        onPositionChanged: event => {
            const src = block.bar.dragSource;
            if (!src || src.tasksModel !== block.tasksModel || (!block.launchers && block.cfg.sortingStrategy !== 1)) {
                return;
            }
            const p = drop.mapToItem(tasksRow, event.x, event.y);
            const above = tasksRow.childAt(p.x, p.y);
            if (!above || above === src || above === drop.ignored || above.index === undefined) {
                return;
            }
            block.tasksModel.move(src.index, above.index);
            drop.ignored = above;
            ignoreTimer.restart();
        }

        onDropped: event => {
            const src = block.bar.dragSource;
            if (src && !src.isLauncher && !block.launchers && src.tasksModel !== block.tasksModel
                    && block.scope === 0) {
                // Dropped on another desktop: move the window(s)
                src.tasksModel.requestVirtualDesktops(src.modelIndex(), [block.desktopId]);
                event.accepted = true;
                return;
            }
            if (block.launchers) {
                if (src && !src.isLauncher) {
                    block.bar.pin(src.model.LauncherUrlWithoutIcon);
                } else if (!src && event.hasUrls) {
                    event.urls.forEach(u => block.bar.pin(u));
                }
            }
        }

        Timer {
            id: ignoreTimer
            interval: 600
            onTriggered: drop.ignored = null
        }
    }
}
