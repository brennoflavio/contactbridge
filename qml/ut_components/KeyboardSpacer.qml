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
import QtQuick 2.12

/*!
 * \brief KeyboardSpacer - An automatic spacer that adjusts for the virtual keyboard
 *
 * KeyboardSpacer is a zero-configuration component that automatically creates
 * space when the virtual keyboard appears on screen. It prevents the keyboard
 * from covering important UI elements by expanding its height to match the
 * keyboard's height.
 *
 * The component requires no properties or configuration - simply place it in
 * your layout where you want the spacing to appear when the keyboard is shown.
 *
 * Features:
 * - Automatically tracks keyboard visibility
 * - Zero height when keyboard is hidden
 * - Expands to keyboard height when shown
 * - Inherits width from parent container
 *
 * Example usage in a Column layout:
 * \qml
 * Column {
 *     TextField {
 *         placeholderText: "Type here..."
 *     }
 *
 *     // Other content here
 *
 *     KeyboardSpacer {
 *         // Pushes content above when keyboard appears
 *     }
 * }
 * \endqml
 *
 * Example usage at the bottom of a page:
 * \qml
 * Page {
 *     Flickable {
 *         anchors.fill: parent
 *         contentHeight: column.height
 *
 *         Column {
 *             id: column
 *             width: parent.width
 *
 *             // Your content here
 *
 *             KeyboardSpacer {
 *                 // Creates scrollable space when keyboard appears
 *             }
 *         }
 *     }
 * }
 * \endqml
 */
Item {
    height: Qt.inputMethod.keyboardRectangle.height
    width: parent ? parent.width : 0
}
