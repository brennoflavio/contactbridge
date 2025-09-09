/*
 * Copyright (C) 2025  Brenno Flávio de Almeida
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * calpacontactbridgel is distributed in the hope that it will be useful,
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
    id: card

    property string albumName: ""
    property string thumbnailSource: ""
    property string icon: ""
    property int itemCount: 0
    property string description: ""
    property alias backgroundColor: background.color

    signal clicked

    width: parent.width
    height: units.gu(10)

    Rectangle {
        id: background
        anchors.fill: parent
        color: "transparent"
        radius: units.gu(1)

        MouseArea {
            anchors.fill: parent
            onClicked: card.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: units.gu(1)
            spacing: units.gu(2)

            Rectangle {
                id: thumbnailContainer
                width: units.gu(8)
                height: units.gu(8)
                radius: units.gu(1)
                color: theme.palette.normal.base
                clip: true
                Layout.alignment: Qt.AlignVCenter

                Image {
                    id: thumbnail
                    anchors.fill: parent
                    source: card.thumbnailSource
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== "" && card.icon === ""
                    layer.enabled: true
                    layer.effect: ShaderEffect {
                        property real radius: units.gu(1)
                        property size size: Qt.size(thumbnail.width, thumbnail.height)
                        fragmentShader: "
                            varying highp vec2 qt_TexCoord0;
                            uniform sampler2D source;
                            uniform highp float radius;
                            uniform highp vec2 size;
                            uniform lowp float qt_Opacity;
                            void main() {
                                highp vec2 tc = qt_TexCoord0 * size;
                                highp float dx = min(tc.x, size.x - tc.x);
                                highp float dy = min(tc.y, size.y - tc.y);
                                if (dx < radius && dy < radius) {
                                    highp float d = radius - distance(vec2(dx, dy), vec2(radius, radius));
                                    gl_FragColor = texture2D(source, qt_TexCoord0) * qt_Opacity * smoothstep(-1.0, 0.0, d);
                                } else {
                                    gl_FragColor = texture2D(source, qt_TexCoord0) * qt_Opacity;
                                }
                            }
                        "
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    name: card.icon !== "" ? card.icon : "stock_image"
                    width: units.gu(4)
                    height: units.gu(4)
                    color: theme.palette.normal.backgroundSecondaryText
                    visible: card.icon !== "" || thumbnail.source === ""
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: units.gu(0.5)

                Label {
                    text: card.albumName
                    fontSize: "medium"
                    color: theme.palette.normal.foregroundText
                    elide: Text.ElideRight
                    width: parent.width
                }

                Label {
                    text: card.description ? i18n.tr("%1 items • %2").arg(card.itemCount).arg(card.description) : i18n.tr("%1 items").arg(card.itemCount)
                    fontSize: "small"
                    color: theme.palette.normal.backgroundTertiaryText
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }
}
