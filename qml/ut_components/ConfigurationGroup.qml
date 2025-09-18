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

/*!
 * \brief ConfigurationGroup - A titled container for related configuration controls
 *
 * ConfigurationGroup presents a section header followed by any number of nested
 * form elements or settings, keeping related options visually grouped together.
 * The component handles spacing and layout so consumers only need to provide the
 * child controls, typically other components from this library.
 * This component is meant to be used with ToggleOption, InputField, and NumberOption that
 * are in this folder. Here is a brief explanation of each:
 * - ToggleOption (title str, subtitle str, checked bool, enabled bool): A switch control for enabling/disabling a setting.
 * - InputField (title str, placeholder str, validationRegex str, text str, required bool): A text input field for user input.
 * - NumberOption (title str, subtitle str, value int, minimumValue int, maximumValue: int, enabled bool):: A numeric input field with range constraints.
 *
 * Example usage with ToggleOption:
 * \qml
 * ConfigurationGroup {
 *     title: "Appearance"
 *     ToggleOption {
 *         title: "Dark Mode"
 *         checked: true
 *         onCheckedChanged: console.log("Dark mode:", checked)
 *     }
 * }
 * \endqml
 *
 * Example usage with InputField:
 * \qml
 * ConfigurationGroup {
 *     title: "User Profile"
 *     InputField {
 *         title: "Username"
 *         placeholder: "Enter username"
 *     }
 *     InputField {
 *         title: "Email"
 *         placeholder: "user@example.com"
 *         inputType: Qt.ImhEmailCharactersOnly
 *     }
 * }
 * \endqml
 *
 * Example usage with NumberOption:
 * \qml
 * ConfigurationGroup {
 *     title: "Display Settings"
 *     NumberOption {
 *         title: "Font Size"
 *         value: 14
 *         minimumValue: 8
 *         maximumValue: 32
 *         suffix: "pt"
 *     }
 *     NumberOption {
 *         title: "Screen Timeout"
 *         value: 30
 *         minimumValue: 10
 *         maximumValue: 300
 *         suffix: " seconds"
 *     }
 * }
 * \endqml
 *
 * Example with mixed control types:
 * \qml
 * ConfigurationGroup {
 *     title: "Network Settings"
 *     ToggleOption {
 *         title: "Wi-Fi"
 *         checked: true
 *     }
 *     InputField {
 *         title: "Proxy Server"
 *         placeholder: "proxy.example.com:8080"
 *     }
 *     NumberOption {
 *         title: "Connection Timeout"
 *         value: 30
 *         minimumValue: 5        // IMPORTANT: Use minimumValue, not minValue
 *         maximumValue: 120      // IMPORTANT: Use maximumValue, not maxValue
 *         suffix: " sec"
 *     }
 * }
 * \endqml
 */
Item {
    id: configurationGroup

    /*! Title text shown in the section header */
    property string title: ""
    /*! Direct access to child items inside the group (useful for iteration) */
    property alias children: contentColumn.children
    /*! Default property: place controls inside the group without extra wrappers */
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
