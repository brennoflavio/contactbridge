/*
 * Copyright (C) 2025  Brenno Flávio de Almeida
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * ut-components is distributed in the hope that it will be useful,
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
import QtGraphicalEffects 1.0

/*!
 * \brief CardList - A filterable list view component that displays items as cards
 *
 * CardList provides a scrollable list of cards with optional search functionality.
 * Each item in the list is rendered as a card with title, subtitle, icon, and/or thumbnail.
 * The component handles empty states and provides click feedback for each card.
 *
 * Features:
 * - Automatic card rendering from data array
 * - Optional search bar with real-time filtering
 * - Empty state message when no items are present
 * - Click signal for handling card selection
 * - Thumbnail image or icon display for each card
 *
 * Example usage without search:
 * \qml
 * CardList {
 *     height: units.gu(30)
 *     items: [
 *         { title: "Item 1", subtitle: "Description 1", icon: "add" },
 *         { title: "Item 2", subtitle: "Description 2", thumbnailSource: "image.jpg" }
 *     ]
 *     emptyMessage: i18n.tr("No data")
 *     onItemClicked: console.log("Selected:", item.title)
 * }
 * \endqml
 *
 * Example usage with search:
 * \qml
 * CardList {
 *     height: units.gu(40)
 *     showSearchBar: true
 *     searchPlaceholder: i18n.tr("Search items...")
 *     items: myDataModel
 *     onItemClicked: pageStack.push(detailPage, { data: item })
 * }
 * \endqml
 *
 * Properties:
 * - items (array): Array of objects containing card data (title, subtitle, icon, thumbnailSource)
 * - emptyMessage (string): Message displayed when items array is empty (default: "No items")
 * - showSearchBar (bool): Whether to show the search bar (default: false)
 * - searchPlaceholder (string): Placeholder text for search field (default: "Search")
 *
 * Signals:
 * - itemClicked(var item): Emitted when a card is clicked, passes the clicked item object
 */
Column {
    id: cardList

    property var items: []
    property string emptyMessage: i18n.tr("No items")
    property bool showSearchBar: false
    property string searchPlaceholder: i18n.tr("Search")

    signal itemClicked(var item)

    width: parent.width
    spacing: units.gu(1)

    Item {
        visible: showSearchBar
        width: parent.width
        height: visible ? units.gu(5) : 0

        Row {
            anchors {
                fill: parent
                leftMargin: units.gu(2)
                rightMargin: units.gu(2)
            }
            spacing: units.gu(1)

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "find"
                height: units.gu(2)
                width: units.gu(2)
                color: theme.palette.normal.backgroundSecondaryText
            }

            TextField {
                id: searchInput
                width: parent.width - units.gu(5)
                anchors.verticalCenter: parent.verticalCenter
                placeholderText: cardList.searchPlaceholder
            }
        }
    }

    ListView {
        id: listView
        width: parent.width
        height: parent.height - (showSearchBar ? units.gu(6) : 0)
        spacing: units.gu(1)
        clip: true

        model: {
            var filtered = items;
            if (showSearchBar && searchInput.text.length > 0) {
                filtered = filtered.filter(function (item) {
                        var searchValue = item.title || "";
                        return searchValue.toLowerCase().indexOf(searchInput.text.toLowerCase()) !== -1;
                    });
            }
            return filtered;
        }

        delegate: Item {
            id: cardDelegate
            width: parent.width - units.gu(4)
            height: units.gu(10)
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                id: background
                anchors.fill: parent
                color: "transparent"
                radius: units.gu(1)

                MouseArea {
                    anchors.fill: parent
                    onClicked: cardList.itemClicked(modelData)
                    onPressed: background.opacity = 0.7
                    onReleased: background.opacity = 1.0
                    onCanceled: background.opacity = 1.0
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
                        Layout.alignment: Qt.AlignVCenter

                        Image {
                            id: thumbnail
                            anchors.fill: parent
                            source: modelData.thumbnailSource || ""
                            fillMode: Image.PreserveAspectCrop
                            visible: false
                        }

                        Rectangle {
                            id: mask
                            anchors.fill: parent
                            radius: units.gu(1)
                            visible: false
                        }

                        OpacityMask {
                            anchors.fill: parent
                            source: thumbnail
                            maskSource: mask
                            visible: (!!modelData.thumbnailSource) && !modelData.icon
                        }

                        Icon {
                            anchors.centerIn: parent
                            name: modelData.icon || "dialog-question-symbolic"
                            width: units.gu(4)
                            height: units.gu(4)
                            color: theme.palette.normal.backgroundSecondaryText
                            visible: (!!modelData.icon) || (!modelData.thumbnailSource && !modelData.icon)
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: units.gu(0.5)

                        Label {
                            text: modelData.title || ""
                            fontSize: "medium"
                            color: theme.palette.normal.foregroundText
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Label {
                            text: modelData.subtitle || ""
                            fontSize: "small"
                            color: theme.palette.normal.backgroundTertiaryText
                            elide: Text.ElideRight
                            width: parent.width
                            visible: text !== ""
                        }
                    }
                }
            }
        }

        Label {
            visible: listView.model.length === 0
            anchors.centerIn: parent
            text: cardList.emptyMessage
            fontSize: "large"
            color: theme.palette.normal.backgroundSecondaryText
        }
    }
}
