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
import io.thp.pyotherside 1.4
import Qt.labs.platform 1.0 as Platform
import "lib"

Page {
    id: addServerPage

    signal backRequested
    property bool isLoading: false
    property string errorMessage: ""

    header: AppHeader {
        id: pageHeader
        pageTitle: i18n.tr("Add Server")
        showBackButton: !addServerPage.isLoading
        showSettingsButton: false

        onBackClicked: {
            if (!addServerPage.isLoading) {
                addServerPage.backRequested();
            }
        }
    }

    Form {
        id: serverForm
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            topMargin: units.gu(2)
        }

        buttonText: i18n.tr("Save")
        buttonIconName: "ok"

        fields: [
            InputField {
                id: serverUrlField
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                title: i18n.tr("Server URL")
                placeholder: i18n.tr("https://example.com/caldav")
                validationRegex: "^https?://[\\w\\-]+(\\.[\\w\\-]+)+[/#?]?.*$"
                errorMessage: i18n.tr("Please enter a valid URL (e.g., https://example.com)")
            },
            InputField {
                id: usernameField
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: serverUrlField.bottom
                anchors.topMargin: units.gu(1)
                title: i18n.tr("Username")
                placeholder: i18n.tr("Enter your username")
            },
            InputField {
                id: passwordField
                width: parent.width - units.gu(4)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: usernameField.bottom
                anchors.topMargin: units.gu(1)
                title: i18n.tr("Password")
                placeholder: i18n.tr("Enter your password")
                echoMode: TextInput.Password
            }
        ]

        onSubmitted: {
            if (!serverUrlField.validate() || usernameField.text === "" || passwordField.text === "") {
                addServerPage.errorMessage = i18n.tr("Please fill all fields");
                return;
            }
            addServerPage.isLoading = true;
            addServerPage.errorMessage = "";
            python.call('server.save_server', [serverUrlField.text, usernameField.text, passwordField.text], function (result) {
                    addServerPage.isLoading = false;
                    if (result && result.success === true) {
                        addServerPage.backRequested();
                    } else {
                        addServerPage.errorMessage = result ? result.message : "Unknown error";
                    }
                });
        }
    }

    Label {
        id: errorLabel
        anchors {
            top: serverForm.bottom
            left: parent.left
            right: parent.right
            topMargin: units.gu(2.5)
            leftMargin: units.gu(2)
            rightMargin: units.gu(2)
        }
        text: addServerPage.errorMessage
        color: theme.palette.normal.negative
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        visible: addServerPage.errorMessage !== ""
    }

    LoadToast {
        id: loadingToast
        showing: addServerPage.isLoading
        showSpinner: true
        message: i18n.tr("Connecting to server...")
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'));
        }

        onError: {
        }
    }
}
