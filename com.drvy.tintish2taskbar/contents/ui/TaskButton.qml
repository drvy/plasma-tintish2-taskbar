/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// One window, group or pinned launcher.
PlasmaCore.ToolTipArea {
    id: task

    required property var model
    required property int index
    required property Item bar
    required property var tasksModel

    // Desktop of the block showing this button ("" = not tied to one)
    property string blockDesktop: ""

    // Set when the button is a row of the group popup
    property bool inPopup: false
    property int parentRow: -1

    readonly property var cfg: Plasmoid.configuration
    readonly property bool isLauncher: model.IsLauncher
    readonly property bool isGroup: model.IsGroupParent
    readonly property bool isActive: model.IsActive
    readonly property int pad: 3
    // Same size for every icon: the standard icon size nearest to the room available
    readonly property int iconPx: {
        if (cfg.iconSize > 0) {
            return cfg.iconSize;
        }
        // Vertical panels: the button is as wide as the panel; with titles the icon stays at a normal size
        const room = (bar.vertical ? (showLabel ? 24 + 2 * pad : width) : height) - 2 * pad;
        return [16, 22, 24, 32, 48, 64].reduce((best, s) => Math.abs(s - room) < Math.abs(best - room) ? s : best, 16);
    }
    readonly property bool showLabel: inPopup || (cfg.showLabels && !isLauncher)
    readonly property bool menuOpen: bar.menuOwner === task

    /** @return {QModelIndex} index of this task in its model */
    function modelIndex() {
        return inPopup ? tasksModel.makeModelIndex(parentRow, index) : tasksModel.makeModelIndex(index);
    }

    readonly property string appKey: bar.keyOf(model.AppId ?? "", model.LauncherUrlWithoutIcon ?? "")
    // Launch feedback and windows not placed yet have no desktop, so every desktop model lists them:
    // only the desktop they were started from shows them
    readonly property bool pending: model.IsStartup
        || (model.IsWindow && !model.IsOnAllVirtualDesktops && (model.VirtualDesktops ?? []).length === 0)

    visible: !model.SkipTaskbar && !(pending && !isLauncher && blockDesktop !== "" && bar.homeOf(appKey) !== blockDesktop)

    readonly property bool vertical: bar.vertical && !inPopup
    Layout.fillHeight: !inPopup && !vertical
    Layout.fillWidth: showLabel || vertical
    Layout.minimumWidth: iconPx + 2 * pad
    Layout.preferredWidth: showLabel && !vertical ? cfg.labelWidth : iconPx + 2 * pad
    Layout.maximumWidth: vertical ? Number.POSITIVE_INFINITY : (showLabel ? cfg.labelWidth : iconPx + 2 * pad)
    Layout.minimumHeight: vertical ? iconPx + 2 * pad : 0
    Layout.preferredHeight: vertical ? iconPx + 2 * pad : -1
    Layout.maximumHeight: vertical ? iconPx + 2 * pad : Number.POSITIVE_INFINITY

    mainText: model.display
    subText: isGroup ? i18n("%1 windows", model.ChildCount) : model.GenericName
    icon: model.decoration
    active: cfg.showToolTips && !menuOpen && !(bar.groupPopup && bar.groupPopup.visible)
    location: Plasmoid.location

    Accessible.name: model.display
    Accessible.role: Accessible.Button
    Accessible.onPressAction: bar.activateTask(task, 0)

    TaskFrame {
        anchors.fill: parent
        anchors.margins: 1
        active: task.isActive
        running: !task.isLauncher
        minimized: !!task.model.IsMinimized
        kind: {
            if (task.isLauncher) return task.containsMouse || task.menuOpen ? "hover" : "normal";
            if (task.model.IsDemandingAttention) return "attention";
            if (task.isActive) return task.cfg.highlightStyle === 1 ? "focus" : "normal";
            if (task.containsMouse || task.menuOpen) return "hover";
            if (task.model.IsMinimized) return "minimized";
            return "normal";
        }
    }

    Item {
        id: content
        anchors.fill: parent
        anchors.margins: task.pad

        Kirigami.Icon {
            id: icon
            x: task.showLabel ? 0 : (parent.width - width) / 2
            anchors.verticalCenter: parent.verticalCenter
            width: task.inPopup ? Kirigami.Units.iconSizes.medium : task.iconPx
            height: width
            source: task.model.decoration
            active: task.containsMouse
            // tint2 task_icon_asb: inactive 80 %, active 100 %
            opacity: (task.isLauncher || task.inPopup || task.isActive || task.containsMouse || !task.cfg.dimInactive) ? 1 : 0.8
        }

        Text {
            visible: task.showLabel
            anchors {
                left: icon.right
                leftMargin: Kirigami.Units.smallSpacing
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            text: task.model.display
            elide: Text.ElideRight
            font: Kirigami.Theme.defaultFont
            color: task.cfg.styleSource === 0 ? Kirigami.Theme.textColor
                 : (task.isActive ? task.cfg.colorLabelActive : task.cfg.colorLabel)
        }

        Rectangle {
            visible: task.isGroup && task.model.ChildCount > 1 && !task.inPopup
            anchors { right: parent.right; bottom: parent.bottom }
            width: Math.max(height, badge.implicitWidth + 4)
            height: badge.implicitHeight
            radius: height / 2
            color: Kirigami.Theme.highlightColor
            Text {
                id: badge
                anchors.centerIn: parent
                text: task.model.ChildCount
                color: Kirigami.Theme.highlightedTextColor
                font.pixelSize: Math.max(9, Kirigami.Theme.defaultFont.pixelSize - 3)
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: (eventPoint, button) => task.bar.activateTask(task, point.modifiers)
    }

    TapHandler {
        acceptedButtons: Qt.MiddleButton
        onTapped: task.bar.middleClick(task)
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: task.bar.showMenu(task)
    }

    DragHandler {
        id: dragHandler
        target: null
        enabled: !task.inPopup
        grabPermissions: PointerHandler.CanTakeOverFromHandlersOfDifferentType
        onActiveChanged: {
            if (active) {
                icon.grabToImage(result => {
                    if (!dragHandler.active) {
                        return;
                    }
                    task.bar.startDrag(task, result.url);
                });
            } else {
                task.bar.endDrag();
            }
        }
    }

    // Dragging something over a window brings it forward so it can be dropped there
    DropArea {
        anchors.fill: parent
        enabled: !task.isLauncher && !task.inPopup
        onEntered: event => {
            if (task.bar.dragSource || event.formats.indexOf("text/x-plasmoidservicename") >= 0) {
                event.accepted = false;
                return;
            }
            hoverTimer.restart();
        }
        onExited: hoverTimer.stop()
        onDropped: event => {
            hoverTimer.stop();
            if (event.hasUrls) {
                task.tasksModel.requestOpenUrls(task.modelIndex(), event.urls);
            }
        }
    }

    Timer {
        id: hoverTimer
        interval: 400
        onTriggered: {
            if (task.isGroup) {
                task.bar.togglePopup(task);
            } else {
                task.tasksModel.requestActivate(task.modelIndex());
            }
        }
    }

    // Tells KWin where the button is so minimize animations land on it
    Timer {
        id: geometryTimer
        interval: 200
        onTriggered: {
            if (!task.model.IsWindow || task.inPopup) {
                return;
            }
            const p = task.mapToGlobal(0, 0);
            task.tasksModel.requestPublishDelegateGeometry(task.modelIndex(), Qt.rect(p.x, p.y, task.width, task.height), task);
        }
    }
    onXChanged: geometryTimer.restart()
    onWidthChanged: geometryTimer.restart()
    onHeightChanged: geometryTimer.restart()
    Component.onCompleted: geometryTimer.restart()
}
