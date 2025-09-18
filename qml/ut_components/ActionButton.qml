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
import QtQuick.Layouts 1.3

/*!
 * \brief ActionButton - A prominent button component for primary actions in Ubuntu Touch applications
 *
 * ActionButton provides a rounded, colored button with an icon and text label,
 * designed for important user actions like "Add", "Save", or "Delete".
 * The button includes visual feedback on press and supports a disabled state.
 *
 * Features:
 * - Icon and text label display
 * - Customizable colors for background, text, and icon
 * - Press animation with opacity changes
 * - Disabled state with reduced opacity
 * - Auto-sizing to parent width with maximum constraint
 *
 * Example usage for a default action:
 * \qml
 * ActionButton {
 *     text: "Add New Item"
 *     iconName: "add"
 *     onClicked: console.log("Item added")
 * }
 * \endqml
 *
 * Example usage for a destructive action:
 * \qml
 * ActionButton {
 *     text: "Delete"
 *     iconName: "delete"
 *     backgroundColor: theme.palette.normal.negative
 *     onClicked: confirmDelete()
 * }
 * \endqml
 *
 * Example usage with custom styling:
 * \qml
 * ActionButton {
 *     text: "Custom Button"
 *     iconName: "starred"
 *     backgroundColor: "#FF9800"
 *     textColor: "#000000"
 *     iconColor: "#000000"
 *     enabled: !isProcessing
 *     onClicked: doCustomAction()
 * }
 * \endqml
 */
Rectangle {
    id: actionButton

    property string text: ""
    property string iconName: "add"
    property alias backgroundColor: actionButton.color
    property alias textColor: buttonText.color
    property alias iconColor: buttonIcon.color
    property bool enabled: true

    signal clicked

    implicitWidth: units.gu(30)
    implicitHeight: units.gu(6)
    width: Math.min(parent.width - units.gu(4), units.gu(30))
    height: units.gu(6)
    color: theme.palette.normal.positive
    radius: units.gu(3)
    opacity: enabled ? 1.0 : 0.5

    MouseArea {
        anchors.fill: parent
        enabled: actionButton.enabled
        onClicked: actionButton.clicked()
        onPressed: actionButton.opacity = enabled ? 0.8 : 0.5
        onReleased: actionButton.opacity = enabled ? 1.0 : 0.5
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: units.gu(1)

        Icon {
            id: buttonIcon
            name: actionButton.iconName
            width: units.gu(2.5)
            height: units.gu(2.5)
            color: "white"
            Layout.alignment: Qt.AlignVCenter
        }

        Label {
            id: buttonText
            text: actionButton.text
            fontSize: "medium"
            font.weight: Font.Medium
            color: "white"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Behavior on opacity  {
        NumberAnimation {
            duration: 100
        }
    }
}
