/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_showOnlyCurrentScreen: onlyScreen.checked
    property alias cfg_showOnlyCurrentActivity: onlyActivity.checked
    property alias cfg_showOnlyMinimized: onlyMinimized.checked
    property alias cfg_groupingStrategy: grouping.currentIndex
    property alias cfg_groupClickAction: groupClick.currentIndex
    property alias cfg_sortingStrategy: sorting.currentIndex
    property alias cfg_minimizeActiveOnClick: minimizeActive.checked
    property alias cfg_middleClickAction: middleClick.currentIndex
    property alias cfg_wheelAction: wheel.currentIndex
    property alias cfg_showToolTips: toolTips.checked

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: onlyScreen
            Kirigami.FormData.label: i18n("Show only tasks:")
            text: i18n("From the current screen")
        }
        QQC2.CheckBox {
            id: onlyActivity
            text: i18n("From the current activity")
        }
        QQC2.CheckBox {
            id: onlyMinimized
            text: i18n("That are minimized")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            id: grouping
            Kirigami.FormData.label: i18n("Group windows:")
            model: [i18n("Never"), i18n("By application")]
        }
        QQC2.ComboBox {
            id: groupClick
            Kirigami.FormData.label: i18n("Clicking a group:")
            enabled: grouping.currentIndex !== 0
            model: [i18n("Lists its windows"), i18n("Cycles through its windows")]
        }
        QQC2.ComboBox {
            id: sorting
            Kirigami.FormData.label: i18n("Sort tasks:")
            model: [i18n("Do not sort"), i18n("Manually"), i18n("Alphabetically")]
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: minimizeActive
            Kirigami.FormData.label: i18n("Clicking a task:")
            text: i18n("Minimizes it when it is already active")
        }
        QQC2.ComboBox {
            id: middleClick
            Kirigami.FormData.label: i18n("Middle click:")
            model: [i18n("Does nothing"), i18n("Closes the window"), i18n("Opens a new instance"), i18n("Minimizes or restores")]
        }
        QQC2.ComboBox {
            id: wheel
            Kirigami.FormData.label: i18n("Mouse wheel:")
            model: [i18n("Does nothing"), i18n("Cycles through tasks"), i18n("Switches desktop")]
        }
        QQC2.CheckBox {
            id: toolTips
            Kirigami.FormData.label: i18n("Tooltips:")
            text: i18n("Show tooltips")
        }
    }
}
