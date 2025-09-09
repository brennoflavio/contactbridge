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

Column {
    id: gallery

    property string month: ""
    property var days: []

    signal itemClicked(var imageData)

    width: parent.width
    spacing: 0

    Item {
        width: parent.width
        height: monthLabel.height + units.gu(3)
        visible: gallery.month !== ""

        Label {
            id: monthLabel
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                top: parent.top
                topMargin: units.gu(2)
            }
            text: gallery.month
            fontSize: "x-large"
            color: theme.palette.normal.baseText
        }
    }

    Repeater {
        model: gallery.days

        Column {
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: dateLabel.height + units.gu(2)
                visible: modelData.date !== ""

                Label {
                    id: dateLabel
                    anchors {
                        left: parent.left
                        leftMargin: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    text: modelData.date
                    fontSize: "medium"
                    color: theme.palette.normal.baseText
                }
            }

            Grid {
                width: parent.width
                columns: 3
                spacing: units.gu(0.2)

                Repeater {
                    model: modelData.images

                    GalleryItem {
                        filePath: modelData.filePath || ""
                        duration: modelData.duration || ""
                        width: (gallery.width - units.gu(0.4)) / 3
                        height: width

                        onClicked: gallery.itemClicked(modelData)
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: units.gu(2)
                color: "transparent"
            }
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: i18n.tr("No images to display")
        fontSize: "large"
        color: theme.palette.disabled.baseText
        visible: days.length === 0
    }
}
