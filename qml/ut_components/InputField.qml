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
 * \brief InputField - A text input component with built-in validation and error handling
 *
 * InputField provides a comprehensive text input solution with:
 * - Title label above the input field
 * - Placeholder text support
 * - Real-time validation using regular expressions
 * - Required field validation
 * - Error message display
 * - Password and other echo modes support
 *
 * The component automatically validates input as the user types and displays
 * appropriate error messages below the field when validation fails.
 *
 * Example usage for a basic text field:
 * \qml
 * InputField {
 *     title: "Username"
 *     placeholder: "Enter your username"
 *     onTextChanged: console.log("Username:", text)
 * }
 * \endqml
 *
 * Example usage for a required email field with validation:
 * \qml
 * InputField {
 *     title: "Email Address"
 *     placeholder: "user@example.com"
 *     required: true
 *     validationRegex: "^[\\w\\.-]+@[\\w\\.-]+\\.\\w+$"
 *     errorMessage: "Please enter a valid email address"
 * }
 * \endqml
 *
 * Example usage for a password field:
 * \qml
 * InputField {
 *     title: "Password"
 *     placeholder: "Enter secure password"
 *     echoMode: TextInput.Password
 *     required: true
 * }
 * \endqml
 */
Item {
    id: inputField

    /*! The label text displayed above the input field */
    property string title: ""

    /*! Placeholder text shown when the field is empty */
    property string placeholder: ""

    /*! The current text value in the input field (read/write) */
    property alias text: textField.text

    /*!
     * The echo mode for the text field
     * Possible values: TextInput.Normal, TextInput.Password, TextInput.NoEcho, TextInput.PasswordEchoOnEdit
     */
    property alias echoMode: textField.echoMode

    /*!
     * Regular expression pattern for input validation
     * Leave empty to disable regex validation
     * Example patterns:
     * - Email: "^[\\w\\.-]+@[\\w\\.-]+\\.\\w+$"
     * - Phone: "^[+]?[0-9\\s\\-()]+$"
     * - ZIP: "^\\d{5}(-\\d{4})?$"
     */
    property string validationRegex: ""

    /*!
     * Custom error message shown when validation fails
     * For required fields, a default "This field is required" message is shown when empty
     */
    property string errorMessage: i18n.tr("Invalid input")

    /*!
     * Whether this field is required (must not be empty)
     * When true, the field will show an error if left empty after losing focus
     */
    property bool required: false

    /*! Whether the current input is valid (for form validation). Do not manipulate this variable directly, use validationRegex instead. */
    property alias isValid: internal.isValid

    width: parent.width
    height: units.gu(12)

    QtObject {
        id: internal
        property bool isValid: (required || validationRegex) ? false : true
        property bool showError: false

        function validate() {
            if (required && text.trim().length === 0) {
                isValid = false;
                showError = text.length > 0 || textField.focus === false;
                return false;
            }
            if (validationRegex === "") {
                isValid = true;
                showError = false;
                return true;
            }
            var regex = new RegExp(validationRegex);
            isValid = regex.test(text);
            showError = !isValid && text.length > 0;
            return isValid;
        }
    }

    onTextChanged: {
        internal.validate();
    }

    Connections {
        target: textField
        onFocusChanged: {
            if (!textField.focus) {
                internal.validate();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: units.gu(1)
        spacing: units.gu(0.5)

        Label {
            id: titleLabel
            text: inputField.title
            fontSize: "small"
            color: theme.palette.normal.backgroundText
            Layout.fillWidth: true
        }

        TextField {
            id: textField
            placeholderText: inputField.placeholder
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: internal.showError ? theme.palette.normal.negative : theme.palette.normal.fieldText
        }

        Label {
            id: errorLabel
            text: required && textField.text.trim().length === 0 ? i18n.tr("This field is required") : errorMessage
            fontSize: "x-small"
            color: theme.palette.normal.negative
            visible: internal.showError
            Layout.fillWidth: true
        }
    }
}
