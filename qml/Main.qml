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
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.4
import "ut_components"
import Qt.labs.platform 1.0 as Platform
import Lomiri.PushNotifications 0.1

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'contactbridge.brennoflavio'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    PushClient {
        id: pushClient
        appId: "contactbridge.brennoflavio_contactbridge"
        onTokenChanged: {
            python.call('server.persist_token', [pushClient.token]);
        }
    }

    property var serverList: []
    property bool isSyncing: false
    property string syncMessage: ""
    property bool syncSuccess: false

    function refreshServerList() {
        python.call('server.get_servers', [], function (result) {
                root.serverList = result.servers.map(function (server) {
                        return {
                            "id": server.id,
                            "title": server.name,
                            "icon": "address-book-app-symbolic",
                            "subtitle": server.item_count + " " + i18n.tr("Address Books") + " • " + server.description
                        };
                    });
            });
    }

    PageStack {
        id: pageStack
        anchors.fill: parent

        Component.onCompleted: push(mainPage)

        Page {
            id: mainPage
            visible: false

            onActiveChanged: {
                if (active) {
                    root.refreshServerList();
                }
            }

            header: AppHeader {
                id: mainHeader
                pageTitle: i18n.tr('Contact Bridge')
                isRootPage: true
                appIconName: "phone-apple-iphone-symbolic"
                showSettingsButton: true

                onSettingsClicked: {
                    root.syncMessage = "";
                    pageStack.push(Qt.resolvedUrl("ConfigurationPage.qml"));
                }
            }

            CardList {
                id: cardList
                anchors {
                    top: mainHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: syncServersButton.top
                    margins: units.gu(2)
                    bottomMargin: units.gu(1)
                }
                items: root.serverList
                emptyMessage: i18n.tr("No servers configured")

                onItemClicked: {
                    root.syncMessage = "";
                    pageStack.push(Qt.resolvedUrl("ServerDetailsPage.qml"), {
                            "serverId": item.id,
                            "serverName": item.title
                        });
                }
            }

            ActionButton {
                id: syncServersButton
                anchors {
                    bottom: addServerButton.top
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: units.gu(1)
                }
                text: i18n.tr("Sync Servers")
                iconName: "sync"
                enabled: !root.isSyncing

                onClicked: {
                    root.isSyncing = true;
                    root.syncMessage = "";
                    python.call('server.sync_servers', [], function (result) {
                            root.isSyncing = false;
                            if (result) {
                                root.syncSuccess = result.success === true;
                                root.syncMessage = result.message || (root.syncSuccess ? "Sync completed" : "Sync failed");
                            } else {
                                root.syncSuccess = false;
                                root.syncMessage = i18n.tr("Unknown sync error");
                            }
                        });
                }
            }

            ActionButton {
                id: addServerButton
                anchors {
                    bottom: syncMessageLabel.top
                    horizontalCenter: parent.horizontalCenter
                    bottomMargin: units.gu(1)
                }
                text: i18n.tr("Add Server")
                iconName: "add"

                onClicked: {
                    root.syncMessage = "";
                    pageStack.push(Qt.resolvedUrl("AddServerPage.qml"));
                }
            }

            Label {
                id: syncMessageLabel
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    bottomMargin: units.gu(2)
                    leftMargin: units.gu(2)
                    rightMargin: units.gu(2)
                }
                text: root.syncMessage
                color: root.syncSuccess ? theme.palette.normal.positive : theme.palette.normal.negative
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                visible: root.syncMessage !== ""
            }

            LoadToast {
                id: syncLoadingToast
                showing: root.isSyncing
                message: i18n.tr("Syncing servers...")
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule('server', function () {
                    root.refreshServerList();
                });
        }

        onError: {
        }
    }
}
