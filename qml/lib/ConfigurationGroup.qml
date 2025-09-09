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
    id: configurationGroup

    property string title: ""
    property alias children: contentColumn.children
    default property alias content: contentColumn.data

    width: parent.width
    height: headerItem.height + contentColumn.height + units.gu(3)

    Item {
        id: headerItem
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: units.gu(2)
        }
        height: titleLabel.height + units.gu(2)

        Label {
            id: titleLabel
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            text: configurationGroup.title
            fontSize: "medium"
            font.weight: Font.DemiBold
            color: theme.palette.normal.backgroundSecondaryText
        }
    }

    Column {
        id: contentColumn
        anchors {
            top: headerItem.bottom
            left: parent.left
            right: parent.right
        }
        spacing: units.gu(0)
    }
}
