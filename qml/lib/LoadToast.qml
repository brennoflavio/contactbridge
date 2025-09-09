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
    id: toast

    property bool showing: false
    property bool showSpinner: true
    property string message: ""

    visible: showing
    anchors.fill: parent
    z: 1000

    MouseArea {
        anchors.fill: parent
        enabled: toast.showing
        onClicked:
        // Block click events from going through
        {
        }
        onPressed:
        // Block press events from going through
        {
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.3
        visible: toast.showing
    }

    Rectangle {
        id: toastContainer
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, units.gu(40))
        height: contentColumn.height + units.gu(4)
        color: theme.palette.normal.background
        radius: units.gu(1)
        visible: toast.showing

        Column {
            id: contentColumn
            anchors {
                centerIn: parent
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            ActivityIndicator {
                id: spinner
                anchors.horizontalCenter: parent.horizontalCenter
                running: toast.showing && toast.showSpinner
                visible: toast.showSpinner
            }

            Label {
                id: messageLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: toast.message
                wrapMode: Text.WordWrap
                width: toastContainer.width - units.gu(4)
                horizontalAlignment: Text.AlignHCenter
                visible: toast.message !== ""
            }
        }
    }
}
