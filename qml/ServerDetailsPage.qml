import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
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
import io.thp.pyotherside 1.4
import "ut_components"

Page {
    id: serverDetailsPage

    property string serverId: ""
    property string serverName: ""
    property var addressBooks: []
    property bool isLoading: true
    property string errorMessage: ""
    property var syncLogs: []
    property bool isUpdatingAddressBook: false
    property bool isDeletingServer: false

    function loadServerDetails() {
        if (serverId === "") {
            isLoading = false;
            errorMessage = i18n.tr("Invalid server ID");
            return ;
        }
        isLoading = true;
        errorMessage = "";
        python.call('server.get_server_detail', [serverId], function(result) {
            isLoading = false;
            if (result && result.addressbooks) {
                addressBooks = result.addressbooks;
                loadSyncLogs();
            } else {
                errorMessage = i18n.tr("Failed to load server details");
            }
        });
    }

    function loadSyncLogs() {
        python.call('server.server_sync_log', [serverId], function(result) {
            if (result && result.server_logs)
                syncLogs = result.server_logs;

        });
    }

    function updateAddressBookStatus(addressBookId, enabled) {
        isUpdatingAddressBook = true;
        python.call('server.update_address_book_status', [serverId, addressBookId, enabled], function(result) {
            isUpdatingAddressBook = false;
            loadServerDetails();
        });
    }

    function copyToClipboard(text) {
        Clipboard.push(text);
        copiedLabel.visible = true;
        copiedTimer.restart();
    }

    function buildSyncLogText() {
        var text = "";
        for (var i = 0; i < syncLogs.length; i++) {
            var log = syncLogs[i];
            text += (log.addressbook_name || i18n.tr("Unknown Address Book")) + "\n";
            text += i18n.tr("Last sync:") + " " + (log.last_run_time || i18n.tr("Never")) + "\n";
            text += i18n.tr("Type:") + " " + (log.last_run_type || i18n.tr("Unknown")) + "\n";
            text += i18n.tr("Status:") + " " + (log.last_run_success ? i18n.tr("Success") : i18n.tr("Failed")) + "\n";
            if (log.last_run_message && log.last_run_message !== "")
                text += i18n.tr("Message:") + " " + log.last_run_message + "\n";

            if (i < syncLogs.length - 1)
                text += "\n";

        }
        return text;
    }

    function deleteServer() {
        isDeletingServer = true;
        python.call('server.delete_server', [serverId], function(result) {
            isDeletingServer = false;
            if (result && result.success)
                pageStack.pop();
            else
                errorMessage = i18n.tr("Failed to delete server");
        });
    }

    Component.onCompleted: {
        if (serverId === "") {
            errorMessage = i18n.tr("No server ID provided");
            isLoading = false;
        }
    }

    Flickable {
        contentHeight: contentColumn.height
        visible: !isLoading && !errorMessage

        anchors {
            top: detailsHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: units.gu(2)
        }

        Column {
            id: contentColumn

            width: parent.width
            spacing: units.gu(2)

            ConfigurationGroup {
                title: i18n.tr("Address Books")
                visible: addressBooks && addressBooks.length > 0

                Repeater {
                    model: addressBooks

                    ToggleOption {
                        title: modelData.name || i18n.tr("Unnamed Address Book")
                        subtitle: ""
                        checked: modelData.enabled || false
                        onToggled: function(checked) {
                            updateAddressBookStatus(modelData.id, checked);
                        }
                    }

                }

            }

            Label {
                width: parent.width
                text: i18n.tr("No address books found")
                horizontalAlignment: Text.AlignHCenter
                color: theme.palette.normal.backgroundSecondaryText
                visible: !addressBooks || addressBooks.length === 0
            }

            Item {
                width: parent.width
                height: units.gu(3)
            }

            ActionButton {
                id: deleteServerButton

                anchors.horizontalCenter: parent.horizontalCenter
                text: i18n.tr("Delete Server")
                iconName: "delete"
                backgroundColor: theme.palette.normal.negative
                onClicked: {
                    PopupUtils.open(deleteConfirmDialog);
                }
            }

            Item {
                width: parent.width
                height: units.gu(2)
            }

            ConfigurationGroup {
                title: i18n.tr("Sync Logs")
                visible: syncLogs && syncLogs.length > 0

                Repeater {
                    model: syncLogs

                    Item {
                        property bool expanded: false

                        width: parent.width
                        height: logColumn.height + units.gu(2)

                        Column {
                            id: logColumn

                            width: parent.width
                            spacing: units.gu(0.5)

                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: units.gu(2)
                                rightMargin: units.gu(2)
                                verticalCenter: parent.verticalCenter
                            }

                            Label {
                                text: modelData.addressbook_name || i18n.tr("Unknown Address Book")
                                fontSize: "medium"
                                font.weight: Font.DemiBold
                            }

                            Row {
                                spacing: units.gu(1)

                                Label {
                                    text: i18n.tr("Last sync:")
                                    fontSize: "small"
                                    color: theme.palette.normal.backgroundSecondaryText
                                }

                                Label {
                                    text: modelData.last_run_time || i18n.tr("Never")
                                    fontSize: "small"
                                    color: theme.palette.normal.backgroundTertiaryText
                                }

                            }

                            Row {
                                spacing: units.gu(1)

                                Label {
                                    text: i18n.tr("Type:")
                                    fontSize: "small"
                                    color: theme.palette.normal.backgroundSecondaryText
                                }

                                Label {
                                    text: modelData.last_run_type || i18n.tr("Unknown")
                                    fontSize: "small"
                                    color: theme.palette.normal.backgroundTertiaryText
                                }

                            }

                            Row {
                                spacing: units.gu(1)

                                Label {
                                    text: i18n.tr("Status:")
                                    fontSize: "small"
                                    color: theme.palette.normal.backgroundSecondaryText
                                }

                                Label {
                                    text: modelData.last_run_success ? i18n.tr("Success") : i18n.tr("Failed")
                                    fontSize: "small"
                                    color: modelData.last_run_success ? theme.palette.normal.positive : theme.palette.normal.negative
                                }

                            }

                            Label {
                                width: parent.width
                                text: {
                                    if (!modelData.last_run_message || modelData.last_run_message === "")
                                        return "";

                                    if (modelData.last_run_message.length > 150 && !parent.parent.expanded)
                                        return modelData.last_run_message.substring(0, 150) + "...";

                                    return modelData.last_run_message;
                                }
                                fontSize: "small"
                                color: theme.palette.normal.backgroundTertiaryText
                                wrapMode: Text.WordWrap
                                visible: modelData.last_run_message && modelData.last_run_message !== ""
                            }

                            Label {
                                text: parent.parent.expanded ? i18n.tr("Show less") : i18n.tr("Show more")
                                fontSize: "small"
                                color: theme.palette.normal.activity
                                visible: modelData.last_run_message && modelData.last_run_message.length > 150

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        parent.parent.parent.expanded = !parent.parent.parent.expanded;
                                    }
                                }

                            }

                            Rectangle {
                                width: parent.width + units.gu(4)
                                height: units.gu(0.1)
                                color: theme.palette.normal.base
                                visible: index < syncLogs.length - 1

                                anchors {
                                    left: parent.left
                                    leftMargin: -units.gu(2)
                                }

                            }

                        }

                    }

                }

                ActionButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    iconName: "edit-copy"
                    text: i18n.tr("Copy Logs")
                    onClicked: {
                        copyToClipboard(buildSyncLogText());
                    }
                }

            }

            Label {
                width: parent.width
                text: i18n.tr("No sync logs available")
                horizontalAlignment: Text.AlignHCenter
                color: theme.palette.normal.backgroundSecondaryText
                visible: !syncLogs || syncLogs.length === 0
            }

            Item {
                width: parent.width
                height: units.gu(2)
            }

        }

    }

    Label {
        id: copiedLabel

        z: 100
        anchors.bottom: parent.bottom
        anchors.bottomMargin: units.gu(4)
        anchors.horizontalCenter: parent.horizontalCenter
        text: i18n.tr("Copied to clipboard")
        fontSize: "small"
        color: theme.palette.normal.overlayText
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: -units.gu(1.5)
            color: theme.palette.normal.overlay
            radius: units.gu(1)
            z: -1
        }

    }

    Timer {
        id: copiedTimer

        interval: 2000
        onTriggered: copiedLabel.visible = false
    }

    LoadToast {
        showing: isLoading
        message: i18n.tr("Loading server details...")
    }

    LoadToast {
        showing: isUpdatingAddressBook
        message: i18n.tr("Updating address book...")
    }

    LoadToast {
        showing: isDeletingServer
        message: i18n.tr("Deleting server...")
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - units.gu(4)
        text: errorMessage
        color: theme.palette.normal.negative
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        visible: errorMessage !== "" && !isLoading
    }

    Component {
        id: deleteConfirmDialog

        Dialog {
            id: dialogue

            title: i18n.tr("Delete Server")
            text: i18n.tr("This will remove the Addressbooks from your device. Are you sure?")

            Button {
                text: i18n.tr("Cancel")
                onClicked: PopupUtils.close(dialogue)
            }

            Button {
                text: i18n.tr("Delete")
                color: theme.palette.normal.negative
                onClicked: {
                    PopupUtils.close(dialogue);
                    deleteServer();
                }
            }

        }

    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'));
            importModule('server', function() {
                loadServerDetails();
            });
        }
        onError: {
            isLoading = false;
            errorMessage = i18n.tr("Error loading server details");
        }
    }

    header: AppHeader {
        id: detailsHeader

        pageTitle: serverName || i18n.tr("Server Details")
        isRootPage: false
        showSettingsButton: false
    }

}
