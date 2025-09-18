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
 * \brief IconButton - A circular button component with icon and optional text label
 *
 * IconButton provides a touch-friendly circular button with an icon and optional
 * text label below. It features visual feedback on press with a subtle background
 * color change animation.
 *
 * The component automatically adjusts its height based on whether a text label
 * is provided. When text is present, the icon is positioned at the top with
 * the label below. Without text, the icon is centered in the button.
 *
 * Example usage with icon only:
 * \qml
 * IconButton {
 *     iconName: "add"
 *     onClicked: console.log("Add button clicked")
 * }
 * \endqml
 *
 * Example usage with icon and text:
 * \qml
 * IconButton {
 *     iconName: "edit"
 *     text: "Edit"
 *     onClicked: pageStack.push(editPage)
 * }
 * \endqml
 *
 * Properties:
 * - iconName (string): The name of the icon to display (default: "settings")
 * - text (string): Optional text label to display below the icon (default: "")
 *
 * Signals:
 * - clicked(): Emitted when the button is pressed
 */
Item {
    id: iconButton

    property string iconName: "settings"
    property string text: ""

    signal clicked

    width: units.gu(6)
    height: text ? units.gu(7) : units.gu(4)

    Rectangle {
        id: background
        anchors.centerIn: parent
        width: units.gu(4)
        height: units.gu(4)
        radius: width / 2
        color: "transparent"

        states: State {
            name: "pressed"
            when: mouseArea.pressed
            PropertyChanges {
                target: background
                color: Qt.rgba(0, 0, 0, 0.1)
            }
        }

        transitions: Transition {
            ColorAnimation {
                duration: 100
            }
        }
    }

    Icon {
        id: icon
        anchors.centerIn: text ? undefined : parent
        anchors.horizontalCenter: text ? parent.horizontalCenter : undefined
        anchors.top: text ? parent.top : undefined
        anchors.topMargin: text ? units.gu(0.75) : 0
        name: iconButton.iconName
        width: units.gu(2.5)
        height: units.gu(2.5)
        color: theme.palette.normal.backgroundText
    }

    Label {
        id: label
        visible: text !== ""
        text: iconButton.text
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: units.gu(0.5)
        fontSize: "x-small"
        color: theme.palette.normal.backgroundText
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: iconButton.clicked()
    }
}
