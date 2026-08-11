import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.overlay.controls 1.0

// in this i decided to use root.ctrl because i thought it was necessary for rectangles but thats not true. mistake.
Rectangle {
    id: root
     focus: true // allows the root window to recieve keyboard events
    anchors.fill: parent
    color: "#0F1113"

    readonly property color accent: "#00AEEF"
    readonly property color panelColor: "#17191C"
    readonly property color idleColor: "#17191C"
    readonly property color borderColor: "#2D3238"
    readonly property color outlineColor: "#2D3238"
    readonly property color textColor: "#FFFFFF"
    readonly property color subText: "#7C848E"
    readonly property string mainFont: "Montserrat"

    readonly property var ctrl: ControllerBridge

    //
    property int updateCounter: 0
    property bool listening: false // false: not waiting for input, true: waiting for user to press a button
    property int currentAction: -1 // nothing is currently beingw remapped. if we map Action_A it would be currentAction = Action_A

    property string pendingProfileName: ""

    function beginMapping(action) {
        listening = true // firstly we say listening is true. Now the UI knows aswell and says "Waiting for input"
        currentAction = action // eg if action = Action_A, then currentAction = Action_A
        // this is checking two things:
        // Firstly, does ctrl exist?
        // Secondly, does this functionr really exist? typeof will return "function" if it is a function and undefined if it isnt. its JS
        if (root.ctrl && typeof root.ctrl.beginRemap === "function") {
            root.ctrl.beginRemap(action)
        }
    }

    function cancelMapping() {
        listening = false
        currentAction = -1
        if (root.ctrl && typeof root.ctrl.cancelRemap === "function") {
            root.ctrl.cancelRemap()
        }
    }
    component SectionTitle : Text {
        color: subText
        font.family: mainFont
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 1.2
    }

    component MapButton : Button {
            property string label: "" // what action is on the ui
            property int controllerAction: -1 // what action it represents.
            property string fallbackValue: "None"
            activeFocusOnTab: false // Prevents the button from holding focus loops

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Space) {
                    event.accepted = true; // Stops QML from treating Space as a click
                }
            }

            // Dynamically bind to the cpp mapping name and auto refresh
            property string value: {
                var dummy = root.updateCounter // Forces evaluation on mapping change
                return (root.ctrl && controllerAction !== -1)
                    ? root.ctrl.getActionMappingName(controllerAction)
                    : fallbackValue
                /* ^ this is just
                if(root.ctrl && controllerAction != -1)
                return root.ctrl.getActionMappingName(controllerAction);
                else
                return fallbackValue;

                Example
                suppose controllerAction = Action_A it calls getActionMappingName(Action_A) which might return "A" or "B" or whatever depending
                on what they mapped
            */
            }

            implicitWidth: 90
            implicitHeight: 40

            onClicked: {
                if (controllerAction === -1)
                    return;

                if (root.listening) {
                    if (root.currentAction === controllerAction)
                        root.cancelMapping();
                    return;
                }

                root.beginMapping(controllerAction);
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (controllerAction !== -1 && root.ctrl) {
                                // FORCE cancel listening state in both QML and C++ first
                                if (root.listening) {
                                    root.cancelMapping();
                                }

                                // Clear the action in C++ (sets to -1 / None)
                                root.ctrl.clearAction(controllerAction);
                            }
                        } else if (mouse.button === Qt.LeftButton) {
                            if (controllerAction === -1)
                                return;

                            if (root.listening) {
                                if (root.currentAction === controllerAction) {
                                    root.cancelMapping();
                                }
                                return;
                            }

                            root.beginMapping(controllerAction);
                        }
                    }
            }

            background: Rectangle { // replace the default button background
                radius: 6
                color: { // binding
                    // this means "this is the button currently being remapped
                    if (root.listening && controllerAction !== -1 && root.currentAction === controllerAction)
                        return "#3A2B00"
                    if (parent.hovered) {
                        return "#23272D"
                    }
                    return "#15181B"
                }
                border.width: 1
                border.color: {
                    if (root.listening && controllerAction !== -1 && root.currentAction === controllerAction)
                        return "#FFB000"
                    if (parent.hovered) // if theyve just hovered.
                        return accent
                        return borderColor
                }
            }

            contentItem: Column {
                anchors.centerIn: parent
                spacing: 2

                Text { // this text doesnt change
                    text: label
                    color: "#777"
                    font.pixelSize: 9
                    font.bold: true
                    font.family: mainFont
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                Text { // this text changes. normally it would be eg A, during remapping "Listening.."
                    text: (root.listening && controllerAction !== -1 && root.currentAction === controllerAction)
                          ? "Listening..."
                          : value
                    color: (root.listening && controllerAction !== -1 && root.currentAction === controllerAction)
                           ? "#FFB000"
                           : "white" // normally white during remapping gold
                    font.pixelSize: 10
                    font.family: mainFont
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }
            }
        }
    // States and signals listener to update ui properties and stuff
    // essentially in cpp that were like emit controllerUpdated() or other signals.
    // This says that whenever ControllerBridge emits one of those signals run thees functions
    Connections {
        target: root.ctrl
        ignoreUnknownSignals: true
            // this runs with the controllerUpdated() signal in cpp. when we do like emit controllerUpdated itll do this
        // its a naming convention kind of thing really. the signals will prepend with "on"
        function onControllerUpdated() {
            root.updateCounter++ // Now that previous binding that we had with "property string value", this is what it binds to. its a dummy value.
            if (!root.ctrl) return; // if for some reason the cpp isnt available then dont crash.
            controllerPreview.leftTrigger = root.ctrl.getActionAxis(ControllerBridge.Action_LeftTrigger)
            controllerPreview.buttonLBPressed = root.ctrl.isActionPressed(ControllerBridge.Action_L_Shoulder)
            controllerPreview.leftStickX = root.ctrl.getActionAxis(ControllerBridge.Action_LeftStickX)
            controllerPreview.leftStickY = root.ctrl.getActionAxis(ControllerBridge.Action_LeftStickY)
            controllerPreview.leftStickPressed = root.ctrl.isActionPressed(ControllerBridge.Action_LeftStickClick)

            controllerPreview.dpadUp = root.ctrl.isActionPressed(ControllerBridge.Action_DPadUp)
            controllerPreview.dpadDown = root.ctrl.isActionPressed(ControllerBridge.Action_DPadDown)
            controllerPreview.dpadLeft = root.ctrl.isActionPressed(ControllerBridge.Action_DPadLeft)
            controllerPreview.dpadRight = root.ctrl.isActionPressed(ControllerBridge.Action_DPadRight)

            controllerPreview.rightTrigger = root.ctrl.getActionAxis(ControllerBridge.Action_RightTrigger)
            controllerPreview.buttonRBPressed = root.ctrl.isActionPressed(ControllerBridge.Action_R_Shoulder)
            controllerPreview.buttonYPressed = root.ctrl.isActionPressed(ControllerBridge.Action_Y)
            controllerPreview.buttonXPressed = root.ctrl.isActionPressed(ControllerBridge.Action_X)
            controllerPreview.buttonBPressed = root.ctrl.isActionPressed(ControllerBridge.Action_B)
            controllerPreview.buttonAPressed = root.ctrl.isActionPressed(ControllerBridge.Action_A)
            controllerPreview.rightStickX = root.ctrl.getActionAxis(ControllerBridge.Action_RightStickX)
            controllerPreview.rightStickY = root.ctrl.getActionAxis(ControllerBridge.Action_RightStickY)
            controllerPreview.rightStickPressed = root.ctrl.isActionPressed(ControllerBridge.Action_RightStickClick)
        }

        // when we emit remapFinished()
        function onRemapFinished() {
                listening = false     // <--- Set directly
                currentAction = -1    // <--- Set directly
            }

        // when a profile load fails (e.g. stale name, file deleted outside the app)
        function onProfileLoadFailed(name) {
                console.log("Failed to load profile:", name)
                root.updateCounter++ // force the combo box back to reflect the real currentProfileName/model
            }

    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20 // 20 pixels from like the edges basically
        spacing: 20 // child spacing

        // Header
        RowLayout { // everything is placed left to right
            Layout.fillWidth: true
            spacing: 15
            ColumnLayout {
                spacing: 2
                Text {
                    text: "INPUT CONFIGURATION"
                    color: textColor
                    font.family: mainFont
                    font.pixelSize: 18
                    font.bold: true
                }
                Text {
                    text: listening ? "Press any controller button, keyboard, or move a stick..." : "Select a control to remap."
                    color: listening ? "#FFB000" : subText
                    font.family: mainFont
                    font.pixelSize: 11
                }
            }
            Item { Layout.fillWidth: true } // Basically this has nothing but takes up the remaining space in a way
            ComboBox {
                    id: profileCombo
                    model: {
                        var dummy = root.updateCounter
                        return ctrl.getAvailableProfiles()
                    }
                    // Use a binding so it always tracks the active profile automatically
                    currentIndex: {
                            var dummy = root.updateCounter
                            let profiles = ctrl.getAvailableProfiles()
                            let idx = profiles.indexOf(ctrl.currentProfileName)
                            // If found, use its index. Otherwise, default to index 0 ("Default") if available.
                            return idx !== -1 ? idx : (profiles.length > 0 ? 0 : -1)
                        }

                    Keys.onPressed: function(event) {
                        event.accepted = true;
                    }

                    onActivated: function(index) {
                        let targetProfile = currentText
                        if (targetProfile === ctrl.currentProfileName) return

                        // FIX: Clear listening state properly
                        root.listening = false
                        root.currentAction = -1
                        if (root.ctrl) root.ctrl.cancelRemap()

                        if (ctrl.hasUnsavedChanges) {
                            pendingProfileName = targetProfile
                            currentIndex = Qt.binding(function() {
                                let profiles = ctrl.getAvailableProfiles()
                                let idx = profiles.indexOf(ctrl.currentProfileName)
                                return idx !== -1 ? idx : 0
                            })
                            unsavedChangesDialog.open()
                        } else {
                            ctrl.loadProfile(targetProfile)
                        }
                    }
                }
                Button {
                    text: "New"
                    onClicked: newProfileDialog.open()
                }

                Button {
                    text: "Delete"
                    // FIX: Disable if only 1 profile remains, or if the current selection is "default"
                    enabled: profileCombo.count > 1 && profileCombo.currentText.toLowerCase() !== "default"
                    opacity: enabled ? 1.0 : 0.5
                    onClicked: {
                            // FIX: Clear listening state properly
                            root.listening = false
                            root.currentAction = -1
                            if (root.ctrl) root.ctrl.cancelRemap()

                            ctrl.deleteProfile(profileCombo.currentText)
                        }
                }
            RowLayout {
                spacing: 6
            Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: ctrl.deviceConnected ? "#2ECC71" : "#E81123"
                }

                // Dynamic text reflecting connection status
                Text {
                    text: ctrl.deviceConnected ? "Controller Connected" : "No Device Connected"
                    color: "#FFFFFF"
                    font.pixelSize: 12
                    font.family: "Segoe UI"
                    anchors.verticalCenter: parent.verticalCenter
                }
        }
        }
    // so essentially if you see sum like Item { Layout.preferredHeight: something } its a spacer really
        // Main Content (Centered)
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // LEFT SIDE
            ColumnLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                SectionTitle { text: "LEFT STICK" }
                GridLayout {
                    columns: 3
                    rowSpacing: 6; columnSpacing: 6
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "UP"
                        fallbackValue: "Axis Y-"
                        controllerAction: ControllerBridge.Action_LeftStickY_Neg
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "LEFT"
                        fallbackValue: "Axis X-"
                        controllerAction: ControllerBridge.Action_LeftStickX_Neg
                    }
                    MapButton {
                        label: "CLICK"
                        fallbackValue: "L3"
                        controllerAction: ControllerBridge.Action_LeftStickClick
                    }
                    MapButton {
                        label: "RIGHT"
                        fallbackValue: "Axis X+"
                        controllerAction: ControllerBridge.Action_LeftStickX_Pos
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "DOWN"
                        fallbackValue: "Axis Y+"
                        controllerAction: ControllerBridge.Action_LeftStickY_Pos
                    }
                    Item { Layout.preferredWidth: 90 }
                }

                Item { Layout.preferredHeight: 20 }

                SectionTitle { text: "D-PAD" }
                GridLayout {
                    columns: 3
                    rowSpacing: 6; columnSpacing: 6
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "UP"
                        fallbackValue: "D-Up"
                        controllerAction: ControllerBridge.Action_DPadUp
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "LEFT"
                        fallbackValue: "D-Left"
                        controllerAction: ControllerBridge.Action_DPadLeft
                    }
                    // FIX: Replaced "CENTER" with a blank spacer item
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "RIGHT"
                        fallbackValue: "D-Right"
                        controllerAction: ControllerBridge.Action_DPadRight
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "DOWN"
                        fallbackValue: "D-Down"
                        controllerAction: ControllerBridge.Action_DPadDown
                    }
                    Item { Layout.preferredWidth: 90 }
                }
            }

            Item { Layout.fillWidth: true }

            // CENTER PREVIEW & HOME BUTTON
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                spacing: 15

                // home btn above the controller preview
                MapButton {
                    label: "HOME"
                    fallbackValue: "Home"
                    controllerAction: ControllerBridge.Action_Home
                    Layout.alignment: Qt.AlignHCenter
                }

                ControllerPreview {
                    id: controllerPreview
                    Layout.preferredWidth: 380
                    Layout.preferredHeight: 300
                }
            }

            Item { Layout.fillWidth: true }

            // RIGHT SIDE
            ColumnLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                SectionTitle { text: "FACE BUTTONS" }
                GridLayout {
                    columns: 3
                    rowSpacing: 6; columnSpacing: 6
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "X"
                        fallbackValue: "Button X"
                        controllerAction: ControllerBridge.Action_X
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "Y"
                        fallbackValue: "Button Y"
                        controllerAction: ControllerBridge.Action_Y
                    }

                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "A"
                        fallbackValue: "Button A"
                        controllerAction: ControllerBridge.Action_A
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "B"
                        fallbackValue: "Button B"
                        controllerAction: ControllerBridge.Action_B
                    }
                    Item { Layout.preferredWidth: 90 }
                }

                Item { Layout.preferredHeight: 20 }

                SectionTitle { text: "RIGHT STICK" }
                GridLayout {
                    columns: 3
                    rowSpacing: 6; columnSpacing: 6
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "UP"
                        fallbackValue: "Axis Y-"
                        controllerAction: ControllerBridge.Action_RightStickY_Neg
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "LEFT"
                        fallbackValue: "Axis X-"
                        controllerAction: ControllerBridge.Action_RightStickX_Neg
                    }
                    MapButton {
                        label: "CLICK"
                        fallbackValue: "R3"
                        controllerAction: ControllerBridge.Action_RightStickClick
                    }
                    MapButton {
                        label: "RIGHT"
                        fallbackValue: "Axis X+"
                        controllerAction: ControllerBridge.Action_RightStickX_Pos
                    }
                    Item { Layout.preferredWidth: 90 }
                    MapButton {
                        label: "DOWN"
                        fallbackValue: "Axis Y+"
                        controllerAction: ControllerBridge.Action_RightStickY_Pos
                    }
                    Item { Layout.preferredWidth: 90 }
                }
            }
        }

        // FOOTER
        // Also restore defaults restores it to the nintendo layout
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: 10

            Button {
                text: "Restore Defaults"
                onClicked: {
                    if (root.ctrl) root.ctrl.restoreDefaults()
                }
            }



            Item { Layout.fillWidth: true }

            // Shoulder / Trigger Mapping Buttons
            RowLayout {
                spacing: 6
                MapButton {
                    label: "L"
                    fallbackValue: "Button 4"
                    controllerAction: ControllerBridge.Action_L_Shoulder
                    implicitWidth: 55; implicitHeight: 36
                }
                MapButton {
                    label: "ZL"
                    fallbackValue: "Axis 2"
                    controllerAction: ControllerBridge.Action_LeftTrigger
                    implicitWidth: 55; implicitHeight: 36
                }
                MapButton {
                    label: "R"
                    fallbackValue: "Button 5"
                    controllerAction: ControllerBridge.Action_R_Shoulder
                    implicitWidth: 55; implicitHeight: 36
                }
                MapButton {
                    label: "ZR"
                    fallbackValue: "Axis 5"
                    controllerAction: ControllerBridge.Action_RightTrigger
                    implicitWidth: 55; implicitHeight: 36
                }
            }

            Item { Layout.fillWidth: true }
            Button {
                id: saveButton
                text: ctrl.hasUnsavedChanges ? "Save Configuration *" : "Save Configuration"
                implicitWidth: 170; implicitHeight: 40
                background: Rectangle {
                    radius: 6
                    color: ctrl.hasUnsavedChanges ? "#FFB000" : (saveButton.hovered ? "#15B8F5" : accent)
                }
                contentItem: Text {
                    text: saveButton.text
                    color: ctrl.hasUnsavedChanges ? "black" : "white"
                    font.family: mainFont
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (root.listening) {
                        root.cancelMapping()
                    }
                    if (root.ctrl) {
                        // Previously this manually built "profiles/" + currentProfileName + ".ini"
                        // and called saveMappingConfig() directly, which saved to the right
                        // place but never cleared hasUnsavedChanges (that flag is only reset by
                        // saveCurrentProfile()). Calling saveCurrentProfile() does both correctly,
                        // and matches how KeyboardBridge's Save Configuration button now works.
                        root.ctrl.saveCurrentProfile()
                    }
                }
            }
        }
    }
    Dialog {
            id: newProfileDialog
            modal: true
            focus: true
            anchors.centerIn: parent
            implicitWidth: 320

            enter: Transition {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            }
            exit: Transition {
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; from: 1.0; to: 0.85; duration: 120; easing.type: Easing.InCubic }
            }

            background: Rectangle {
                color: panelColor
                border.color: borderColor
                border.width: 1
                radius: 8
            }

            contentItem: Item {
                implicitWidth: layout.implicitWidth + 32
                implicitHeight: layout.implicitHeight + 32

                ColumnLayout {
                    id: layout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    Text {
                        text: "Create New Profile"
                        color: textColor
                        font.family: mainFont
                        font.pixelSize: 14
                        font.bold: true
                    }

                    TextField {
                        id: profileNameInput
                        placeholderText: "Enter profile name..."
                        Layout.fillWidth: true
                        font.family: mainFont
                        color: textColor
                        placeholderTextColor: subText
                        background: Rectangle {
                            color: "#0F1113"
                            border.color: profileNameInput.activeFocus ? accent : borderColor
                            border.width: 1
                            radius: 6
                        }
                    }

                    // Duplicate / Error warning text
                    Text {
                        id: errorText
                        text: "Duplicate name. Please try again."
                        color: "#FF5555"
                        font.family: mainFont
                        font.pixelSize: 11
                        visible: {
                            let name = profileNameInput.text.trim()
                            if (name === "") return false
                            let profiles = ctrl.getAvailableProfiles()
                            return profiles.includes(name)
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 4
                        spacing: 10

                        Button {
                            text: "Cancel"
                            onClicked: {
                                profileNameInput.text = ""
                                newProfileDialog.close()
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#23272D" : "#15181B"
                                border.color: borderColor
                                border.width: 1
                                radius: 6
                            }
                            contentItem: Text {
                                text: parent.text
                                color: subText
                                font.family: mainFont
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Button {
                            text: "Save"
                            enabled: !errorText.visible && profileNameInput.text.trim() !== ""
                            opacity: enabled ? 1.0 : 0.5
                            onClicked: {
                                    let name = profileNameInput.text.trim()
                                    if (name !== "") {
                                        // FIX: Clear listening state properly
                                        root.listening = false
                                        root.currentAction = -1
                                        if (root.ctrl) root.ctrl.cancelRemap()

                                        ctrl.createProfile(name)
                                        profileNameInput.text = ""
                                        newProfileDialog.close()
                                    }
                                }
                            background: Rectangle {
                                color: parent.hovered ? "#15B8F5" : accent
                                radius: 6
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font.family: mainFont
                                font.bold: true
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    Dialog {
            id: unsavedChangesDialog
            modal: true
            focus: true
            anchors.centerIn: parent
            implicitWidth: 360

            enter: Transition {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            }
            exit: Transition {
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
                NumberAnimation { property: "scale"; from: 1.0; to: 0.85; duration: 120; easing.type: Easing.InCubic }
            }

            background: Rectangle {
                color: panelColor
                border.color: borderColor
                border.width: 1
                radius: 8
            }

            contentItem: Item {
                implicitWidth: layoutUnsaved.implicitWidth + 32
                implicitHeight: layoutUnsaved.implicitHeight + 32

                ColumnLayout {
                    id: layoutUnsaved
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 16

                    Text {
                        text: "Unsaved Changes"
                        color: textColor
                        font.family: mainFont
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Text {
                        text: "You have unsaved changes in your current profile. Would you like to save them before switching?"
                        color: subText
                        font.family: mainFont
                        font.pixelSize: 12
                        Layout.maximumWidth: 300
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        Layout.topMargin: 4
                        spacing: 8

                        // 1. Cancel Button (Abort switch entirely)
                        Button {
                            text: "Cancel"
                            onClicked: {
                                pendingProfileName = ""
                                unsavedChangesDialog.close()
                            }
                            background: Rectangle {
                                color: parent.hovered ? "#23272D" : "#15181B"
                                border.color: borderColor
                                border.width: 1
                                radius: 6
                            }
                            contentItem: Text {
                                text: parent.text
                                color: subText
                                font.family: mainFont
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // 2. Discard Button (Throw away changes and switch)
                        Button {
                            text: "Discard"
                            onClicked: {
                                    let target = pendingProfileName
                                    pendingProfileName = ""
                                    unsavedChangesDialog.close()

                                    // Reset listening state properly for MappingPage
                                    root.listening = false
                                    root.currentAction = -1
                                    if (root.ctrl) root.ctrl.cancelRemap()

                                    ctrl.loadProfile(target)
                                }
                            background: Rectangle {
                                color: parent.hovered ? "#3A1F1F" : "#2A1515"
                                border.color: "#FF5555"
                                border.width: 1
                                radius: 6
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "#FF8888"
                                font.family: mainFont
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // 3. Save Button (Save changes, then switch)
                                            Button {
                                                text: "Save Changes"
                                                onClicked: {
                                                        ctrl.saveCurrentProfile() // C++ handles saving and automatically sets hasUnsavedChanges = false
                                                        let target = pendingProfileName
                                                        pendingProfileName = ""
                                                        unsavedChangesDialog.close()
                                                        ctrl.loadProfile(target)
                                                    }
                                                background: Rectangle {
                                                    color: parent.hovered ? "#15B8F5" : accent
                                                    radius: 6
                                                }
                                                contentItem: Text {
                                                    text: parent.text
                                                    color: "white"
                                                    font.family: mainFont
                                                    font.bold: true
                                                    font.pixelSize: 11
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                            }
                    }
                }
            }
        }
}
