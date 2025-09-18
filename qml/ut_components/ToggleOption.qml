/*
 * Copyright (C) 2025  Brenno Flávio de Almeida
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ut-components is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.7
import Lomiri.Components 1.3

/*!
 * \brief ToggleOption - A list item component with a toggle switch for settings
 *
 * ToggleOption provides a consistent UI element for boolean settings in Ubuntu Touch applications.
 * It displays a title and optional subtitle on the left side, with a Switch control on the right.
 * The component includes a bottom separator line for use in lists.
 *
 * Features:
 * - Title and optional subtitle text
 * - Toggle switch control
 * - Enable/disable state
 * - Signal emission on state change
 * - Automatic text ellipsis for long content
 * - Bottom separator for list layouts
 *
 * Example usage for a simple toggle:
 * \qml
 * ToggleOption {
 *     title: "Enable Notifications"
 *     checked: true
 *     onToggled: console.log("Notifications:", checked)
 * }
 * \endqml
 *
 * Example usage with subtitle:
 * \qml
 * ToggleOption {
 *     title: "Dark Mode"
 *     subtitle: "Use dark theme throughout the application"
 *     checked: false
 *     onToggled: settings.darkMode = checked
 * }
 * \endqml
 *
 * Example usage in a settings list:
 * \qml
 * Column {
 *     ToggleOption {
 *         title: "Auto-sync"
 *         subtitle: "Sync data automatically"
 *         checked: settings.autoSync
 *         onToggled: settings.autoSync = checked
 *     }
 *     ToggleOption {
 *         title: "Location Services"
 *         subtitle: "Allow apps to access your location"
 *         checked: settings.locationEnabled
 *         enabled: hasLocationPermission
 *         onToggled: settings.locationEnabled = checked
 *     }
 * }
 * \endqml
 */
Item {
    id: toggleOption

    /*! The main text label displayed for this toggle option */
    property string title: ""

    /*! Optional secondary text displayed below the title. Hidden when empty */
    property string subtitle: ""

    /*! The current state of the toggle switch (true = on, false = off) */
    property bool checked: false

    /*! Whether the toggle switch is interactive. When false, the switch appears grayed out */
    property alias enabled: toggle.enabled

    /*!
     * Emitted when the toggle switch state changes
     * \param checked The new state of the toggle (true = on, false = off)
     */
    signal toggled(bool checked)

    height: units.gu(8)
    width: parent.width

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Column {
        anchors {
            left: parent.left
            right: toggle.left
            verticalCenter: parent.verticalCenter
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
        spacing: units.gu(0.5)

        Label {
            id: titleLabel
            text: toggleOption.title
            fontSize: "medium"
            color: theme.palette.normal.foregroundText
            width: parent.width
            elide: Text.ElideRight
        }

        Label {
            id: subtitleLabel
            text: toggleOption.subtitle
            fontSize: "small"
            color: theme.palette.normal.backgroundSecondaryText
            width: parent.width
            elide: Text.ElideRight
            visible: text !== ""
        }
    }

    Switch {
        id: toggle
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: units.gu(2)
        }
        checked: toggleOption.checked
        onClicked: {
            toggleOption.checked = checked;
            toggleOption.toggled(checked);
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: units.gu(2)
        }
        height: units.dp(1)
        color: theme.palette.normal.base
    }
}
