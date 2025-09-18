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
import Lomiri.OnlineAccounts 2.0
import "ut_components"

Page {
    id: addServerPage

    property bool isLoading: false
    property string errorMessage: ""

    header: AppHeader {
        id: pageHeader
        pageTitle: i18n.tr("Add Server")
        isRootPage: false
        showSettingsButton: false
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

        InputField {
            id: serverUrlField
            width: parent.width
            title: i18n.tr("Server URL")
            placeholder: i18n.tr("https://example.com/caldav")
            validationRegex: "^https?://[\\w\\-]+(\\.[\\w\\-]+)+[/#?]?.*$"
            required: true
        }

        InputField {
            id: usernameField
            width: parent.width
            title: i18n.tr("Username")
            placeholder: i18n.tr("Enter your username")
            required: true
        }

        InputField {
            id: passwordField
            width: parent.width
            title: i18n.tr("Password")
            placeholder: i18n.tr("Enter your password")
            echoMode: TextInput.Password
            required: true
        }

        onSubmitted: {
            addServerPage.isLoading = true;
            addServerPage.errorMessage = "";
            python.call('server.save_server', [serverUrlField.text, usernameField.text, passwordField.text], function (result) {
                    addServerPage.isLoading = false;
                    if (result && result.success === true) {
                        pageStack.pop();
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

    ActionButton {
        id: importAccountButton
        anchors {
            top: errorLabel.bottom
            horizontalCenter: parent.horizontalCenter
            topMargin: units.gu(2)
        }
        text: i18n.tr("Import Account")
        iconName: "contact-new"
        onClicked: {
            accountModel.requestAccess(accountModel.applicationId + "_nextcloud", {});
        }
    }

    LoadToast {
        id: loadingToast
        showing: addServerPage.isLoading
        message: i18n.tr("Connecting to server...")
    }

    AccountModel {
        id: accountModel
        onAccessReply: {
            if (reply.errorCode) {
                addServerPage.errorMessage = i18n.tr("Failed to obtain account access: %1").arg(reply.errorText);
            } else {
                useAccount(reply.account);
            }
        }
    }

    Connections {
        id: accountConnection
        target: null
        onAuthenticationReply: {
            var reply = authenticationData;
            if ("errorCode" in reply) {
                addServerPage.errorMessage = i18n.tr("Authentication error: %1").arg(reply.errorText);
                addServerPage.isLoading = false;
            } else {
                var serverUrl = accountConnection.target.settings.host || "";
                var username = reply.Username || "";
                var password = reply.Password || "";
                python.call('server.save_server', [serverUrl, username, password], function (result) {
                        addServerPage.isLoading = false;
                        if (result && result.success === true) {
                            pageStack.pop();
                        } else {
                            addServerPage.errorMessage = result ? result.message : "Unknown error";
                        }
                    });
            }
        }
    }

    function useAccount(account) {
        addServerPage.isLoading = true;
        addServerPage.errorMessage = "";
        accountConnection.target = account;
        account.authenticate({
                "host": account.settings.host,
                "accountId": account.accountId
            });
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
