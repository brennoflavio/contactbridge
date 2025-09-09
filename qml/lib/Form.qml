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

Item {
    id: form

    property alias fields: fieldsContainer.children
    property string buttonText: i18n.tr("Submit")
    property string buttonIconName: ""

    signal submitted

    width: parent.width
    height: childrenRect.height

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: units.gu(2)
        }
        spacing: units.gu(1)

        Item {
            id: fieldsContainer
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height

            ColumnLayout {
                anchors.fill: parent
                spacing: units.gu(1)
            }
        }

        ActionButton {
            id: submitButton
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: units.gu(2)
            text: form.buttonText
            iconName: form.buttonIconName

            onClicked: {
                form.submitted();
            }
        }
    }
}
