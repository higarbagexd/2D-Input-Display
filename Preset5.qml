import QtQuick
import com.overlay.controls

// This is a simple keyboard preset basically the left side of a keyboard gaming overlay
Item {
    id: keyboardPreset
    width: 450
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

        // Text displayed inside the key
        required property string text
        // Qt key code to track state from KeyboardBridge
        required property int qtKey

        // Default sizing properties for standard keys
        property real customWidth: 50
        property real customHeight: 45

        width: customWidth
        height: customHeight

        color: (pollTimer.tick === -1 || KeyboardBridge.isKeyPressed(qtKey)) ? "#222222" : "transparent"

        // Clean white border matching your overlay theme
        border.color: "white"
        border.width: 2
        radius: 4

        // Applies a shear matrix transform to give the keys that slanted/italicized look
        transform: Matrix4x4 {
            matrix: Qt.matrix4x4(
                1, -0.2, 0, 0,  // X shear factor for the slant effect
                0,  1,   0, 0,
                0,  0,   1, 0,
                0,  0,   0, 1
            )
        }

        // Text label inside the key box
        Text {
            anchors.centerIn: parent
            text: keyRoot.text
            color: "white"
            font.pixelSize: 14
            font.bold: true
            font.italic: true
        }
    }

    // Main layout container holding all rows of keys
    Column {
        id: keyboardColumn
        spacing: 8
        anchors.centerIn: parent

        // Row 1: ~, 1, 2, 3, 4, 5
        Row {
            spacing: 8
            KeyButton { text: "~"; qtKey: Qt.Key_QuoteLeft }
            KeyButton { text: "1"; qtKey: Qt.Key_1 }
            KeyButton { text: "2"; qtKey: Qt.Key_2 }
            KeyButton { text: "3"; qtKey: Qt.Key_3 }
            KeyButton { text: "4"; qtKey: Qt.Key_4 }
            KeyButton { text: "5"; qtKey: Qt.Key_5 }
        }

        // Row 2: TAB, Q, W, E, R, T
        Row {
            spacing: 8
            KeyButton { text: "TAB"; qtKey: Qt.Key_Tab; customWidth: 65 }
            KeyButton { text: "Q"; qtKey: Qt.Key_Q }
            KeyButton { text: "W"; qtKey: Qt.Key_W }
            KeyButton { text: "E"; qtKey: Qt.Key_E }
            KeyButton { text: "R"; qtKey: Qt.Key_R }
            KeyButton { text: "T"; qtKey: Qt.Key_T }
        }

        // Row 3: A, S, D, F, G (aligned precisely under Q)
        Row {
            spacing: 8
            x: 73 // TAB width (65) + spacing (8)
            KeyButton { text: "A"; qtKey: Qt.Key_A }
            KeyButton { text: "S"; qtKey: Qt.Key_S }
            KeyButton { text: "D"; qtKey: Qt.Key_D }
            KeyButton { text: "F"; qtKey: Qt.Key_F }
            KeyButton { text: "G"; qtKey: Qt.Key_G }
        }

        // Row 4: SHIFT, Z, X, C, V, B
        Row {
            spacing: 8
            KeyButton { text: "SHIFT"; qtKey: 0x1101; customWidth: 75 } // LeftShift code
            KeyButton { text: "Z"; qtKey: Qt.Key_Z }
            KeyButton { text: "X"; qtKey: Qt.Key_X }
            KeyButton { text: "C"; qtKey: Qt.Key_C }
            KeyButton { text: "V"; qtKey: Qt.Key_V }
            KeyButton { text: "B"; qtKey: Qt.Key_B }
        }

        // Row 5: CTRL, [gap], ALT, and the space bar
        Row {
            spacing: 8
            KeyButton { text: "CTRL"; qtKey: 0x1103; customWidth: 65 } // LeftCtrl code

            // Spacer item to create the gap between CTRL and ALT matching your screenshot
            Item { width: 50; height: 45 }

            KeyButton { text: "ALT"; qtKey: 0x1105; customWidth: 65 }  // LeftAlt code
            KeyButton { text: ""; qtKey: Qt.Key_Space; customWidth: 151 }
        }
    }
}