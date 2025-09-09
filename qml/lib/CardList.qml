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

ListView {
    id: cardList

    property var albums: []

    signal albumClicked(var albumId, string albumName)

    width: parent.width
    spacing: units.gu(1)
    clip: true

    model: albums

    delegate: Card {
        id: card
        width: parent.width - units.gu(4)
        anchors.horizontalCenter: parent.horizontalCenter
        albumName: modelData.name || ""
        thumbnailSource: modelData.thumbnailUrl || ""
        icon: modelData.icon || ""
        itemCount: modelData.itemCount || 0
        description: modelData.description || ""

        onClicked: {
            cardList.albumClicked(modelData.id, modelData.name);
        }
    }

    Label {
        visible: albums.length === 0
        anchors.centerIn: parent
        text: i18n.tr("No servers")
        fontSize: "large"
        color: theme.palette.normal.backgroundSecondaryText
    }
}
