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
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.appletdecoration 0.1 as AppletDecoration

import "../code/tools.js" as ModelTools

Item {
    id: root
    clip: true

    Layout.fillHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? true : false
    Layout.fillWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? false : true

    Layout.minimumWidth: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? animatedMinimumWidth : -1
    Layout.minimumHeight: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? -1 : animatedMinimumHeight
    Layout.preferredHeight: Layout.minimumHeight
    Layout.preferredWidth: Layout.minimumWidth
    Layout.maximumHeight: Layout.minimumHeight
    Layout.maximumWidth: Layout.minimumWidth

    Plasmoid.preferredRepresentation: Plasmoid.fullRepresentation
    Plasmoid.onFormFactorChanged: plasmoid.configuration.formFactor = plasmoid.formFactor;

    property int animatedMinimumWidth: minimumWidth
    property int animatedMinimumHeight: minimumHeight

    readonly property bool inEditMode: latteInEditMode || plasmoid.userConfiguring

    readonly property bool plasma515: AppletDecoration.Environment.plasmaDesktopVersion >= AppletDecoration.Environment.makeVersion(5,15,0)
    readonly property bool isStackingOrderSupported: {
        var supported = false;

        if (latteBridge) {
            if (latteBridge.version < latteBridge.actions.version(0,9,75)) { // TODO: replace with version that actually has the patches
                supported = false;
            } else if (AppletDecoration.Environment.isPlatformX11) {
                supported = true;
            } else if (AppletDecoration.Environment.isPlatformWayland &&
                    AppletDecoration.Environment.frameworksVersion >= AppletDecoration.Environment.makeVersion(5,73,0)) {
                supported = true;
            }
        } else {
            if (AppletDecoration.Environment.isPlatformX11 &&
                    AppletDecoration.Environment.plasmaDesktopVersion >= AppletDecoration.Environment.makeVersion(5,18,0)) {
                supported = true;
            } else if (AppletDecoration.Environment.isPlatformWayland &&
                    AppletDecoration.Environment.plasmaDesktopVersion >= AppletDecoration.Environment.makeVersion(5,21,2)) { // TODO: replace with version that actually has the patches
                supported = true;
            }
        }

        plasmoid.configuration.isStackingOrderSupported = supported;

        return supported;
    }
    
    readonly property bool useAnyMaximizedWindow: visibility === AppletDecoration.Types.AnyMaximizedWindow

    readonly property bool mustHide: {
        if (visibility === AppletDecoration.Types.AlwaysVisible || inEditMode) {
            return false;
        }

        if (visibility === AppletDecoration.Types.ActiveWindow && !existsWindowActive) {
            return true;
        }

        if (visibility === AppletDecoration.Types.ActiveMaximizedWindow
                && (!isLastActiveWindowMaximized || (inPlasmaPanel && !existsWindowActive))) {
            return true;
        }

        if (visibility === AppletDecoration.Types.ShownWindowExists && !existsWindowShown) {
            return true;
        }

        if (visibility === AppletDecoration.Types.AnyMaximizedWindow && !existsWindowMaximized) {
            return true;
        }

        return false;
    }

    readonly property bool selectedDecorationExists: decorations.decorationExists(plasmoid.configuration.selectedPlugin, plasmoid.configuration.selectedTheme)

    readonly property bool slideAnimationEnabled: ( (visibility !== AppletDecoration.Types.AlwaysVisible)
                                                   && (plasmoid.configuration.hiddenState === AppletDecoration.Types.SlideOut) )
    readonly property bool emptySpaceEnabled: ( (visibility !== AppletDecoration.Types.AlwaysVisible)
                                                   && (plasmoid.configuration.hiddenState === AppletDecoration.Types.EmptySpace) )

    readonly property int containmentType: plasmoid.configuration.containmentType
    readonly property int disabledMaximizedBorders: plasmoid.configuration.disabledMaximizedBorders
    readonly property int visibility: (plasmoid.configuration.visibility === AppletDecoration.Types.AnyMaximizedWindow) &&
                                      !isStackingOrderSupported ?
                                          AppletDecoration.Types.ActiveMaximizedWindow :
                                          plasmoid.configuration.visibility

    readonly property int minimumWidth: {
        if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            if (mustHide && slideAnimationEnabled && !plasmoid.userConfiguring && !latteInEditMode){
                return 0;
            }
        }

        return plasmoid.formFactor === PlasmaCore.Types.Horizontal ? buttonsArea.width : -1;
    }

    readonly property int minimumHeight: {
        if (plasmoid.formFactor === PlasmaCore.Types.Vertical) {
            if (mustHide && slideAnimationEnabled && !plasmoid.userConfiguring && !latteInEditMode){
                return 0;
            }
        }

        return plasmoid.formFactor === PlasmaCore.Types.Horizontal ? -1 : buttonsArea.height
    }

    readonly property string buttonsStr: plasmoid.configuration.buttons

    Plasmoid.status: {
        if (mustHide) {
            if ((plasmoid.formFactor === PlasmaCore.Types.Horizontal && animatedMinimumWidth === 0)
                    || (plasmoid.formFactor === PlasmaCore.Types.Vertical && animatedMinimumHeight === 0)) {
                return PlasmaCore.Types.HiddenStatus;
            }
        }

        return PlasmaCore.Types.ActiveStatus;
    }

    // START visual properties
    property bool inactiveStateEnabled: inEditMode ? false : plasmoid.configuration.inactiveStateEnabled

    property int thickPadding: {
        if (auroraeThemeEngine.isEnabled && plasmoid.configuration.useDecorationMetrics) {
            return plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                        ((root.height - auroraeThemeEngine.buttonHeight) / 2) - 1 :
                        ((root.width - auroraeThemeEngine.buttonHeight) / 2) - 1;
        }

        //! Latte padding
        if (inLatte) {
            if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
                return (root.height - (latteBridge.iconSize * (plasmoid.configuration.buttonSizePercentage/100))) / 2;
            } else {
                return (root.width - (latteBridge.iconSize * (plasmoid.configuration.buttonSizePercentage/100))) / 2;
            }
        }

        //! Plasma panels code
        if (plasmoid.formFactor === PlasmaCore.Types.Horizontal) {
            return (root.height - (root.height * (plasmoid.configuration.buttonSizePercentage/100))) / 2;
        } else {
            return (root.width - (root.width * (plasmoid.configuration.buttonSizePercentage/100))) / 2;
        }
    }

    property int lengthFirstMargin: plasmoid.configuration.lengthFirstMargin
    property int lengthLastMargin: plasmoid.configuration.lengthLastMargin

    property int lengthFirstPadding: Math.min(lengthFirstMargin, lengthMidPadding)
    property int lengthMidPadding: spacing / 2
    property int lengthLastPadding: Math.min(lengthLastMargin, lengthMidPadding)

    property int spacing: {
        if (auroraeThemeEngine.isEnabled && plasmoid.configuration.useDecorationMetrics) {
            return auroraeThemeEngine.buttonSpacing;
        }

        return plasmoid.configuration.spacing;
    }
    // END visual properties

    // START window properties

    //! make sure that on startup it will always be shown
    readonly property bool existsWindowActive: (windowInfoLoader.item && windowInfoLoader.item.existsWindowActive)
                                               || containmentIdentifierTimer.running
    readonly property bool existsWindowShown: (windowInfoLoader.item && windowInfoLoader.item.existsWindowShown)
                                              || containmentIdentifierTimer.running

    readonly property bool existsWindowMaximized: (windowInfoLoader.item && windowInfoLoader.item.existsWindowMaximized)
                                              || containmentIdentifierTimer.running

    readonly property bool isLastActiveWindowPinned: lastActiveTaskItem && existsWindowShown && lastActiveTaskItem.isOnAllDesktops
    readonly property bool isLastActiveWindowMaximized: lastActiveTaskItem && existsWindowShown && lastActiveTaskItem.isMaximized
    readonly property bool isLastActiveWindowKeepAbove: lastActiveTaskItem && existsWindowShown && lastActiveTaskItem.isKeepAbove

    readonly property bool isLastActiveWindowClosable: lastActiveTaskItem && existsWindowShown && lastActiveTaskItem.isClosable
    readonly property bool isLastActiveWindowMaximizable: lastActiveTaskItem && existsWindowShown && lastActiveTaskItem.isMaximizable
    readonly property bool isLastActiveWindowMinimizable: lastActiveTaskItem && existsWindowShown && lastActiveTaskItem.isMinimizable
    readonly property bool isLastActiveWindowVirtualDesktopsChangeable: lastActiveTaskItem && existsWindowShown && lastActiveTaskItem.isVirtualDesktopsChangeable

    property bool hasDesktopsButton: false
    property bool hasMaximizedButton: false
    property bool hasKeepAboveButton: false

    readonly property bool inPlasmaPanel: latteBridge === null
    readonly property bool inLatte: latteBridge !== null

    readonly property Item lastActiveTaskItem: windowInfoLoader.item.operatingTaskItem
    // END Window properties

    // START decoration properties
    property string currentPlugin: plasmoid.configuration.useCurrentDecoration || !selectedDecorationExists ?
                                       decorations.currentPlugin : plasmoid.configuration.selectedPlugin
    property string currentTheme: plasmoid.configuration.useCurrentDecoration || !selectedDecorationExists ?
                                      decorations.currentTheme : plasmoid.configuration.selectedTheme
    property string currentScheme: {
        if (plasmaThemeExtended.isActive) {
            return plasmaThemeExtended.colors.schemeFile;
        }

        if (enforceLattePalette && plasmoid.configuration.selectedScheme === "kdeglobals") {
            return latteBridge.palette.scheme;
        }

        return plasmoid.configuration.selectedScheme;
    }
    // END decoration properties

    //BEGIN Latte Dock Communicator
    property QtObject latteBridge: null // current Latte v0.9 API

    onLatteBridgeChanged: {
        if (latteBridge) {
            plasmoid.configuration.containmentType = AppletDecoration.Types.Latte;
            latteBridge.actions.setProperty(plasmoid.id, "latteSideColoringEnabled", false);
            latteBridge.actions.setProperty(plasmoid.id, "windowsTrackingEnabled", true);
        }
    }
    //END  Latte Dock Communicator
    //BEGIN Latte based properties
    //!   This applet is a special case and thus the latteBridge.applyPalette is not used.
    //!   the applet relys totally to Latte to paint itself correctly at all cases,
    //!   even when Latte informs the applets that need to use the default plasma theme.
    readonly property bool enforceLattePalette: latteBridge && latteBridge.palette
    readonly property bool latteInEditMode: latteBridge && latteBridge.inEditMode

    //END Latte based properties

    //START Behaviors
    Behavior on animatedMinimumWidth {
        enabled: slideAnimationEnabled && plasmoid.formFactor===PlasmaCore.Types.Horizontal
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }

    Behavior on animatedMinimumHeight {
        enabled: slideAnimationEnabled && plasmoid.formFactor===PlasmaCore.Types.Vertical
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }
    //END Behaviors

    onButtonsStrChanged: initButtons();

    onContainmentTypeChanged: {
        if (containmentType === AppletDecoration.Types.Plasma && disabledMaximizedBorders !== 1) { /*SystemDecision*/
            windowSystem.setDisabledMaximizedBorders(disabledMaximizedBorders);
        }
    }

    onCurrentSchemeChanged: {
        //! This is needed from some themes e.g. Oxygen in order to paint properly
        //! scheme changes. In the future it must be investigated if it is
        //! Oxygen fault.
        if (currentPlugin === "org.kde.oxygen") {
            initButtons();
        }
    }

    onDisabledMaximizedBordersChanged: {
        if (containmentType === AppletDecoration.Types.Plasma && disabledMaximizedBorders !== 1) { /*SystemDecision*/
            windowSystem.setDisabledMaximizedBorders(disabledMaximizedBorders);
        }
    }

    onExistsWindowActiveChanged: {
        //! This is needed from some themes e.g. Breeze in order to paint properly
        //! active/inactive buttons. In the future it must be investigated if it is
        //! Breeze fault
        if (root.inactiveStateEnabled && (currentPlugin==="org.kde.breeze" || currentPlugin === "org.kde.oxygen")) {
            initButtons();
        }
    }

    Connections{
        target: !auroraeThemeEngine.isEnabled ? root : null
        onThickPaddingChanged: initButtons();
    }

    Connections {
        target: bridgeItem
        onPluginChanged: initButtons();
    }

    Connections {
        target: buttonsRepeater
        onCountChanged: discoverButtons();
    }

    Component.onCompleted: {
        if (plasmoid.configuration.buttons.indexOf("9") === -1) {
            //add new supported buttons if they dont exist in the configuration
            plasmoid.configuration.buttons = plasmoid.configuration.buttons.concat("|9");
        }

        initButtons();
        containmentIdentifierTimer.start();
    }

    property var tasksPreparedArray: []

    ListModel {
        id: controlButtonsModel
    }

    //!
    Loader {
        id: windowInfoLoader
        sourceComponent: latteBridge
                         && latteBridge.windowsTracker
                         && latteBridge.windowsTracker.currentScreen.lastActiveWindow
                         && latteBridge.windowsTracker.allScreens.lastActiveWindow ? latteTrackerComponent : plasmaTasksModel

        Component{
            id: latteTrackerComponent
            LatteWindowsTracker{
                filterByScreen: plasmoid.configuration.filterByScreen
            }
        }

        Component{
            id: plasmaTasksModel
            PlasmaTasksModel{
                filterByScreen: plasmoid.configuration.filterByScreen
            }
        }
    }
    //!


    ///Decoration Items
    AppletDecoration.Bridge {
        id: bridgeItem
        plugin: currentPlugin
        theme: currentTheme
    }

    AppletDecoration.Settings {
        id: settingsItem
        bridge: bridgeItem.bridge
        borderSizesIndex: 0 // Normal
    }

    AppletDecoration.SharedDecoration {
        id: sharedDecorationItem
        bridge: bridgeItem.bridge
        settings: settingsItem
    }

    AppletDecoration.DecorationsModel {
        id: decorations
    }

    AppletDecoration.PlasmaThemeExtended {
        id: plasmaThemeExtended

        readonly property bool isActive: plasmoid.configuration.selectedScheme === "_plasmatheme_"

        function triggerUpdate() {
            if (isActive) {
                initButtons();
            }
        }

        onThemeChanged: triggerUpdate();
        onColorsChanged: triggerUpdate();
    }

    AppletDecoration.AuroraeTheme {
        id: auroraeThemeEngine
        theme: isEnabled ? currentTheme : ""

        readonly property bool isEnabled: decorations.isAurorae(currentPlugin, currentTheme);
    }

    AppletDecoration.WindowSystem {
        id: windowSystem
    }

    ///functions
    function initButtons() {
        if (!buttonsRecreator.running){
            buttonsRecreator.start();
        }
    }

    function initializeControlButtonsModel() {
        console.log("recreating buttons");
        sharedDecorationItem.createDecoration();

        var buttonsList = buttonsStr.split('|');

        ModelTools.initializeControlButtonsModel(buttonsList, tasksPreparedArray, controlButtonsModel, true);
    }

    function discoverButtons() {
        var hasMax = false;
        var hasPin = false;
        var hasKeepAbove = false;

        for (var i=0; i<tasksPreparedArray.length; ++i) {
            if (tasksPreparedArray[i].buttonType === AppletDecoration.Types.Maximize) {
                hasMax = true;
            } else if (tasksPreparedArray[i].buttonType === AppletDecoration.Types.OnAllDesktops) {
                hasPin = true;
            } else if (tasksPreparedArray[i].buttonType === AppletDecoration.Types.KeepAbove) {
                hasKeepAbove = true;
            }
        }

        hasMaximizedButton = hasMax;
        hasDesktopsButton = hasPin;
        hasKeepAboveButton = hasKeepAbove;
    }

    function performActiveWindowAction(windowOperation) {
        if (windowOperation === AppletDecoration.Types.ActionClose) {
            windowInfoLoader.item.toggleClose();
        } else if (windowOperation === AppletDecoration.Types.ToggleMaximize) {
            windowInfoLoader.item.toggleMaximized();
        } else if (windowOperation === AppletDecoration.Types.ToggleMinimize) {
            windowInfoLoader.item.toggleMinimized();
        } else if (windowOperation === AppletDecoration.Types.TogglePinToAllDesktops) {
            windowInfoLoader.item.togglePinToAllDesktops();
        } else if (windowOperation === AppletDecoration.Types.ToggleKeepAbove){
            windowInfoLoader.item.toggleKeepAbove();
        }
    }

    ///START Visual Items

    Grid {
        id: buttonsArea

        rowSpacing: 0
        columnSpacing: 0

        rows: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 1 : 0
        columns: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? 0 : 1

        readonly property int buttonThickness: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                                                   root.height - 2 * thickPadding :
                                                   root.width - 2 * thickPadding

        onButtonThicknessChanged: console.log("Window Buttons Applet :: Button Thickness ::: " + buttonThickness);

        opacity: emptySpaceEnabled && mustHide && !inEditMode ? 0 : 1
        visible: opacity === 0 ? false : true

        Behavior on opacity {
            enabled: emptySpaceEnabled
            NumberAnimation {
                duration: 250
                easing.type: Easing.InCubic
            }
        }

        Repeater {
            id: buttonsRepeater
            model: controlButtonsModel
            delegate: auroraeThemeEngine.isEnabled ? auroraeButton : pluginButton
        }
    }

    Component {
        id: pluginButton
        AppletDecoration.Button {
            id: cButton
            width: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                       buttonsArea.buttonThickness + padding.left + padding.right :
                       buttonsArea.buttonThickness + 2 * thickPadding

            height: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                        buttonsArea.buttonThickness + 2 * thickPadding :
                        buttonsArea.buttonThickness + padding.top + padding.bottom


            bridge: bridgeItem.bridge
            sharedDecoration: sharedDecorationItem
            scheme: root.currentScheme
            type: buttonType

            isActive: {
                //!   FIXME-TEST PERIOD: Disabled because it shows an error from c++ theme when its value is changed
                //!   and breaks in some cases the buttons coloring through the schemeFile
                if (root.inactiveStateEnabled && !root.existsWindowActive){
                    return false;
                }

                return true;
            }
            isOnAllDesktops: root.isLastActiveWindowPinned
            isMaximized: root.isLastActiveWindowMaximized
            isKeepAbove: root.isLastActiveWindowKeepAbove

            localX: x
            localY: y

            visible: {
                if (visibility === AppletDecoration.Types.AlwaysVisible || inEditMode) {
                    return true;
                }

                if (type === AppletDecoration.Types.Close) {
                    return root.isLastActiveWindowClosable;
                } else if (type === AppletDecoration.Types.Maximize) {
                    return root.isLastActiveWindowMaximizable;
                } else if (type === AppletDecoration.Types.Minimize) {
                    return root.isLastActiveWindowMinimizable;
                } else if (type === AppletDecoration.Types.OnAllDesktops) {
                    return root.isLastActiveWindowVirtualDesktopsChangeable;
                }

                return true;
            }


            readonly property int firstPadding: {
                if (index === 0) {
                    //! first button
                    return lengthFirstMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            readonly property int lastPadding: {
                if (index>=0 && index === buttonsRepeater.count - 1) {
                    //! last button
                    return lengthLastMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            padding{
                left: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? firstPadding : thickPadding
                right: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? lastPadding : thickPadding
                top: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : firstPadding
                bottom: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : lastPadding
            }

            onClicked: {
                root.performActiveWindowAction(windowOperation);
            }

            /*Rectangle{
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "red"
            }

            Rectangle{
                x: cButton.padding.left
                y: cButton.padding.top
                width: cButton.width - cButton.padding.left - cButton.padding.right
                height: cButton.height - cButton.padding.top - cButton.padding.bottom

                color: "transparent"
                border.width: 1
                border.color: "blue"
            }*/
        }
    }

    Component {
        id: auroraeButton
        AppletDecoration.AuroraeButton {
            id: aButton
            width: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                       auroraeTheme.buttonRatio*buttonsArea.buttonThickness + leftPadding + rightPadding :
                       buttonsArea.buttonThickness + 2 * thickPadding

            height: plasmoid.formFactor === PlasmaCore.Types.Horizontal ?
                        buttonsArea.buttonThickness + 2 * thickPadding :
                        buttonsArea.buttonThickness + topPadding + bottomPadding

            readonly property int firstPadding: {
                if (index === 0) {
                    //! first button
                    return lengthFirstMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            readonly property int lastPadding: {
                if (index>=0 && index === buttonsRepeater.count - 1) {
                    //! last button
                    return lengthLastMargin;
                } else {
                    return lengthMidPadding;
                }
            }

            leftPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? firstPadding : thickPadding
            rightPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? lastPadding : thickPadding
            topPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : firstPadding
            bottomPadding: plasmoid.formFactor === PlasmaCore.Types.Horizontal ? thickPadding : lastPadding

            isActive: {
                //!   FIXME-TEST PERIOD: Disabled because it shows an error from c++ theme when its value is changed
                //!   and breaks in some cases the buttons coloring through the schemeFile
                if (root.inactiveStateEnabled && !root.existsWindowActive){
                    return false;
                }

                return true;
            }
            isOnAllDesktops: root.isLastActiveWindowPinned
            isMaximized: root.isLastActiveWindowMaximized
            isKeepAbove: root.isLastActiveWindowKeepAbove
            buttonType: model.buttonType
            auroraeTheme: auroraeThemeEngine

            monochromeIconsEnabled: latteBridge && latteBridge.applyPalette && auroraeThemeEngine.hasMonochromeIcons
            monochromeIconsColor: latteBridge ? latteBridge.palette.textColor : "transparent"

            visible: {
                if (visibility === AppletDecoration.Types.AlwaysVisible || inEditMode) {
                    return true;
                }

                if (buttonType === AppletDecoration.Types.Close) {
                    return root.isLastActiveWindowClosable;
                } else if (buttonType === AppletDecoration.Types.Maximize) {
                    return root.isLastActiveWindowMaximizable;
                } else if (buttonType === AppletDecoration.Types.Minimize) {
                    return root.isLastActiveWindowMinimizable;
                } else if (buttonType === AppletDecoration.Types.OnAllDesktops) {
                    return root.isLastActiveWindowVirtualDesktopsChangeable;
                }

                return true;
            }

            onClicked: {
                root.performActiveWindowAction(windowOperation);
            }

            /*  Rectangle{
                anchors.fill: parent
                color: "transparent"
                border.width: 1
                border.color: "red"
            }

            Rectangle{
                x: aButton.leftPadding
                y: aButton.topPadding
                width: aButton.width - aButton.leftPadding - aButton.rightPadding
                height: aButton.height - aButton.topPadding - aButton.bottomPadding

                color: "transparent"
                border.width: 1
                border.color: "blue"
            } */
        }
    }
    ///END Visual Items

    //! this timer is used in order to not call too many times the recreation
    //! of buttons with no reason.
    Timer{
        id: buttonsRecreator
        interval: 200
        onTriggered: initializeControlButtonsModel();
    }

    //! this timer is used in order to identify in which containment the applet is in
    //! it should be called only the first time an applet is created and loaded because
    //! afterwards the applet has no way to move between different processes such
    //! as Plasma and Latte
    Timer{
        id: containmentIdentifierTimer
        interval: 5000
        onTriggered: {
            if (latteBridge) {
                plasmoid.configuration.containmentType = AppletDecoration.Types.Latte;
            } else {
                plasmoid.configuration.containmentType = AppletDecoration.Types.Plasma;
            }
        }
    }
}
