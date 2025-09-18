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
 * \brief BottomBar - A bottom navigation bar component for Ubuntu Touch applications
 *
 * BottomBar provides a fixed-height bottom bar with three distinct sections:
 * 1. Left slot - Optional button on the left side
 * 2. Center area - Row of buttons/actions in the middle
 * 3. Right slot - Optional button on the right side
 *
 * The component includes a top separator line and uses Ubuntu Touch theme colors
 * for consistent styling across applications.
 *
 * Example usage with all sections:
 * \qml
 * BottomBar {
 *     leftButton: IconButton {
 *         iconName: "back"
 *         text: "Back"
 *         onClicked: console.log("Back button clicked")
 *     }
 *     rightButton: IconButton {
 *         iconName: "go-next"
 *         text: "Forward"
 *         onClicked: console.log("Forward button clicked")
 *     }
 *
 *     // Middle buttons are added as children
 *     IconButton {
 *         iconName: "home"
 *         onClicked: console.log("Home button clicked")
 *     }
 *     IconButton {
 *         iconName: "search"
 *         onClicked: console.log("Search button clicked")
 *     }
 * }
 * \endqml
 *
 * Example usage with only middle buttons:
 * \qml
 * BottomBar {
 *     IconButton { iconName: "add", text: "Action 1" }
 *     IconButton { iconName: "add", text: "Action 2" }
 *     IconButton { iconName: "add", text: "Action 3" }
 * }
 * \endqml
 */
Rectangle {
    id: bottomBar

    /*! Optional button component to display on the left side */
    property Item leftButton: null

    /*! Optional button component to display on the right side */
    property Item rightButton: null

    /*!
     * Child items placed in the center row
     * This is the default property, so buttons can be added as direct children
     */
    default property alias middleButtons: middleButtonsRow.children

    height: units.gu(8)
    color: theme.palette.normal.background

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: units.dp(1)
        color: theme.palette.normal.base
    }

    Item {
        anchors.fill: parent
        anchors.margins: units.gu(1)

        Item {
            id: leftButtonContainer
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            width: leftButton ? leftButton.width : 0
            height: leftButton ? leftButton.height : 0

            Component.onCompleted: {
                if (leftButton) {
                    leftButton.parent = leftButtonContainer;
                    leftButton.anchors.centerIn = leftButtonContainer;
                }
            }
        }

        Row {
            id: middleButtonsRow
            anchors.centerIn: parent
            spacing: units.gu(2)
        }

        Item {
            id: rightButtonContainer
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            width: rightButton ? rightButton.width : 0
            height: rightButton ? rightButton.height : 0

            Component.onCompleted: {
                if (rightButton) {
                    rightButton.parent = rightButtonContainer;
                    rightButton.anchors.centerIn = rightButtonContainer;
                }
            }
        }
    }
}
