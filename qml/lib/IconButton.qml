/*
 * Copyright (C) 2025  Brenno Flávio de Almeida
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * contactbridge is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
import QtQuick 2.7
import Lomiri.Components 1.3

Item {
    id: iconButton

    property string iconName: "settings"
    property alias iconColor: icon.color
    property real iconSize: units.gu(2.5)
    property string tooltipText: ""

    signal clicked

    width: units.gu(4)
    height: units.gu(4)

    Rectangle {
        id: background
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
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
        anchors.centerIn: parent
        name: iconButton.iconName
        width: iconButton.iconSize
        height: iconButton.iconSize
        color: theme.palette.normal.backgroundText
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: iconButton.clicked()
    }
}
