/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Lists the windows of a group; opened by clicking a grouped task.
PlasmaCore.PopupPlasmaWindow {
    id: popup

    required property Item bar
    required property var tasksModel
    required property int parentRow

    readonly property int rowHeight: Kirigami.Units.iconSizes.medium + 8
    readonly property int rowSpacing: 2

    animated: true
    width: Kirigami.Units.gridUnit * 16 + leftPadding + rightPadding
    height: Math.min(list.count * (rowHeight + rowSpacing), Kirigami.Units.gridUnit * 25) + topPadding + bottomPadding
    popupDirection: {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.TopEdge: return Qt.BottomEdge;
        case PlasmaCore.Types.LeftEdge: return Qt.RightEdge;
        case PlasmaCore.Types.RightEdge: return Qt.LeftEdge;
        default: return Qt.TopEdge;
        }
    }

    mainItem: ListView {
        id: list
        clip: true
        spacing: popup.rowSpacing
        interactive: contentHeight > height
        model: DelegateModel {
            model: popup.tasksModel
            rootIndex: popup.tasksModel.makeModelIndex(popup.parentRow)
            delegate: TaskButton {
                width: list.width
                height: popup.rowHeight
                bar: popup.bar
                tasksModel: popup.tasksModel
                inPopup: true
                parentRow: popup.parentRow
            }
        }
        onCountChanged: {
            if (count === 0) {
                popup.visible = false;
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 100
        onTriggered: {
            if (!popup.active) {
                popup.visible = false;
            }
        }
    }

    onActiveChanged: {
        if (!active) {
            closeTimer.restart();
        }
    }

    onVisibleChanged: {
        if (visible) {
            requestActivate();
        } else {
            if (bar.groupPopup === popup) {
                bar.groupPopup = null;
            }
            destroy();
        }
    }
}
