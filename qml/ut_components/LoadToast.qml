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
 * \brief LoadToast - A full-screen loading overlay component for Ubuntu Touch applications
 *
 * LoadToast displays a modal overlay with an activity indicator and optional message text.
 * It blocks user interaction with the underlying content while showing a loading state.
 *
 * The component features:
 * - Semi-transparent backdrop that covers the entire parent
 * - Centered container with activity spinner
 * - Optional message text below the spinner
 * - Smooth fade in/out transitions
 *
 * Example usage:
 * \qml
 * LoadToast {
 *     id: loadingOverlay
 *     showing: dataModel.isLoading
 *     message: i18n.tr("Loading data...")
 * }
 * \endqml
 *
 * Example with dynamic message:
 * \qml
 * LoadToast {
 *     id: saveToast
 *     message: i18n.tr("Saving changes...")
 * }
 *
 * // In your logic:
 * saveToast.showing = true
 * backend.saveData()
 * // Hide when complete:
 * saveToast.showing = false
 * \endqml
 */
Item {
    id: toast

    property bool showing: false
    property string message: ""

    anchors.fill: parent
    z: 1000
    state: showing ? "visible" : "hidden"

    states: [
        State {
            name: "visible"
            PropertyChanges {
                target: toast
                opacity: 1.0
            }
            PropertyChanges {
                target: toast
                visible: true
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: toast
                opacity: 0.0
            }
            PropertyChanges {
                target: toast
                visible: false
            }
        }
    ]

    transitions: Transition {
        from: "*"
        to: "*"
        NumberAnimation {
            properties: "opacity"
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: toast.showing
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.3
        visible: toast.showing
    }

    Rectangle {
        id: toastContainer
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.8, units.gu(40))
        height: contentColumn.height + units.gu(4)
        color: theme.palette.normal.background
        radius: units.gu(1)
        visible: toast.showing

        Column {
            id: contentColumn
            anchors {
                centerIn: parent
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            ActivityIndicator {
                id: spinner
                anchors.horizontalCenter: parent.horizontalCenter
                running: toast.showing
            }

            Label {
                id: messageLabel
                anchors.horizontalCenter: parent.horizontalCenter
                text: toast.message
                wrapMode: Text.WordWrap
                width: toastContainer.width - units.gu(4)
                horizontalAlignment: Text.AlignHCenter
                visible: toast.message !== ""
            }
        }
    }
}
