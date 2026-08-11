import QtQuick
import QtQuick.Layouts
import com.overlay.controls 1.0
// this is just from keyboardmappingpage.qml
Rectangle {
    id: keyboardPreset
    anchors.fill: parent
    color: "transparent"

    component KeyboardKey : Rectangle {
        id: keyRoot
        property string label: ""
        property string keyId: label
        property real unitWidth: 1.0

        function getQtKey(id) {
            switch(id) {
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

        property int targetQtKey: getQtKey(keyId)
        property bool isPressed: KeyboardBridge.isKeyPressed(targetQtKey)

        width: unitWidth * 47
        height: 44
        radius: 6

        color: isPressed ? "#3a3f4b" : "#1a1a1a"
        border.color: isPressed ? "#5a6275" : "#333"
        border.width: 1

        Text {
            text: parent.label
            color: parent.isPressed ? "white" : "#cccccc"
            font.family: mainFont
            font.pixelSize: 12
            font.bold: true
            anchors.centerIn: parent
        }

        Connections {
            target: KeyboardBridge
            function onKeyboardUpdated() {
                keyRoot.isPressed = KeyboardBridge.isKeyPressed(keyRoot.targetQtKey)
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 860
        height: 330
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