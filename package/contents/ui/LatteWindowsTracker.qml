/*
*  Copyright 2019 Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of applet-window-title
*
*  Latte-Dock is free software; you can redistribute it and/or
*  modify it under the terms of the GNU General Public License as
*  published by the Free Software Foundation; either version 2 of
*  the License, or (at your option) any later version.
*
*  Latte-Dock is distributed in the hope that it will be useful,
*  but WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*  GNU General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.7

Item {
    id: latteWindowsTracker
    property bool filterByScreen: true

    readonly property bool existsWindowActive: operatingWindow.isValid && !operatingTaskItem.isMinimized && operatingTaskItem.isActive
    readonly property bool existsWindowShown: operatingWindow.isValid && !operatingTaskItem.isMinimized
    readonly property bool existsWindowMaximized: operatingWindow.isValid && operatingTaskItem.isMaximized && !operatingTaskItem.isMinimized

    readonly property QtObject selectedTracker: filterByScreen ? latteBridge.windowsTracker.currentScreen : latteBridge.windowsTracker.allScreens
    readonly property QtObject operatingWindow: root.useAnyMaximizedWindow ? selectedTracker.toplevelMaximizedWindow : selectedTracker.lastActiveWindow

    readonly property Item operatingTaskItem: Item {
        readonly property string title: operatingWindow.display
        readonly property bool isMinimized: operatingWindow.isMinimized
        readonly property bool isMaximized: operatingWindow.isMaximized
        readonly property bool isActive: operatingWindow.isActive
        readonly property bool isOnAllDesktops: operatingWindow.isOnAllDesktops
        readonly property bool isKeepAbove: operatingWindow.isKeepAbove
        readonly property bool isClosable: operatingWindow.hasOwnProperty("isClosable") ? operatingWindow.isClosable : true
        readonly property bool isMinimizable: operatingWindow.hasOwnProperty("isMinimizable") ? operatingWindow.isMinimizable : true
        readonly property bool isMaximizable: operatingWindow.hasOwnProperty("isMaximizable") ? operatingWindow.isMaximizable : true
        readonly property bool isVirtualDesktopsChangeable: operatingWindow.hasOwnProperty("isVirtualDesktopsChangeable") ?
                                                                operatingWindow.isVirtualDesktopsChangeable : true
    }

    function toggleMaximized() {
        operatingWindow.requestToggleMaximized();
    }

    function toggleMinimized() {
        operatingWindow.requestToggleMinimized();
    }

    function toggleClose() {
        operatingWindow.requestClose();
    }

    function togglePinToAllDesktops() {
        operatingWindow.requestToggleIsOnAllDesktops();
    }

    function toggleKeepAbove(){
        operatingWindow.requestToggleKeepAbove();
    }
}

