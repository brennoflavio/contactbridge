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
    id: toggleOption

    property string title: ""
    property string subtitle: ""
    property bool checked: false
    property alias enabled: toggle.enabled

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
