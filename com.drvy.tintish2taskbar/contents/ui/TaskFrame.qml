/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import org.kde.ksvg as KSvg
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

// Background of a task or block: Plasma theme ("widgets/tasks") or custom colours, per the style setting.
Item {
    id: frame

    // normal | hover | focus | attention | minimized | taskbar | taskbar-active
    property string kind: "normal"

    readonly property var cfg: Plasmoid.configuration
    readonly property bool themed: cfg.styleSource === 0
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
        visible: frame.themed
        imagePath: "widgets/tasks"
        prefix: [frame.edge + frame.kind, frame.kind]
    }

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
