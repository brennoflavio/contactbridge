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
    id: inputField

    property string title: ""
    property string placeholder: ""
    property alias text: textField.text
    property alias inputMethodHints: textField.inputMethodHints
    property alias echoMode: textField.echoMode
    property string validationRegex: ""
    property string errorMessage: i18n.tr("Invalid input")
    property bool isValid: true
    property bool showError: false

    width: parent.width
    height: units.gu(12)

    function validate() {
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

    onTextChanged: {
        if (validationRegex !== "") {
            validate();
        } else if (showError && text.length > 0) {
            showError = false;
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
            color: showError ? theme.palette.normal.negative : theme.palette.normal.fieldText
        }

        Label {
            id: errorLabel
            text: errorMessage
            fontSize: "x-small"
            color: theme.palette.normal.negative
            visible: showError
            Layout.fillWidth: true
        }
    }
}
