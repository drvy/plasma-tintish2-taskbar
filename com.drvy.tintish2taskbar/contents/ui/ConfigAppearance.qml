/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls

KCM.SimpleKCM {
    property alias cfg_styleSource: style.currentIndex
    property alias cfg_dimInactive: dim.checked
    property alias cfg_highlightStyle: highlight.currentIndex
    property alias cfg_cornerRadius: radius.value
    property alias cfg_spacing: spacing.value
    property alias cfg_colorBlock: block.color
    property alias cfg_colorBlockActive: blockActive.color
    property alias cfg_colorTaskHover: hover.color
    property alias cfg_colorTaskActive: active.color
    property alias cfg_colorTaskAttention: attention.color
    property alias cfg_colorLabel: label.color
    property alias cfg_colorLabelActive: labelActive.color

    readonly property bool custom: style.currentIndex === 1

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: style
            Kirigami.FormData.label: i18n("Style:")
            model: [i18n("Plasma theme"), i18n("Custom colors")]
        }
        QQC2.CheckBox {
            id: dim
            Kirigami.FormData.label: i18n("Inactive tasks:")
            text: i18n("Dim the icon (the active one is shown at full brightness)")
        }
        QQC2.ComboBox {
            id: highlight
            Kirigami.FormData.label: i18n("Active task:")
            model: [i18n("Icon brightness only"), i18n("Icon brightness and background box")]
        }
        QQC2.SpinBox {
            id: spacing
            Kirigami.FormData.label: i18n("Space between tasks:")
            from: 0
            to: 32
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: radius
            Kirigami.FormData.label: i18n("Corner radius:")
            enabled: custom
            from: 0
            to: 16
        }
        KQuickControls.ColorButton {
            id: block
            Kirigami.FormData.label: i18n("Desktop block:")
            enabled: custom
            showAlphaChannel: true
        }
        KQuickControls.ColorButton {
            id: blockActive
            Kirigami.FormData.label: i18n("Current desktop block:")
            enabled: custom
            showAlphaChannel: true
        }
        KQuickControls.ColorButton {
            id: hover
            Kirigami.FormData.label: i18n("Task under the pointer:")
            enabled: custom
            showAlphaChannel: true
        }
        KQuickControls.ColorButton {
            id: active
            Kirigami.FormData.label: i18n("Active task:")
            enabled: custom
            showAlphaChannel: true
        }
        KQuickControls.ColorButton {
            id: attention
            Kirigami.FormData.label: i18n("Task needing attention:")
            enabled: custom
            showAlphaChannel: true
        }
        KQuickControls.ColorButton {
            id: label
            Kirigami.FormData.label: i18n("Text:")
            enabled: custom
            showAlphaChannel: true
        }
        KQuickControls.ColorButton {
            id: labelActive
            Kirigami.FormData.label: i18n("Text of the active task or desktop:")
            enabled: custom
            showAlphaChannel: true
        }
    }
}
