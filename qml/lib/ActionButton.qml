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
import QtQuick.Layouts 1.3

Rectangle {
    id: actionButton

    property string text: ""
    property string iconName: "add"
    property alias backgroundColor: actionButton.color
    property alias textColor: buttonText.color
    property alias iconColor: buttonIcon.color

    signal clicked

    width: Math.min(parent.width - units.gu(4), units.gu(30))
    height: units.gu(6)
    color: theme.palette.normal.positive
    radius: units.gu(3)

    MouseArea {
        anchors.fill: parent
        onClicked: actionButton.clicked()
        onPressed: actionButton.opacity = 0.8
        onReleased: actionButton.opacity = 1.0
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
