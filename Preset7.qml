import QtQuick
import com.overlay.controls

Item {
    id: pastelKeyboard
    width: 520
    height: 260

    // High-speed polling timer to keep the overlay in sync with C++ key states
    Timer {
        id: pollTimer
        interval: 16
        running: true
        repeat: true
        property int tick: 0
        onTriggered: tick++
    }

    // Reusable custom key component using the poll timer for real-time response
    component PastelKey: Rectangle {
        id: keyRoot
        required property string text
        required property int qtKey

        property real customWidth: 36
        property real customHeight: 36

        width: customWidth
        height: customHeight
        radius: 8

        // Changes color dynamically when the key is pressed
        color: (pollTimer.tick === -1 || KeyboardBridge.isKeyPressed(qtKey)) ? "#9e4e66" : "#f2e1d0"

        Text {
            anchors.centerIn: parent
            text: keyRoot.text
            color: (pollTimer.tick === -1 || KeyboardBridge.isKeyPressed(qtKey)) ? "#ffffff" : "#7a2b45"
            font.pixelSize: 13
            font.bold: true
        }
    }

    Column {
        id: keyboardColumn
        spacing: 6
        anchors.centerIn: parent

        // Row 1: q w e r t y u i o p [ ]
        Row {
            spacing: 6
            PastelKey { text: "q"; qtKey: Qt.Key_Q }
            PastelKey { text: "w"; qtKey: Qt.Key_W }
            PastelKey { text: "e"; qtKey: Qt.Key_E }
            PastelKey { text: "r"; qtKey: Qt.Key_R }
            PastelKey { text: "t"; qtKey: Qt.Key_T }
            PastelKey { text: "y"; qtKey: Qt.Key_Y }
            PastelKey { text: "u"; qtKey: Qt.Key_U }
            PastelKey { text: "i"; qtKey: Qt.Key_I }
            PastelKey { text: "o"; qtKey: Qt.Key_O }
            PastelKey { text: "p"; qtKey: Qt.Key_P }
            PastelKey { text: "["; qtKey: Qt.Key_BracketLeft }
            PastelKey { text: "]"; qtKey: Qt.Key_BracketRight }
        }

        // Row 2: a s d f g h j k l ; '
        Row {
            spacing: 6
            x: 18
            PastelKey { text: "a"; qtKey: Qt.Key_A }
            PastelKey { text: "s"; qtKey: Qt.Key_S }
            PastelKey { text: "d"; qtKey: Qt.Key_D }
            PastelKey { text: "f"; qtKey: Qt.Key_F }
            PastelKey { text: "g"; qtKey: Qt.Key_G }
            PastelKey { text: "h"; qtKey: Qt.Key_H }
            PastelKey { text: "j"; qtKey: Qt.Key_J }
            PastelKey { text: "k"; qtKey: Qt.Key_K }
            PastelKey { text: "l"; qtKey: Qt.Key_L }
            PastelKey { text: ";"; qtKey: Qt.Key_Semicolon }
            PastelKey { text: "'"; qtKey: Qt.Key_Apostrophe }
        }

        // Row 3: z x c v b n m , . /
        Row {
            spacing: 6
            x: 38
            PastelKey { text: "z"; qtKey: Qt.Key_Z }
            PastelKey { text: "x"; qtKey: Qt.Key_X }
            PastelKey { text: "c"; qtKey: Qt.Key_C }
            PastelKey { text: "v"; qtKey: Qt.Key_V }
            PastelKey { text: "b"; qtKey: Qt.Key_B }
            PastelKey { text: "n"; qtKey: Qt.Key_N }
            PastelKey { text: "m"; qtKey: Qt.Key_M }
            PastelKey { text: ","; qtKey: Qt.Key_Comma }
            PastelKey { text: "."; qtKey: Qt.Key_Period }
            PastelKey { text: "/"; qtKey: Qt.Key_Slash }
        }

        // Row 4: Space bar centered underneath
        Row {
            spacing: 6
            x: 95
            PastelKey { text: ""; qtKey: Qt.Key_Space; customWidth: 200; customHeight: 36 }
        }
    }
}