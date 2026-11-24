/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.ksvg as KSvg
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// Background of a task or block: Plasma theme ("widgets/tasks") or custom colours, per the style setting.
// The theme's task frames only exist for horizontal panels (their indicator bar is at the bottom), so in a
// vertical panel the task states are drawn here instead, with an indicator on the panel's edge side.
Item {
    id: frame

    // normal | hover | focus | attention | minimized | taskbar | taskbar-active
    property string kind: "normal"
    // Task state, used for the vertical-panel indicator; blocks and launchers are not running windows
    property bool running: false
    property bool active: false
    property bool minimized: false

    readonly property var cfg: Plasmoid.configuration
    readonly property bool themed: cfg.styleSource === 0
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool taskKind: kind !== "taskbar" && kind !== "taskbar-active"
    // Vertical panel, theme style, a task: the theme frame is replaced by the one below
    readonly property bool ownFrame: themed && vertical && taskKind
    readonly property bool edgeRight: Plasmoid.location === PlasmaCore.Types.RightEdge
    readonly property string edge: {
        switch (Plasmoid.location) {
        case PlasmaCore.Types.LeftEdge: return "west-";
        case PlasmaCore.Types.TopEdge: return "north-";
        case PlasmaCore.Types.RightEdge: return "east-";
        default: return "south-";
        }
    }

    KSvg.FrameSvgItem {
        anchors.fill: parent
        visible: frame.themed && !frame.ownFrame
        imagePath: "widgets/tasks"
        prefix: [frame.edge + frame.kind, frame.kind]
    }

    // Theme-style frame for a task in a vertical panel
    Rectangle {
        anchors.fill: parent
        visible: frame.ownFrame
        radius: frame.cfg.cornerRadius
        color: {
            switch (frame.kind) {
            case "hover": return Qt.alpha(Kirigami.Theme.textColor, 0.12);
            case "focus": return Qt.alpha(Kirigami.Theme.highlightColor, 0.3);
            case "attention": return Qt.alpha(Kirigami.Theme.negativeTextColor, 0.25);
            default: return "transparent";
            }
        }
        border.width: frame.kind === "attention" ? 1 : 0
        border.color: Kirigami.Theme.negativeTextColor
    }

    // Short, thin mark on the panel's edge side: running window, brighter when active, faint when minimized
    Rectangle {
        visible: frame.ownFrame && frame.running
        anchors {
            verticalCenter: parent.verticalCenter
            left: frame.edgeRight ? undefined : parent.left
            right: frame.edgeRight ? parent.right : undefined
        }
        width: 2
        height: Math.round(parent.height * 0.4)
        radius: 1
        color: Kirigami.Theme.textColor
        opacity: frame.minimized ? 0.2 : (frame.active ? 0.7 : 0.35)
    }

    // Custom colours
    Rectangle {
        anchors.fill: parent
        visible: !frame.themed
        radius: frame.cfg.cornerRadius
        color: {
            switch (frame.kind) {
            case "hover": return frame.cfg.colorTaskHover;
            case "focus": return frame.cfg.colorTaskActive;
            case "attention": return frame.cfg.colorTaskAttention;
            case "taskbar": return frame.cfg.colorBlock;
            case "taskbar-active": return frame.cfg.colorBlockActive;
            default: return "transparent";
            }
        }
        border.width: frame.kind === "attention" ? 1 : 0
        border.color: Qt.rgba(frame.cfg.colorTaskAttention.r, frame.cfg.colorTaskAttention.g,
                              frame.cfg.colorTaskAttention.b, Math.min(1, frame.cfg.colorTaskAttention.a * 2))
    }
}
