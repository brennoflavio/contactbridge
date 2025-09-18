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
import "."

/*!
 * \brief Form - Declarative form container with submit action
 *
 * Form arranges input fields in a vertical column, tracks their validation state
 * (via an optional `isValid` property) and exposes a single submit button that emits
 * `submitted` when clicked. The button is automatically disabled until every child
 * field reporting `isValid` evaluates to true.
 * This component is meant to be used with ToggleOption, InputField, and NumberOption that
 * are in this folder. Here is a brief explanation of each:
 * - ToggleOption (title str, subtitle str, checked bool, enabled bool): A switch control for enabling/disabling a setting.
 * - InputField (title str, placeholder str, validationRegex str, text str, required bool): A text input field for user input.
 * - NumberOption (title str, subtitle str, value int, minimumValue int, maximumValue: int, enabled bool):: A numeric input field with range constraints.
 *
 * Example usage:
 * \qml
 * Form {
 *     buttonText: i18n.tr("Create account")
 *     buttonIconName: "ok"
 *
 *     TextField {
 *         placeholderText: i18n.tr("Email")
 *         property bool isValid: text.length > 0
 *     }
 *
 *     PasswordField {
 *         placeholderText: i18n.tr("Password")
 *         property bool isValid: text.length >= 8
 *     }
 *
 *     onSubmitted: authController.submit()
 * }
 * \endqml
 *
 * API:
 * - `fields` (default property): declaratively add child form fields.
 * - `buttonText`: label shown on the submit button.
 * - `buttonIconName`: optional icon name for the submit button.
 * - `allFieldsValid`: read-only helper reflecting the validation status.
 * - `submitted`: signal emitted when the submit button is triggered.
 */
Item {
    id: form

    /*! Default property used to declare child fields within the form */
    default property alias fields: fieldsContainer.children

    /*! Text label displayed on the submit button */
    property string buttonText: i18n.tr("Submit")

    /*! Icon name applied to the submit button; leave empty for no icon */
    property string buttonIconName: ""

    /*! Consolidated validity state evaluated from child fields providing `isValid` */
    property bool allFieldsValid: {
        for (var i = 0; i < fieldsContainer.children.length; i++) {
            var field = fieldsContainer.children[i];
            if (field.hasOwnProperty('isValid') && !field.isValid) {
                return false;
            }
        }
        return true;
    }

    /*! Emitted when the submit button is pressed and all fields are valid */
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
        height: implicitHeight
        spacing: units.gu(1)

        Column {
            id: fieldsContainer
            Layout.fillWidth: true
            width: parent.width
            spacing: units.gu(1)
        }

        ActionButton {
            id: submitButton
            readonly property real calculatedWidth: Math.min(form.width - units.gu(4), units.gu(30))

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: units.gu(2)
            Layout.preferredWidth: calculatedWidth
            Layout.minimumWidth: calculatedWidth
            Layout.maximumWidth: calculatedWidth
            Layout.preferredHeight: implicitHeight

            width: calculatedWidth
            text: form.buttonText
            iconName: form.buttonIconName
            enabled: form.allFieldsValid

            onClicked: {
                form.submitted();
            }
        }
    }
}
