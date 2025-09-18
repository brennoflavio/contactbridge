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
import io.thp.pyotherside 1.4
import "ut_components"

Page {
    id: configurationPage

    property bool backgroundSyncEnabled: false
    property bool crashReportEnabled: false

    header: AppHeader {
        pageTitle: i18n.tr("Configuration")
        isRootPage: false
        showSettingsButton: false
    }

    Component.onCompleted: {
        loadConfiguration();
    }

    function loadConfiguration() {
        python.call('server.get_configuration', [], function (config) {
                if (config) {
                    if (config.hasOwnProperty('background_sync')) {
                        configurationPage.backgroundSyncEnabled = config.background_sync;
                    }
                    if (config.hasOwnProperty('crash_report')) {
                        configurationPage.crashReportEnabled = config.crash_report;
                    }
                }
            });
    }

    function setBackgroundSync(backgroundSync) {
        errorLabel.text = "";  // Clear any previous error
        loadToast.message = i18n.tr("Updating background sync settings...");
        loadToast.showing = true;
        python.call('server.set_background_sync', [backgroundSync], function (response) {
                loadToast.showing = false;
                if (response && response.success === false) {
                    // Revert the toggle state
                    configurationPage.backgroundSyncEnabled = !backgroundSync;
                    // Show error message
                    errorLabel.text = response.message || i18n.tr("Failed to update background sync settings");
                }
            });
    }

    function setCrashReport(crashReport) {
        python.call('server.crash_report', [crashReport], function () {});
    }

    Flickable {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width
            spacing: units.gu(0)

            ConfigurationGroup {
                title: i18n.tr("General")

                ToggleOption {
                    title: i18n.tr("Background sync")
                    subtitle: i18n.tr("Install Systemd Timer for background updates")
                    checked: configurationPage.backgroundSyncEnabled
                    onToggled: function (checked) {
                        configurationPage.backgroundSyncEnabled = checked;
                        configurationPage.setBackgroundSync(checked);
                    }
                }

                ToggleOption {
                    title: i18n.tr("Crash logs")
                    subtitle: i18n.tr("Send anonymous crash reports")
                    checked: configurationPage.crashReportEnabled
                    onToggled: function (checked) {
                        configurationPage.crashReportEnabled = checked;
                        configurationPage.setCrashReport(checked);
                    }
                }
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));
            importModule('server', function () {});
        }

        onError: {
        }
    }

    LoadToast {
        id: loadToast
    }

    Rectangle {
        id: errorContainer
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: errorLabel.height + units.gu(2)
        color: theme.palette.normal.negative
        visible: errorLabel.text !== ""

        Label {
            id: errorLabel
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                margins: units.gu(2)
            }
            text: ""
            color: "white"
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
