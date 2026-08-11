import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import com.overlay.controls 1.0

Rectangle {
    id: root
    focus: false
    activeFocusOnTab: false
    anchors.fill: parent
    color: "#0F1113"

    property string activeKeyId: ""
    property string activeKeyLabel: activeKeyId.replace("Left", "").replace("Right", "")

    // Theme properties for dialog and UI consistency
    property string mainFont: "Montserrat"
    property color panelColor: "#181A1F"
    property color borderColor: "#333"
    property color accent: "#15B8F5"
    property color subText: "#888888"
    property color textColor: "white"

    property int updateCounter: 0
    property string pendingProfileName: ""


    // Connect to global remap signal from C++ for physical keys
        Connections {
            target: KeyboardBridge
            function onKeyPressedForRemap(pressedQtKey) {
                if (KeyboardBridge.isListening && KeyboardBridge.activeQtKey !== 0 && root.activeKeyId !== "") {
                    // Check if the pressed input is a controller button/action range (0x5000 to 0x5020)
                    if (pressedQtKey >= 0x5000 && pressedQtKey <= 0x5020) {
                        let actionIndex = pressedQtKey - 0x5000;
                        // Bind key to controller action and clear any keyboard remapping conflict
                        KeyboardBridge.setControllerKeyMapping(KeyboardBridge.activeQtKey, actionIndex);
                        KeyboardBridge.setKeyMapping(KeyboardBridge.activeQtKey, KeyboardBridge.activeQtKey);
                    } else {
                        // Regular keyboard remapping: set keyboard map and clear any controller binding
                        KeyboardBridge.setKeyMapping(KeyboardBridge.activeQtKey, pressedQtKey);
                        KeyboardBridge.setControllerKeyMapping(KeyboardBridge.activeQtKey, -1);
                    }

                    KeyboardBridge.isListening = false;
                    root.activeKeyId = "";
                    KeyboardBridge.activeQtKey = 0;
                }
            }
            function onKeyboardUpdated() {
                root.updateCounter++
            }
        }

    component KeyboardKey : Rectangle {
        id: keyRoot
        property string label: ""
        property string keyId: label
        property real unitWidth: 1.0
        property bool isListening: KeyboardBridge.isListening && root.activeKeyId === label

        function getQtKey(id) {
            switch(id) {
                case "LMB": return 0x0201;
                case "RMB": return 0x0202;
                case "Mouse 3": return 0x0203;
                case "Mouse 4": return 0x0204;
                case "Mouse 5": return 0x0205;

                case "LeftShift":  return 0x1101;
                case "RightShift": return 0x1102;
                case "LeftCtrl":   return 0x1103;
                case "RightCtrl":  return 0x1104;
                case "LeftAlt":    return 0x1105;
                case "RightAlt":   return 0x1106;

                case "`": return Qt.Key_QuoteLeft;
                case "1": return Qt.Key_1; case "2": return Qt.Key_2; case "3": return Qt.Key_3;
                case "4": return Qt.Key_4; case "5": return Qt.Key_5; case "6": return Qt.Key_6;
                case "7": return Qt.Key_7; case "8": return Qt.Key_8; case "9": return Qt.Key_9;
                case "0": return Qt.Key_0; case "-": return Qt.Key_Minus; case "=": return Qt.Key_Equal;
                case "Backspace": return Qt.Key_Backspace; case "Tab": return Qt.Key_Tab;
                case "Q": return Qt.Key_Q; case "W": return Qt.Key_W; case "E": return Qt.Key_E;
                case "R": return Qt.Key_R; case "T": return Qt.Key_T; case "Y": return Qt.Key_Y;
                case "U": return Qt.Key_U; case "I": return Qt.Key_I; case "O": return Qt.Key_O;
                case "P": return Qt.Key_P; case "[": return Qt.Key_BracketLeft; case "]": return Qt.Key_BracketRight;
                case "\\": return Qt.Key_Backslash; case "Caps": return Qt.Key_CapsLock;
                case "A": return Qt.Key_A; case "S": return Qt.Key_S; case "D": return Qt.Key_D;
                case "F": return Qt.Key_F; case "G": return Qt.Key_G; case "H": return Qt.Key_H;
                case "J": return Qt.Key_J; case "K": return Qt.Key_K; case "L": return Qt.Key_L;
                case ";": return Qt.Key_Semicolon; case "'": return Qt.Key_Apostrophe;
                case "Enter": return Qt.Key_Return;
                case "Z": return Qt.Key_Z; case "X": return Qt.Key_X; case "C": return Qt.Key_C;
                case "V": return Qt.Key_V; case "B": return Qt.Key_B; case "N": return Qt.Key_N;
                case "M": return Qt.Key_M; case ",": return Qt.Key_Comma; case ".": return Qt.Key_Period;
                case "/": return Qt.Key_Slash; case "Win": return Qt.Key_Meta;
                case "Space": return Qt.Key_Space;
                default: return 0;
            }
        }

        function getKeyName(qtKeyCode) {
            if (qtKeyCode === 0) return "Unmapped";

            if (qtKeyCode >= 0x5000 && qtKeyCode <= 0x5020) {
                let btnIndex = qtKeyCode - 0x5000;
                switch(btnIndex) {
                    case 0: return "Gamepad A";
                    case 1: return "Gamepad B";
                    case 2: return "Gamepad X";
                    case 3: return "Gamepad Y";
                    case 4: return "Back";
                    case 6: return "Start";
                    case 9: return "LB";
                    case 10: return "RB";
                    case 11: return "D-Up";
                    case 12: return "D-Down";
                    case 13: return "D-Left";
                    case 14: return "D-Right";
                    default: return "Gamepad " + btnIndex;
                }
            }

            if (qtKeyCode >= Qt.Key_A && qtKeyCode <= Qt.Key_Z) return String.fromCharCode(qtKeyCode);
            if (qtKeyCode >= Qt.Key_0 && qtKeyCode <= Qt.Key_9) return String.fromCharCode(qtKeyCode);
            if (qtKeyCode >= Qt.Key_F1 && qtKeyCode <= Qt.Key_F24) return "F" + (qtKeyCode - Qt.Key_F1 + 1);

            switch(qtKeyCode) {
                case Qt.Key_Space: return "Space";
                case Qt.Key_Meta: return "Win";
                case Qt.Key_Return: return "Enter";
                case Qt.Key_Tab: return "Tab";
                case Qt.Key_Backspace: return "Backspace";
                case Qt.Key_CapsLock: return "Caps Lock";
                case Qt.Key_Escape: return "Esc";
                case Qt.Key_QuoteLeft: return "`";
                case Qt.Key_Minus: return "-";
                case Qt.Key_Equal: return "=";
                case Qt.Key_BracketLeft: return "[";
                case Qt.Key_BracketRight: return "]";
                case Qt.Key_Backslash: return "\\";
                case Qt.Key_Semicolon: return ";";
                case Qt.Key_Apostrophe: return "'";
                case Qt.Key_Comma: return ",";
                case Qt.Key_Period: return ".";
                case Qt.Key_Slash: return "/";
                case 0x1101: return "Left Shift";
                case 0x1102: return "Right Shift";
                case 0x1103: return "Left Ctrl";
                case 0x1104: return "Right Ctrl";
                case 0x1105: return "Left Alt";
                case 0x1106: return "Right Alt";
                case 0x0201: return "LMB";
                case 0x0202: return "RMB";
                case 0x0203: return "Mouse 3";
                case 0x0204: return "Mouse 4";
                case 0x0205: return "Mouse 5";
                default: return "Key " + qtKeyCode;
            }
        }

        function getActionName(actionInt) {
            return "Action " + actionInt;
        }

        property int targetQtKey: getQtKey(keyId)
        property int mappedQtKey: KeyboardBridge.getKeyMapping(targetQtKey)
        property int controllerAction: KeyboardBridge.getControllerKeyMapping(targetQtKey)
        property bool hasControllerMapping: controllerAction !== -1
        property bool isPressed: KeyboardBridge.isKeyPressed(targetQtKey)
        property bool isCustomMapped: (mappedQtKey !== targetQtKey) || hasControllerMapping

        width: unitWidth * 47
        height: 44
        radius: 6

        color: isListening ? "#FFB000" : (isPressed ? "#3a3f4b" : (mouseArea.containsMouse ? "#22252a" : "#1a1a1a"))
        border.color: isListening ? "white" : (isCustomMapped ? "#0e8bc7" : (isPressed ? "#5a6275" : "#333"))
        border.width: isCustomMapped ? 2 : 1

        Text {
            text: parent.label
            color: parent.isListening ? "black" : "white"
            font.family: mainFont
            font.pixelSize: 12
            font.bold: true
            anchors.centerIn: parent
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    // FIX: Reset mapping to targetQtKey so it removes it from m_keyMappings cleanly
                    KeyboardBridge.setKeyMapping(keyRoot.targetQtKey, keyRoot.targetQtKey);

                    // Clear controller action binding
                    KeyboardBridge.setControllerKeyMapping(keyRoot.targetQtKey, -1);

                    if (KeyboardBridge.isListening && root.activeKeyId === parent.keyId) {
                        KeyboardBridge.isListening = false;
                        root.activeKeyId = "";
                        KeyboardBridge.activeQtKey = 0;
                    }
                } else {
                    if (KeyboardBridge.isListening && root.activeKeyId === parent.keyId) {
                        KeyboardBridge.isListening = false;
                        root.activeKeyId = "";
                        KeyboardBridge.activeQtKey = 0;
                    } else {
                        root.activeKeyId = parent.keyId;
                        KeyboardBridge.activeQtKey = keyRoot.targetQtKey;
                        KeyboardBridge.isListening = true;
                    }
                }
            }
        }
        ToolTip {
            id: keyToolTip
            visible: mouseArea.containsMouse && keyRoot.isCustomMapped
            delay: 200
            text: keyRoot.hasControllerMapping
                  ? "Bound to: " + keyRoot.getActionName(keyRoot.controllerAction)
                  : "Mapped to: " + getKeyName(keyRoot.mappedQtKey)

            contentItem: Text {
                text: keyToolTip.text
                color: "#15B8F5"
                font.pixelSize: 11
                font.bold: true
            }

            background: Rectangle {
                color: "#181A1F"
                border.color: "#0e8bc7"
                border.width: 1
                radius: 4
            }
        }

        Connections {
            target: KeyboardBridge
            function onKeyboardUpdated() {
                keyRoot.mappedQtKey = KeyboardBridge.getKeyMapping(keyRoot.targetQtKey)
                keyRoot.controllerAction = KeyboardBridge.getControllerKeyMapping(keyRoot.targetQtKey)
                keyRoot.isPressed = KeyboardBridge.isKeyPressed(keyRoot.targetQtKey)
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 20

        // Header Row containing Title, Description, Profile Controls, and Mouse Toggle
        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Text {
                    text: "Keyboard Mapping"
                    color: "white"
                    font.family: mainFont
                    font.pixelSize: 22
                    font.bold: true
                }
                Text {
                    text: KeyboardBridge.isListening ? "Press physical key or controller button to bind to '" + activeKeyLabel + "'... (Click key again to cancel)" : "Click any key below to modify its binding. Custom mapped keys feature a blue outline. Right click on a key to clear its mapping."
                    color: KeyboardBridge.isListening ? "#FFB000" : "#888888"
                    font.family: mainFont
                    font.pixelSize: 11
                }
            }

            // Profile Controls (Matched exactly to Controller page style)
            RowLayout {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter
                ComboBox {
                    id: keyboardProfileCombo
                    model: {
                        var dummy = root.updateCounter
                        return KeyboardBridge.getAvailableProfiles()
                    }

                    currentIndex: {
                        var dummy = root.updateCounter
                        let profiles = KeyboardBridge.getAvailableProfiles()
                        let idx = profiles.indexOf(KeyboardBridge.currentProfileName)
                        return idx !== -1 ? idx : (profiles.length > 0 ? 0 : -1)
                    }

                    Keys.onPressed: function(event) {
                        event.accepted = true;
                    }

                    onActivated: function(index) {
                        let targetProfile = currentText
                        if (targetProfile === KeyboardBridge.currentProfileName) return

                        if (KeyboardBridge.hasUnsavedChanges || MouseBridge.hasUnsavedChanges) {
                            pendingProfileName = targetProfile
                            currentIndex = Qt.binding(function() {
                                let profiles = KeyboardBridge.getAvailableProfiles()
                                let idx = profiles.indexOf(KeyboardBridge.currentProfileName)
                                return idx !== -1 ? idx : 0
                            })
                            unsavedChangesDialog.open()
                        } else {
                            KeyboardBridge.loadProfile(targetProfile)
                            MouseBridge.loadProfile(targetProfile) // Assuming MouseBridge supports profile loading
                        }
                    }
                }

                Button {
                    text: "New"
                    onClicked: newProfileDialog.open()
                }

                Button {
                    text: "Delete"
                    onClicked: {
                        if (keyboardProfileCombo.count > 1) {
                            KeyboardBridge.deleteProfile(keyboardProfileCombo.currentText)
                        }
                    }
                }
            }

            // Spacing gap between profile controls and mouse toggle
            Item {
                width: 20
            }

            // Far Right: Mouse Toggle Switch / Controls
            Row {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: "Mouse"
                    color: "white"
                    font.family: mainFont
                    font.pixelSize: 14
                    anchors.verticalCenter: mouseToggle.verticalCenter
                }
                Switch {
                    id: mouseToggle
                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Space) {
                            event.accepted = true
                        }
                    }
                    checked: false
                }
            }
        }

        // Side-by-Side View for Keyboard and Mouse
        RowLayout {
            Layout.alignment: Qt.AlignCenter
            spacing: 20

            // Keyboard Layout Container
            Item {
                Layout.preferredWidth: 860
                Layout.preferredHeight: 330

                Rectangle {
                    anchors.fill: parent
                    color: "#121417"
                    radius: 12
                    border.color: "#222"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        // Row 1: Number Row
                        Row {
                            spacing: 6
                            KeyboardKey { label: "`"; unitWidth: 1.0 }
                            KeyboardKey { label: "1"; unitWidth: 1.0 }
                            KeyboardKey { label: "2"; unitWidth: 1.0 }
                            KeyboardKey { label: "3"; unitWidth: 1.0 }
                            KeyboardKey { label: "4"; unitWidth: 1.0 }
                            KeyboardKey { label: "5"; unitWidth: 1.0 }
                            KeyboardKey { label: "6"; unitWidth: 1.0 }
                            KeyboardKey { label: "7"; unitWidth: 1.0 }
                            KeyboardKey { label: "8"; unitWidth: 1.0 }
                            KeyboardKey { label: "9"; unitWidth: 1.0 }
                            KeyboardKey { label: "0"; unitWidth: 1.0 }
                            KeyboardKey { label: "-"; unitWidth: 1.0 }
                            KeyboardKey { label: "="; unitWidth: 1.0 }
                            KeyboardKey { label: "Backspace"; unitWidth: 2.0 }
                        }

                        // Row 2: QWERTY Row
                        Row {
                            spacing: 6
                            KeyboardKey { label: "Tab"; unitWidth: 1.5 }
                            KeyboardKey { label: "Q"; unitWidth: 1.0 }
                            KeyboardKey { label: "W"; unitWidth: 1.0 }
                            KeyboardKey { label: "E"; unitWidth: 1.0 }
                            KeyboardKey { label: "R"; unitWidth: 1.0 }
                            KeyboardKey { label: "T"; unitWidth: 1.0 }
                            KeyboardKey { label: "Y"; unitWidth: 1.0 }
                            KeyboardKey { label: "U"; unitWidth: 1.0 }
                            KeyboardKey { label: "I"; unitWidth: 1.0 }
                            KeyboardKey { label: "O"; unitWidth: 1.0 }
                            KeyboardKey { label: "P"; unitWidth: 1.0 }
                            KeyboardKey { label: "["; unitWidth: 1.0 }
                            KeyboardKey { label: "]"; unitWidth: 1.0 }
                            KeyboardKey { label: "\\"; unitWidth: 1.5 }
                        }

                        // Row 3: Home Row
                        Row {
                            spacing: 6
                            KeyboardKey { label: "Caps"; unitWidth: 1.75 }
                            KeyboardKey { label: "A"; unitWidth: 1.0 }
                            KeyboardKey { label: "S"; unitWidth: 1.0 }
                            KeyboardKey { label: "D"; unitWidth: 1.0 }
                            KeyboardKey { label: "F"; unitWidth: 1.0 }
                            KeyboardKey { label: "G"; unitWidth: 1.0 }
                            KeyboardKey { label: "H"; unitWidth: 1.0 }
                            KeyboardKey { label: "J"; unitWidth: 1.0 }
                            KeyboardKey { label: "K"; unitWidth: 1.0 }
                            KeyboardKey { label: "L"; unitWidth: 1.0 }
                            KeyboardKey { label: ";"; unitWidth: 1.0 }
                            KeyboardKey { label: "'"; unitWidth: 1.0 }
                            KeyboardKey { label: "Enter"; unitWidth: 2.25 }
                        }

                        // Row 4: Bottom Row
                        Row {
                            spacing: 6
                            KeyboardKey { label: "Shift"; keyId: "LeftShift"; unitWidth: 2.25 }
                            KeyboardKey { label: "Z"; unitWidth: 1.0 }
                            KeyboardKey { label: "X"; unitWidth: 1.0 }
                            KeyboardKey { label: "C"; unitWidth: 1.0 }
                            KeyboardKey { label: "V"; unitWidth: 1.0 }
                            KeyboardKey { label: "B"; unitWidth: 1.0 }
                            KeyboardKey { label: "N"; unitWidth: 1.0 }
                            KeyboardKey { label: "M"; unitWidth: 1.0 }
                            KeyboardKey { label: ","; unitWidth: 1.0 }
                            KeyboardKey { label: "."; unitWidth: 1.0 }
                            KeyboardKey { label: "/"; unitWidth: 1.0 }
                            KeyboardKey { label: "Shift"; keyId: "RightShift"; unitWidth: 2.75 }
                        }

                        // Row 5: Space Bar Row
                        Row {
                            spacing: 6
                            KeyboardKey { label: "Ctrl"; keyId: "LeftCtrl"; unitWidth: 1.25 }
                            KeyboardKey { label: "Win"; keyId: "LeftWin"; unitWidth: 1.25 }
                            KeyboardKey { label: "Alt"; keyId: "LeftAlt"; unitWidth: 1.25 }
                            KeyboardKey { label: "Space"; unitWidth: 6.25 }
                            KeyboardKey { label: "Alt"; keyId: "RightAlt"; unitWidth: 1.25 }
                            KeyboardKey { label: "Ctrl"; keyId: "RightCtrl"; unitWidth: 1.25 }
                        }
                    }
                }
            }

            // Mouse Layout Container (Visible when toggle is on)
            Rectangle {
                Layout.preferredWidth: 270
                Layout.preferredHeight: 350
                color: "#121417"
                radius: 12
                border.color: "#222"
                border.width: 1
                visible: mouseToggle.checked

                clip: true

                MousePreview {
                    anchors.centerIn: parent
                    activeMouseKeyId: root.activeKeyId
                }
            }
        }

        // Action Control Buttons Row
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 12

            Button {
                text: "Restore Defaults"
                contentItem: Text {
                    text: parent.text
                    color: "#cccccc"
                    font.family: mainFont
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    implicitWidth: 130
                    implicitHeight: 36
                    color: parent.hovered ? "#2a2d35" : "#1a1d23"
                    border.color: "#333"
                    border.width: 1
                    radius: 6
                }
                onClicked: KeyboardBridge.restoreDefaults()
            }
            Button {
             text: (KeyboardBridge.hasUnsavedChanges || MouseBridge.hasUnsavedChanges || ControllerBridge.hasUnsavedChanges) ? "Save Configuration *" : "Save Configuration"

                contentItem: Text {
                    text: parent.text
                    color: "black"
                    font.family: mainFont
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: 150
                    implicitHeight: 36
                  color: (KeyboardBridge.hasUnsavedChanges || MouseBridge.hasUnsavedChanges || ControllerBridge.hasUnsavedChanges) ? "#FFB000" : (parent.hovered ? "#139ed6" : "#15B8F5")
                    radius: 6
                }

                onClicked: {
                    KeyboardBridge.saveConfiguration()
                    MouseBridge.saveCurrentProfile()
                }
            }
        }
    }

    // New Profile Dialog popup
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
                        let profiles = KeyboardBridge.getAvailableProfiles()
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
                                KeyboardBridge.createProfile(name)
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

    // Unsaved Changes Dialog popup
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
                    text: "You have unsaved changes in your current configuration. Would you like to save them before switching?"
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

                    Button {
                        text: "Discard"
                        onClicked: {
                                let target = pendingProfileName
                                pendingProfileName = ""
                                unsavedChangesDialog.close()
                                KeyboardBridge.loadProfile(target)
                                MouseBridge.discardChanges()
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

                    Button {
                        text: "Save Changes"
                        onClicked: {
                                KeyboardBridge.saveCurrentProfile()
                                MouseBridge.saveCurrentProfile()
                                let target = pendingProfileName
                                pendingProfileName = ""
                                unsavedChangesDialog.close()
                                KeyboardBridge.loadProfile(target)
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