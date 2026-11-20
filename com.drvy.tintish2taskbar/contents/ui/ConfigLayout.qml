/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_layoutMode: layoutMode.currentIndex
    property alias cfg_widthMode: widthMode.currentIndex
    property alias cfg_maxWidth: maxWidth.value
    property alias cfg_maxWidthUnit: maxUnit.currentIndex
    property alias cfg_maxPercent: maxPercent.value
    property alias cfg_showDesktopNames: showNames.checked
    property alias cfg_equalBlocks: equalBlocks.checked
    property alias cfg_hideEmptyDesktops: hideEmpty.checked
    property alias cfg_showDividers: dividers.checked
    property alias cfg_showLabels: showLabels.checked
    property alias cfg_labelWidth: labelWidth.value
    property alias cfg_iconSize: iconSize.value
    property alias cfg_showLaunchers: showLaunchers.checked
    property alias cfg_launchersAtEnd: launchersAtEnd.checked

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: widthMode
            Kirigami.FormData.label: i18n("Panel width:")
            model: [i18n("Fill the free space"), i18n("Limit to a maximum")]
        }
        QQC2.ComboBox {
            id: maxUnit
            Kirigami.FormData.label: i18n("Maximum is in:")
            enabled: widthMode.currentIndex === 1
            model: [i18n("Pixels"), i18n("Percent of the screen width")]
        }
        QQC2.SpinBox {
            id: maxWidth
            visible: maxUnit.currentIndex === 0
            Kirigami.FormData.label: i18n("Maximum width (px):")
            enabled: widthMode.currentIndex === 1
            from: 200
            to: 16000
            stepSize: 50
        }
        QQC2.SpinBox {
            id: maxPercent
            visible: maxUnit.currentIndex === 1
            Kirigami.FormData.label: i18n("Maximum width (%):")
            enabled: widthMode.currentIndex === 1
            from: 10
            to: 100
            stepSize: 5
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            id: layoutMode
            Kirigami.FormData.label: i18n("Virtual desktops:")
            model: [i18n("One block per desktop"), i18n("Current desktop only"), i18n("All windows together")]
        }
        QQC2.CheckBox {
            id: showNames
            enabled: layoutMode.currentIndex === 0
            text: i18n("Show the desktop name in each block")
        }
        QQC2.CheckBox {
            id: equalBlocks
            enabled: layoutMode.currentIndex === 0
            text: i18n("Blocks share the width equally")
        }
        QQC2.CheckBox {
            id: dividers
            text: i18n("Draw a thin divider between blocks")
        }
        QQC2.CheckBox {
            id: hideEmpty
            enabled: layoutMode.currentIndex === 0
            text: i18n("Hide desktops with no windows")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: showLabels
            Kirigami.FormData.label: i18n("Tasks:")
            text: i18n("Show window titles")
        }
        QQC2.SpinBox {
            id: labelWidth
            Kirigami.FormData.label: i18n("Title width:")
            enabled: showLabels.checked
            from: 60
            to: 400
            stepSize: 10
        }
        QQC2.SpinBox {
            id: iconSize
            Kirigami.FormData.label: i18n("Icon size (0 = fit the panel):")
            from: 0
            to: 128
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: showLaunchers
            Kirigami.FormData.label: i18n("Pinned launchers:")
            text: i18n("Show launchers")
        }
        QQC2.CheckBox {
            id: launchersAtEnd
            enabled: showLaunchers.checked
            text: i18n("Place them after the desktops")
        }
    }
}
