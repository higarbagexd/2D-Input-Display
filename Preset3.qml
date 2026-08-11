import QtQuick
import QtQuick.Shapes
import com.overlay.controls 1.0

// Just the GC Overlay but horizontal

Item {
    id: horizontalGCRoot
    width: 800; height: 250 // compared to preset 2 its wider than it is tall because its horizontal
    anchors.centerIn: parent
    readonly property var ctrl: ControllerBridge

// controller state properties
    property real leftTrigger: 0.0
    property real rightTrigger: 0.0

    property bool leftStickPressed: false
    property real leftStickX: 0.0
    property real leftStickY: 0.0

    property bool dpadUp: false
    property bool dpadDown: false
    property bool dpadLeft: false
    property bool dpadRight: false

    property bool buttonRBPressed: false
    property bool buttonAPressed: false
    property bool buttonBPressed: false
    property bool buttonYPressed: false
    property bool buttonXPressed: false

    property bool rightStickPressed: false
    property real rightStickX: 0.0
    property real rightStickY: 0.0

    // runs everytime controllerUpdated is emitted and copies values from ControllerBridge
    function updateStates() {
        if (!ctrl) return;

        leftTrigger       = ctrl.getActionAxis(ControllerBridge.Action_LeftTrigger)
        rightTrigger      = ctrl.getActionAxis(ControllerBridge.Action_RightTrigger)

        leftStickPressed  = ctrl.isActionPressed(ControllerBridge.Action_LeftStickClick)
        leftStickX        = ctrl.getActionAxis(ControllerBridge.Action_LeftStickX)
        leftStickY        = ctrl.getActionAxis(ControllerBridge.Action_LeftStickY)

        dpadUp            = ctrl.isActionPressed(ControllerBridge.Action_DPadUp)
        dpadDown          = ctrl.isActionPressed(ControllerBridge.Action_DPadDown)
        dpadLeft          = ctrl.isActionPressed(ControllerBridge.Action_DPadLeft)
        dpadRight         = ctrl.isActionPressed(ControllerBridge.Action_DPadRight)

        buttonRBPressed   = ctrl.isActionPressed(ControllerBridge.Action_R_Shoulder)
        buttonAPressed    = ctrl.isActionPressed(ControllerBridge.Action_A)
        buttonBPressed    = ctrl.isActionPressed(ControllerBridge.Action_B)
        buttonYPressed    = ctrl.isActionPressed(ControllerBridge.Action_Y)
        buttonXPressed    = ctrl.isActionPressed(ControllerBridge.Action_X)

        rightStickPressed = ctrl.isActionPressed(ControllerBridge.Action_RightStickClick)
        rightStickX       = ctrl.getActionAxis(ControllerBridge.Action_RightStickX)
        rightStickY       = ctrl.getActionAxis(ControllerBridge.Action_RightStickY)
    }


    Connections {
        target: ctrl
        function onControllerUpdated() {
            horizontalGCRoot.updateStates()
        }
    }

    Component.onCompleted: {
        horizontalGCRoot.updateStates()
    }

    // snapping logic all explained in preset2
    function getSnappedPos(rawX, rawY, radius) {
        let mag = Math.sqrt(rawX * rawX + rawY * rawY);
        if (mag < 0.7) return { x: rawX * radius, y: rawY * radius };
        let angle = Math.atan2(rawY, rawX);
        let snappedAngle = Math.round(angle / (Math.PI / 4)) * (Math.PI / 4);
        return { x: Math.cos(snappedAngle) * mag * radius, y: Math.sin(snappedAngle) * mag * radius };
    }

    // --- OCTAGON COMPONENT ---
    component OctagonGate : Shape {
        property color gateColor: "white"
        width: 110; height: 110
        ShapePath {
            strokeColor: gateColor; strokeWidth: 4
            fillColor: ctrl.showBackground ? "black" : "transparent"
            PathPolyline {
                path: [
                    Qt.point(55, 0), Qt.point(93, 17), Qt.point(110, 55),
                    Qt.point(93, 93), Qt.point(55, 110), Qt.point(17, 93),
                    Qt.point(0, 55), Qt.point(17, 17), Qt.point(55, 0)
                ]
            }
        }
    }


    // This column keeps the Triggers and the Buttons together and centered
    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 10
        spacing: 25

        // 1. TRIGGER ROW
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 100

            Rectangle { // L
                width: 120; height: 10; radius: 5; color: "transparent"; border.color: "white"; border.width: 2
                Rectangle { width: parent.width * horizontalGCRoot.leftTrigger; height: parent.height; radius: 5; color: "white" }
            }
            Rectangle { // R
                width: 120; height: 10; radius: 5; color: "transparent"; border.color: "white"; border.width: 2
                Rectangle { width: parent.width * horizontalGCRoot.rightTrigger; height: parent.height; radius: 5; color: "white"; anchors.right: parent.right }
            }
        }

        // MAIN BUTTON ROW
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 40

            // LEFT STICK
            OctagonGate {
                Rectangle {
                    width: 56; height: 56; radius: 28
                    color: horizontalGCRoot.leftStickPressed ? "white" : "transparent"
                    border.color: "white"; border.width: 4; anchors.centerIn: parent
                    transform: Translate {
                        property var pos: horizontalGCRoot.getSnappedPos(horizontalGCRoot.leftStickX, horizontalGCRoot.leftStickY, 27)
                        x: pos.x; y: pos.y
                    }
                }
            }

            // Dpad
            Item {
                width: 90; height: 90
                Rectangle { width: 90; height: 32; radius: 4; color: "black"; border.color: "white"; border.width: 3; anchors.centerIn: parent }
                Rectangle { width: 32; height: 90; radius: 4; color: "black"; border.color: "white"; border.width: 3; anchors.centerIn: parent }
                Rectangle { width: 28; height: 28; color: "black"; anchors.centerIn: parent; z: 1 }

                Text { text: "▲"; color: horizontalGCRoot.dpadUp ? "white" : "#444"; font.pixelSize: 18; anchors.top: parent.top; anchors.topMargin: 2; anchors.horizontalCenter: parent.horizontalCenter; z: 2 }
                Text { text: "▼"; color: horizontalGCRoot.dpadDown ? "white" : "#444"; font.pixelSize: 18; anchors.bottom: parent.bottom; anchors.bottomMargin: 2; anchors.horizontalCenter: parent.horizontalCenter; z: 2 }
                Text { text: "◀"; color: horizontalGCRoot.dpadLeft ? "white" : "#444"; font.pixelSize: 22; anchors.left: parent.left; anchors.leftMargin: 4; anchors.verticalCenter: parent.verticalCenter; z: 2 }
                Text { text: "▶"; color: horizontalGCRoot.dpadRight ? "white" : "#444"; font.pixelSize: 22; anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter; z: 2 }
            }

            // face buttons
            Item {
                width: 160; height: 110
                Rectangle { // A
                    id: btnA
                    width: 70; height: 70; radius: 35; anchors.centerIn: parent
                    color: horizontalGCRoot.buttonAPressed ? "#00FFAB" : "transparent"; border.color: "#00FFAB"; border.width: 5
                    Text { text: "A"; anchors.centerIn: parent; color: "#00FFAB"; font.bold: true; font.pixelSize: 22 }
                }
                Rectangle { // B
                    width: 36; height: 36; radius: 18; x: 5; y: 65
                    color: horizontalGCRoot.buttonBPressed ? "#FF4B4B" : "transparent"; border.color: "#FF4B4B"; border.width: 4
                    Text { text: "B"; anchors.centerIn: parent; color: "#FF4B4B"; font.bold: true; font.pixelSize: 14 }
                }
                Rectangle { // Y
                    width: 60; height: 24; radius: 12; x: 50; y: -15 // Moved up to create the gap
                    color: horizontalGCRoot.buttonYPressed ? "#AAAAFF" : "transparent"; border.color: "#AAAAFF"; border.width: 4
                    Text { text: "Y"; anchors.centerIn: parent; color: "#AAAAFF"; font.bold: true; font.pixelSize: 14 }
                }
                Rectangle { // X
                    width: 24; height: 60; radius: 12; x: 130; y: 25
                    color: horizontalGCRoot.buttonXPressed ? "#AAAAFF" : "transparent"; border.color: "#AAAAFF"; border.width: 4
                    Text { text: "X"; anchors.centerIn: parent; color: "#AAAAFF"; font.bold: true; font.pixelSize: 14 }
                }
            }

            // C-STICK
            OctagonGate {
                gateColor: "#FFD700"
                Rectangle {
                    width: 46; height: 46; radius: 23
                    color: horizontalGCRoot.rightStickPressed ? "#FFD700" : "transparent"
                    border.color: "#FFD700"; border.width: 4; anchors.centerIn: parent
                    transform: Translate {
                        property var pos: horizontalGCRoot.getSnappedPos(horizontalGCRoot.rightStickX, horizontalGCRoot.rightStickY, 22)
                        x: pos.x; y: pos.y
                    }
                }
            }

            // Z BUTTON
            Rectangle {
                width: 60; height: 24; radius: 12; anchors.verticalCenter: parent.verticalCenter
                color: horizontalGCRoot.buttonRBPressed ? "#A080FF" : "transparent"; border.color: "#A080FF"; border.width: 3
                Text { text: "Z"; anchors.centerIn: parent; color: "#A080FF"; font.bold: true; font.pixelSize: 14 }
            }
        }
    }
}