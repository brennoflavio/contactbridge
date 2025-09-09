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

PageHeader {
    id: appHeader

    property string pageTitle: ""
    property bool showBackButton: false
    property bool showSettingsButton: false
    property string iconName: ""

    signal backClicked
    signal settingsClicked

    title: pageTitle

    leadingActionBar {
        visible: showBackButton || iconName !== ""
        actions: [
            Action {
                iconName: showBackButton ? "back" : appHeader.iconName
                text: showBackButton ? i18n.tr("Back") : ""
                onTriggered: {
                    if (showBackButton) {
                        appHeader.backClicked();
                    }
                }
            }
        ]
    }

    trailingActionBar {
        visible: showSettingsButton
        actions: [
            Action {
                iconName: "settings"
                text: i18n.tr("Settings")
                onTriggered: appHeader.settingsClicked()
            }
        ]
    }
}
