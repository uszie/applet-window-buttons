/*
*  Copyright 2018 Michail Vourlakos <mvourlakos@gmail.com>
*
*  This file is part of applet-window-buttons
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
import QtQml.Models 2.2

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.taskmanager 0.1 as TaskManager

Item {
    id: plasmaTasksItem
    property bool filterByScreen: true

    readonly property bool existsWindowActive: operatingTaskItem && tasksRepeater.count > 0 && operatingTaskItem.isActive
    readonly property bool existsWindowShown: operatingTaskItem && tasksRepeater.count > 0 && !operatingTaskItem.isMinimized
    readonly property bool existsWindowMaximized: operatingTaskItem && tasksRepeater.count > 0 && operatingTaskItem.isMaximized && !operatingTaskItem.isMinimized

    readonly property Item operatingTaskItem: root.useAnyMaximizedWindow ? toplevelMaximizedTaskItem : lastActiveTaskItem
    property Item lastActiveTaskItem: null
    property Item toplevelMaximizedTaskItem: null

    // To get current activity name
    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // To get virtual desktop name
    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        screenGeometry: plasmoid.screenGeometry
        activity: activityInfo.currentActivity
        virtualDesktop: virtualDesktopInfo.currentDesktop

        filterByScreen: plasmaTasksItem.filterByScreen
        filterByVirtualDesktop: true
        filterByActivity: true
    }

    Repeater{
        id: tasksRepeater
        model:DelegateModel {
            model: tasksModel
            delegate: Item{
                id: task
                readonly property string title: display
                readonly property bool isMinimized: IsMinimized === true ? true : false
                readonly property bool isMaximized: IsMaximized === true ? true : false
                readonly property bool isActive: IsActive === true ? true : false
                readonly property bool isOnAllDesktops: IsOnAllVirtualDesktops === true ? true : false
                readonly property bool isKeepAbove: IsKeepAbove === true ? true : false
                readonly property bool isClosable: IsClosable === true ? true : false
                readonly property bool isMinimizable: IsMinimizable === true ? true : false
                readonly property bool isMaximizable: IsMaximizable === true ? true : false
                readonly property bool isVirtualDesktopsChangeable: IsVirtualDesktopsChangeable === true ? true : false
                readonly property int stackingOrder: StackingOrder

                onIsMaximizedChanged: updateToplevelMaximizedWindow();

                onIsMinimizedChanged: updateToplevelMaximizedWindow();

                onIsActiveChanged: {
                    if (isActive) {
                        plasmaTasksItem.lastActiveTaskItem = task;
                    }

                    updateToplevelMaximizedWindow();
                }

                Component.onDestruction: {
                    if (plasmaTasksItem.lastActiveTaskItem === task) {
                        plasmaTasksItem.lastActiveTaskItem = null;
                    }

                    updateToplevelMaximizedWindow();
                }

                function modelIndex(){
                    return tasksModel.makeModelIndex(index);
                }

                function toggleMaximized() {
                    tasksModel.requestToggleMaximized(modelIndex());
                }

                function toggleMinimized() {
                    tasksModel.requestToggleMinimized(modelIndex());
                }

                function toggleClose() {
                    tasksModel.requestClose(modelIndex());
                }

                function togglePinToAllDesktops() {
                    if (root.plasma515) {
                        tasksModel.requestVirtualDesktops(modelIndex(), 0);
                    } else {
                        tasksModel.requestVirtualDesktop(modelIndex(), 0);
                    }
                }

                function toggleKeepAbove(){
                    tasksModel.requestToggleKeepAbove(modelIndex());
                }
            }
        }
    }

    function toggleMaximized() {
        if (operatingTaskItem) {
            operatingTaskItem.toggleMaximized();
        }
    }

    function toggleMinimized() {
        if (operatingTaskItem) {
            operatingTaskItem.toggleMinimized();
        }
    }

    function toggleClose() {
        if (operatingTaskItem) {
            operatingTaskItem.toggleClose();
        }
    }

    function togglePinToAllDesktops() {
        if (operatingTaskItem) {
            operatingTaskItem.togglePinToAllDesktops();
        }
    }

    function toggleKeepAbove(){
        if (operatingTaskItem) {
            operatingTaskItem.toggleKeepAbove();
        }
    }

    function updateToplevelMaximizedWindow(){
        var maxStackingOrder = -10
        var taskWindow = null;
        for (var i = 0; i < tasksRepeater.count; i++ ) {

            var currentTaskWindow = tasksRepeater.itemAt(i);
            if (currentTaskWindow.isMaximized && !currentTaskWindow.isMinimized && currentTaskWindow.stackingOrder > maxStackingOrder) {
                maxStackingOrder = currentTaskWindow.stackingOrder;
                taskWindow = currentTaskWindow;
            }
        }

        toplevelMaximizedTaskItem = taskWindow;
    }
}
