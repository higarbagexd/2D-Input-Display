import QtQuick
import com.overlay.controls

// Extended gaming overlay preset featuring the full keyboard layout and mouse overlay side-by-side
Item {
    id: preset9
    width: 900 // Full keyboard (680) + spacing (20) + mouse preset (200)
    height: 400

    // Main layout container holding both presets side-by-side
    Row {
        spacing: 20
        anchors.centerIn: parent

        // --- LEFT SIDE: Full Keyboard Preset ---
        Item {
            id: keyboardPreset
            width: 680
            height: 350

            // High-speed polling timer to keep the overlay in sync with C++ key states at 60fps
            Timer {
                id: pollTimer
                interval: 16
                running: true
                repeat: true
                property int tick: 0
                onTriggered: tick++
            }

            // Reusable custom key component to keep code clean and DRY
            component KeyButton: Rectangle {
                id: keyRoot

                required property string text
                required property int qtKey

                property real customWidth: 50
                property real customHeight: 45

                width: customWidth
                height: customHeight

                color: (pollTimer.tick === -1 || KeyboardBridge.isKeyPressed(qtKey)) ? "#222222" : "transparent"

                border.color: "white"
                border.width: 2
                radius: 4

                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(
                        1, -0.2, 0, 0,
                        0,  1,   0, 0,
                        0,  0,   1, 0,
                        0,  0,   0, 1
                    )
                }

                Text {
                    anchors.centerIn: parent
                    text: keyRoot.text
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    font.italic: true
                }
            }

            Column {
                id: keyboardColumn
                spacing: 8
                anchors.centerIn: parent

                // Row 1: number row
                Row {
                    spacing: 8
                    KeyButton { text: "~"; qtKey: Qt.Key_QuoteLeft }
                    KeyButton { text: "1"; qtKey: Qt.Key_1 }
                    KeyButton { text: "2"; qtKey: Qt.Key_2 }
                    KeyButton { text: "3"; qtKey: Qt.Key_3 }
                    KeyButton { text: "4"; qtKey: Qt.Key_4 }
                    KeyButton { text: "5"; qtKey: Qt.Key_5 }
                    KeyButton { text: "6"; qtKey: Qt.Key_6 }
                    KeyButton { text: "7"; qtKey: Qt.Key_7 }
                    KeyButton { text: "8"; qtKey: Qt.Key_8 }
                    KeyButton { text: "9"; qtKey: Qt.Key_9 }
                    KeyButton { text: "0"; qtKey: Qt.Key_0 }
                }

                // Row 2: TAB + QWERTYUIOP
                Row {
                    spacing: 8
                    KeyButton { text: "TAB"; qtKey: Qt.Key_Tab; customWidth: 65 }
                    KeyButton { text: "Q"; qtKey: Qt.Key_Q }
                    KeyButton { text: "W"; qtKey: Qt.Key_W }
                    KeyButton { text: "E"; qtKey: Qt.Key_E }
                    KeyButton { text: "R"; qtKey: Qt.Key_R }
                    KeyButton { text: "T"; qtKey: Qt.Key_T }
                    KeyButton { text: "Y"; qtKey: Qt.Key_Y }
                    KeyButton { text: "U"; qtKey: Qt.Key_U }
                    KeyButton { text: "I"; qtKey: Qt.Key_I }
                    KeyButton { text: "O"; qtKey: Qt.Key_O }
                    KeyButton { text: "P"; qtKey: Qt.Key_P }
                }

                // Row 3: CAPS + home row + ENTER
                Row {
                    spacing: 8
                    KeyButton { text: "CAPS"; qtKey: Qt.Key_CapsLock; customWidth: 70 }
                    KeyButton { text: "A"; qtKey: Qt.Key_A }
                    KeyButton { text: "S"; qtKey: Qt.Key_S }
                    KeyButton { text: "D"; qtKey: Qt.Key_D }
                    KeyButton { text: "F"; qtKey: Qt.Key_F }
                    KeyButton { text: "G"; qtKey: Qt.Key_G }
                    KeyButton { text: "H"; qtKey: Qt.Key_H }
                    KeyButton { text: "J"; qtKey: Qt.Key_J }
                    KeyButton { text: "K"; qtKey: Qt.Key_K }
                    KeyButton { text: "L"; qtKey: Qt.Key_L }
                    KeyButton { text: "ENTER"; qtKey: Qt.Key_Return; customWidth: 70 }
                }

                // Row 4: SHIFT + bottom row
                Row {
                    spacing: 8
                    KeyButton { text: "SHIFT"; qtKey: 0x1101; customWidth: 80 }
                    KeyButton { text: "Z"; qtKey: Qt.Key_Z }
                    KeyButton { text: "X"; qtKey: Qt.Key_X }
                    KeyButton { text: "C"; qtKey: Qt.Key_C }
                    KeyButton { text: "V"; qtKey: Qt.Key_V }
                    KeyButton { text: "B"; qtKey: Qt.Key_B }
                    KeyButton { text: "N"; qtKey: Qt.Key_N }
                    KeyButton { text: "M"; qtKey: Qt.Key_M }
                    KeyButton { text: ","; qtKey: Qt.Key_Comma }
                    KeyButton { text: "."; qtKey: Qt.Key_Period }
                    KeyButton { text: "/"; qtKey: Qt.Key_Slash }
                }

                // Row 5: ESC, modifiers, space, F-keys
                Row {
                    spacing: 8
                    KeyButton { text: "ESC"; qtKey: Qt.Key_Escape; customWidth: 60 }
                    KeyButton { text: "CTRL"; qtKey: 0x1103; customWidth: 65 }
                    KeyButton { text: "ALT"; qtKey: 0x1105; customWidth: 65 }
                    KeyButton { text: ""; qtKey: Qt.Key_Space; customWidth: 200 }
                    KeyButton { text: "F1"; qtKey: Qt.Key_F1 }
                    KeyButton { text: "F2"; qtKey: Qt.Key_F2 }
                    KeyButton { text: "F3"; qtKey: Qt.Key_F3 }
                    KeyButton { text: "F4"; qtKey: Qt.Key_F4 }
                }
            }
        }

        // --- RIGHT SIDE: Mouse Preset ---
        MousePreset {
            id: mousePreset
            width: 200
            height: 350
        }
    }
}