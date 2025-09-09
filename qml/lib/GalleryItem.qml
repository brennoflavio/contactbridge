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
    id: galleryItem

    property string filePath: ""
    property string duration: ""

    signal clicked

    Rectangle {
        anchors.fill: parent
        color: theme.palette.normal.base

        Rectangle {
            anchors.fill: parent
            color: theme.palette.normal.backgroundSecondaryText

            Icon {
                anchors.centerIn: parent
                width: units.gu(4)
                height: units.gu(4)
                name: "stock_image"
                color: theme.palette.disabled.baseText
            }
        }

        Image {
            id: image
            anchors.fill: parent
            source: galleryItem.filePath !== "" ? "file://" + galleryItem.filePath : ""
            fillMode: Image.PreserveAspectCrop
            cache: true
            asynchronous: true
            visible: source !== ""
            sourceSize.width: parent.width
            sourceSize.height: parent.height
        }

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                topMargin: units.gu(0.5)
                leftMargin: units.gu(0.5)
            }
            width: durationLabel.width + units.gu(1)
            height: units.gu(2)
            radius: units.gu(0.3)
            color: Qt.rgba(0, 0, 0, 0.7)
            visible: galleryItem.duration !== ""

            Label {
                id: durationLabel
                anchors.centerIn: parent
                text: galleryItem.duration
                fontSize: "x-small"
                color: "white"
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: galleryItem.clicked()
        }
    }
}
