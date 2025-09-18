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
 * \brief NumberOption - A numeric input field component with labels for Ubuntu Touch
 *
 * NumberOption provides a consistent way to input numeric values with validation.
 * It displays a title and optional subtitle on the left, with an editable numeric
 * field on the right. The component includes:
 * - Min/max value validation with visual feedback
 * - Optional suffix display (e.g., units)
 * - Support for negative numbers
 * - Enabled/disabled states
 *
 * Example usage for basic number input:
 * \qml
 * NumberOption {
 *     title: "Age"
 *     subtitle: "Enter your age"
 *     value: 25
 *     minimumValue: 0
 *     maximumValue: 120
 *     onValueUpdated: console.log("Age changed to", newValue)
 * }
 * \endqml
 *
 * Example usage with suffix and negative values:
 * \qml
 * NumberOption {
 *     title: "Temperature"
 *     subtitle: "Current temperature"
 *     value: 20
 *     minimumValue: -50
 *     maximumValue: 60
 *     suffix: "°C"
 *     onValueUpdated: updateTemperature(newValue)
 * }
 * \endqml
 *
 * Example usage for read-only display:
 * \qml
 * NumberOption {
 *     title: "Progress"
 *     value: 75
 *     suffix: "%"
 *     enabled: false
 * }
 * \endqml
 */
Item {
    id: numberOption

    /*! The main label displayed on the left side */
    property string title: ""

    /*! Optional secondary text displayed below the title */
    property string subtitle: ""

    /*! The current numeric value */
    property int value: 0

    /*! The minimum allowed value (supports negative numbers) */
    property int minimumValue: 0

    /*! The maximum allowed value */
    property int maximumValue: 999999

    /*! Optional suffix text displayed after the value (e.g., "km", "%", "°C") */
    property string suffix: ""

    /*! Whether the input field is editable */
    property alias enabled: textField.enabled

    /*!
     * Emitted when the value changes and passes validation
     * \param newValue The new validated numeric value
     */
    signal valueUpdated(int newValue)

    /*! Whether the current value is valid (for form validation) Do not manipulate this variable directly, use minimumValue/maximumValue instead. */
    property bool isValid: !hasValidationError

    /*! \internal */
    property bool hasValidationError: false

    height: units.gu(8)
    width: parent.width

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    Column {
        anchors {
            left: parent.left
            right: textField.left
            verticalCenter: parent.verticalCenter
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
        spacing: units.gu(0.5)

        Label {
            id: titleLabel
            text: numberOption.title
            fontSize: "medium"
            color: theme.palette.normal.foregroundText
            width: parent.width
            elide: Text.ElideRight
        }

        Label {
            id: subtitleLabel
            text: numberOption.subtitle
            fontSize: "small"
            color: theme.palette.normal.backgroundSecondaryText
            width: parent.width
            elide: Text.ElideRight
            visible: text !== ""
        }
    }

    TextField {
        id: textField
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: units.gu(2)
        }
        width: units.gu(12)
        text: numberOption.value + (numberOption.suffix ? " " + numberOption.suffix : "")
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        validator: IntValidator {
            bottom: numberOption.minimumValue
            top: numberOption.maximumValue
        }
        horizontalAlignment: TextInput.AlignRight
        color: numberOption.hasValidationError ? theme.palette.normal.negative : theme.palette.normal.foregroundText

        onTextChanged: {
            var cleanText = text.replace(numberOption.suffix, '').trim();
            var isNegative = cleanText.indexOf('-') === 0;
            var digitsOnly = cleanText.replace(/[^0-9]/g, '');
            if (digitsOnly === '' && cleanText !== '-') {
                return;
            }
            if (cleanText === '-' && numberOption.minimumValue < 0) {
                return;
            }
            var numericValue = parseInt((isNegative ? '-' : '') + digitsOnly) || 0;
            if (!isNaN(numericValue) && numericValue !== numberOption.value) {
                if (numericValue >= numberOption.minimumValue && numericValue <= numberOption.maximumValue) {
                    numberOption.hasValidationError = false;
                    numberOption.value = numericValue;
                    numberOption.valueUpdated(numericValue);
                } else {
                    numberOption.hasValidationError = true;
                }
            }
        }

        onFocusChanged: {
            if (!focus) {
                numberOption.hasValidationError = false;
                text = numberOption.value + (numberOption.suffix ? " " + numberOption.suffix : "");
            } else {
                text = numberOption.value.toString();
            }
        }
    }

    Label {
        id: validationLabel
        anchors {
            top: textField.bottom
            right: parent.right
            rightMargin: units.gu(2)
            topMargin: units.gu(0.5)
        }
        text: "Value must be between " + numberOption.minimumValue + " and " + numberOption.maximumValue
        fontSize: "x-small"
        color: theme.palette.normal.negative
        visible: numberOption.hasValidationError
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
