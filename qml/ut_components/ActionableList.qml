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

/*!
 * \brief ActionableList - A searchable list component with customizable item actions
 *
 * ActionableList provides a flexible list view with optional search functionality
 * and configurable action buttons for each item. It supports both global actions
 * (applied to all items) and per-item custom actions.
 *
 * Features:
 * - Optional search bar with configurable search fields
 * - Item display with title, subtitle, and optional icon
 * - Customizable action buttons per item
 * - Empty state message
 * - Click handling for items and actions
 *
 * Example usage with basic items:
 * \qml
 * ActionableList {
 *     items: [
 *         { title: "Item 1", subtitle: "Description", icon: "document" },
 *         { title: "Item 2", subtitle: "Details" }
 *     ]
 *     showSearchBar: true
 *     searchPlaceholder: "Search items..."
 *     onItemClicked: console.log("Clicked:", item.title)
 * }
 * \endqml
 *
 * Example usage with actions:
 * \qml
 * ActionableList {
 *     items: myDataModel
 *     itemActions: [
 *         { id: "edit", iconName: "edit", text: "Edit" },
 *         { id: "delete", iconName: "delete", text: "Delete" }
 *     ]
 *     onActionTriggered: {
 *         if (actionId === "edit") editItem(item)
 *         else if (actionId === "delete") deleteItem(item)
 *     }
 * }
 * \endqml
 *
 * Example with per-item custom actions:
 * \qml
 * ActionableList {
 *     items: [
 *         {
 *             title: "Locked Item",
 *             customActions: [
 *                 { id: "unlock", iconName: "lock-broken", text: "Unlock" }
 *             ]
 *         },
 *         {
 *             title: "Regular Item",
 *             // Uses global itemActions if no customActions defined
 *         }
 *     ]
 * }
 * \endqml
 */
Column {
    id: actionableList

    /*!
     * Array of items to display in the list.
     * Each item should have at minimum a 'title' property.
     * Optional properties: subtitle, icon, customActions, actionData
     */
    property var items: []

    /*! Whether to show the search bar above the list */
    property bool showSearchBar: false

    /*! Placeholder text for the search input field */
    property string searchPlaceholder: i18n.tr("Search")

    /*! Message displayed when the list is empty or no items match the search */
    property string emptyMessage: i18n.tr("No items")

    /*!
     * Array of property names to search within.
     * Default: ["title"] - searches only in the title field
     * Can be extended to search multiple fields: ["title", "subtitle", "description"]
     */
    property var searchFields: ["title"]

    /*!
     * Global actions applied to all items (unless overridden by item.customActions).
     * Each action object should have: id, iconName, text (optional), enabled (optional), visible (optional)
     */
    property var itemActions: []

    /*! Property name used as unique identifier for items (used internally) */
    property string idField: "id"

    /*! Emitted when a list item is clicked (only if the item has no actions) */
    signal itemClicked(var item)

    /*!
     * Emitted when an action button is triggered.
     * @param actionId The id of the triggered action
     * @param item The complete item object
     * @param actionData Optional data from item.actionData property
     */
    signal actionTriggered(string actionId, var item, var actionData)

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
                placeholderText: actionableList.searchPlaceholder
            }
        }
    }

    ListView {
        id: listView
        width: parent.width
        height: parent.height - (showSearchBar ? units.gu(6) : 0)
        spacing: 0
        clip: true

        model: {
            var filtered = items;
            if (showSearchBar && searchInput.text.length > 0) {
                var searchText = searchInput.text.toLowerCase();
                filtered = filtered.filter(function (item) {
                        for (var i = 0; i < searchFields.length; i++) {
                            var fieldName = searchFields[i];
                            if (item.hasOwnProperty(fieldName)) {
                                var fieldValue = String(item[fieldName] || "").toLowerCase();
                                if (fieldValue.indexOf(searchText) !== -1) {
                                    return true;
                                }
                            }
                        }
                        return false;
                    });
            }
            return filtered;
        }

        delegate: Item {
            id: listItemDelegate

            property var itemData: modelData
            property string title: modelData.title || ""
            property string subtitle: modelData.subtitle || ""
            property string leadingIcon: modelData.icon || ""
            property var actions: modelData.customActions && modelData.customActions.length > 0 ? modelData.customActions : actionableList.itemActions

            width: parent.width
            height: units.gu(7)

            Rectangle {
                anchors.fill: parent
                color: itemMouseArea.pressed ? theme.palette.highlighted.background : "transparent"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: units.gu(1.5)
                        rightMargin: units.gu(0.5)
                    }
                    spacing: units.gu(1)

                    Loader {
                        active: listItemDelegate.leadingIcon !== ""
                        Layout.preferredWidth: units.gu(3)
                        Layout.preferredHeight: units.gu(3)
                        Layout.alignment: Qt.AlignVCenter

                        sourceComponent: Icon {
                            name: listItemDelegate.leadingIcon
                            width: units.gu(3)
                            height: units.gu(3)
                            color: theme.palette.normal.foregroundText
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: units.gu(0.1)

                        Label {
                            text: listItemDelegate.title
                            fontSize: "medium"
                            color: theme.palette.normal.foregroundText
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Loader {
                            active: listItemDelegate.subtitle !== ""
                            width: parent.width
                            sourceComponent: Label {
                                text: listItemDelegate.subtitle
                                fontSize: "small"
                                color: theme.palette.normal.backgroundSecondaryText
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }

                    Row {
                        id: actionsRow
                        spacing: units.gu(0.2)
                        Layout.alignment: Qt.AlignVCenter

                        Repeater {
                            model: {
                                var visibleActions = [];
                                for (var i = 0; i < listItemDelegate.actions.length; i++) {
                                    var action = listItemDelegate.actions[i];
                                    if (action.visible === undefined || action.visible === true) {
                                        visibleActions.push(action);
                                    }
                                }
                                return visibleActions;
                            }

                            delegate: IconButton {
                                iconName: modelData.iconName || "settings"
                                text: modelData.text || ""
                                enabled: modelData.enabled === undefined || modelData.enabled === true
                                onClicked: {
                                    if (modelData.handler && typeof modelData.handler === "function") {
                                        modelData.handler(listItemDelegate.itemData, modelData.id);
                                    } else {
                                        actionableList.actionTriggered(modelData.id, listItemDelegate.itemData, listItemDelegate.itemData.actionData || {});
                                    }
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    enabled: actionsRow.children.length === 0
                    onClicked: actionableList.itemClicked(listItemDelegate.itemData)
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: units.gu(1.5)
                    }
                    height: units.dp(1)
                    color: theme.palette.normal.base
                }
            }
        }

        Label {
            visible: listView.model.length === 0
            anchors.centerIn: parent
            text: actionableList.emptyMessage
            fontSize: "large"
            color: theme.palette.normal.backgroundSecondaryText
        }
    }
}
