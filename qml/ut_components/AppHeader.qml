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
 * \brief AppHeader - A simplified page header component for Ubuntu Touch applications
 *
 * AppHeader provides a consistent header with two distinct styles:
 * 1. Root page style - Shows an app icon (no navigation)
 * 2. Sub-page style - Shows a back button for navigation
 *
 * The component optionally displays a settings button in the trailing position.
 *
 * Example usage for a root page:
 * \qml
 * AppHeader {
 *     pageTitle: "My App"
 *     isRootPage: true
 *     appIconName: "my-app-icon"
 *     showSettingsButton: true
 *     onSettingsClicked: pageStack.push(settingsPage)
 * }
 * \endqml
 *
 * Example usage for a sub-page:
 * \qml
 * AppHeader {
 *     pageTitle: "Details"
 *     isRootPage: false
 *     showSettingsButton: false
 *     // Back button automatically navigates to the previous page
 * }
 * \endqml
 */
PageHeader {
    id: appHeader

    /*! The title text displayed in the header */
    property string pageTitle: ""

    /*!
     * Determines the header style:
     * - true: Root page style with app icon (no back navigation)
     * - false: Sub-page style with back button
     */
    property bool isRootPage: true

    /*!
     * Icon name to display on root pages (only used when isRootPage is true)
     * Leave empty to hide the leading icon on root pages
     */
    property string appIconName: ""

    /*! Whether to show a settings button in the trailing position */
    property bool showSettingsButton: false

    /*! Emitted when the settings button is clicked */
    signal settingsClicked

    title: pageTitle

    leadingActionBar {
        visible: !isRootPage || appIconName !== ""
        actions: [
            Action {
                iconName: isRootPage ? appIconName : "back"
                text: isRootPage ? "" : i18n.tr("Back")
                enabled: !isRootPage
                onTriggered: {
                    if (!isRootPage && pageStack) {
                        pageStack.pop();
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
