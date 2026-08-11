import QtQuick
import com.overlay.controls 1.0

// THIS IS THE DEFAULT CONTROLLER OVERLAY BICHROME (WHITE BLACK)
Item {
    id: controllerRoot
    width: 500; height: 400
    anchors.centerIn: parent

    readonly property var ctrl: ControllerBridge

    // local properties. initially theyre representing not pressed
    property real leftTrigger: 0.0
    property bool buttonLBPressed: false
    property real leftStickX: 0.0
    property real leftStickY: 0.0
    property bool leftStickPressed: false

    property bool dpadUp: false
    property bool dpadDown: false
    property bool dpadLeft: false
    property bool dpadRight: false

    property real rightTrigger: 0.0
    property bool buttonRBPressed: false
    property bool buttonYPressed: false
    property bool buttonXPressed: false
    property bool buttonBPressed: false
    property bool buttonAPressed: false
    property real rightStickX: 0.0
    property real rightStickY: 0.0
    property bool rightStickPressed: false

    // So basically whenever the signal controllerUpdated is emitted itll call this func. Qt's signal and slot sys does it for us
    Connections {
        target: ctrl
        function onControllerUpdated() {
            controllerRoot.leftTrigger = ctrl.getActionAxis(ControllerBridge.Action_LeftTrigger)
            controllerRoot.buttonLBPressed = ctrl.isActionPressed(ControllerBridge.Action_L_Shoulder)
            controllerRoot.leftStickX = ctrl.getActionAxis(ControllerBridge.Action_LeftStickX)
            controllerRoot.leftStickY = ctrl.getActionAxis(ControllerBridge.Action_LeftStickY)
            controllerRoot.leftStickPressed = ctrl.isActionPressed(ControllerBridge.Action_LeftStickClick)

            controllerRoot.dpadUp = ctrl.isActionPressed(ControllerBridge.Action_DPadUp)
            controllerRoot.dpadDown = ctrl.isActionPressed(ControllerBridge.Action_DPadDown)
            controllerRoot.dpadLeft = ctrl.isActionPressed(ControllerBridge.Action_DPadLeft)
            controllerRoot.dpadRight = ctrl.isActionPressed(ControllerBridge.Action_DPadRight)

            controllerRoot.rightTrigger = ctrl.getActionAxis(ControllerBridge.Action_RightTrigger)
            controllerRoot.buttonRBPressed = ctrl.isActionPressed(ControllerBridge.Action_R_Shoulder)
            controllerRoot.buttonYPressed = ctrl.isActionPressed(ControllerBridge.Action_Y)
            controllerRoot.buttonXPressed = ctrl.isActionPressed(ControllerBridge.Action_X)
            controllerRoot.buttonBPressed = ctrl.isActionPressed(ControllerBridge.Action_B)
            controllerRoot.buttonAPressed = ctrl.isActionPressed(ControllerBridge.Action_A)
            controllerRoot.rightStickX = ctrl.getActionAxis(ControllerBridge.Action_RightStickX)
            controllerRoot.rightStickY = ctrl.getActionAxis(ControllerBridge.Action_RightStickY)
            controllerRoot.rightStickPressed = ctrl.isActionPressed(ControllerBridge.Action_RightStickClick)
        }
    }

    // LEFT COLUMN
    Item {
        id: leftSide
        width: 150;
        height: parent.height
        anchors.left: parent.left

        // Left Trigger
        Rectangle {
            id: lt
            width: 100;
            height: 30
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            color: ctrl.showBackground ? "black" : "transparent";
            border.color: "white";
            border.width: 4
            radius: 8;
            topLeftRadius: 20 // for the specific top left corner of the Rectangle, override the radius for that.

            Rectangle {
                anchors.fill: parent; anchors.margins: 4
                color: "white"
                opacity: controllerRoot.leftTrigger // essentially the opacity depends on the value given.
                // if the value given is 0.2, then itll be slightly opacified. 0.5 and its half opacified. 1 and its completely white.
            }
        }

        // Left Shoulder (L)
        Rectangle {
            id: lb
            width: 110; height: 35
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lt.bottom; // this is so its perfectly aligned. the topMargin makes it that theres space between them so they arent connected together
            anchors.topMargin: 5
            color: controllerRoot.buttonLBPressed ? "white" : (ctrl.showBackground ? "black" : "transparent")
            border.color: "white";
            border.width: 4
            radius: 8;
            bottomLeftRadius: 15
        }

        // Left Stick
        Rectangle {
            id: lStick
            width: 100;
            height: 100;
            radius: 50 // circle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lb.bottom; // so this is how we're going about placing the items. All relative to each other.
            anchors.topMargin: 30
            color: ctrl.showBackground ? "black" : "transparent"
            border.color: "white";
            border.width: 4

            Rectangle {
                id: lStickInner
                width: 60; height: 60; radius: 30
                color: controllerRoot.leftStickPressed ? "white" : "transparent"
                border.color: "white";
                border.width: 4
                anchors.centerIn: parent

                transform: Translate {
                    x: controllerRoot.leftStickX * 15; // its gonna move in these pixels depending on thesevalues.
                    y: controllerRoot.leftStickY * 15
                }

                Behavior on color { // just a little animation over  50 ms to make the color change smooth
                    ColorAnimation { duration: 50 }
                }

            }
        }

        // D-Pad
        Item {
            id: dpadContainer
            width: 90; height: 90
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lStick.bottom;
            anchors.topMargin: 20
            property int dThickness: 30
            property int dLength: 85

            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dLength;
                height: dpadContainer.dThickness // here its horizontal
                color: ctrl.showBackground ? "black" : "transparent";
                border.color: "white";
                border.width: 4;
                radius: 8
            }
            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dThickness;
                height: dpadContainer.dLength // here its vertical
                color: ctrl.showBackground ? "black" : "transparent";
                border.color: "white";
                border.width: 4;
                radius: 8
            }

            Rectangle { // these two are slightly smaller than the normal main rectangles BUT theyre here to make it "hollow" in the main rects
                anchors.centerIn: parent
                width: dpadContainer.dLength - 8;
                height: dpadContainer.dThickness - 7 // horizontal
                color: "black";
                z: 1
            }
            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dThickness - 7;
                height: dpadContainer.dLength - 8 // vertical
                color: "black";
                z: 1
            }

            // D-Pad Fills
            Rectangle { // center
                anchors.centerIn: parent
                width: dpadContainer.dThickness - 12;
                height: dpadContainer.dThickness - 12
                color: (controllerRoot.dpadUp || controllerRoot.dpadDown || controllerRoot.dpadLeft || controllerRoot.dpadRight) ? "white" : "transparent"
                radius: 4; z: 2
            }
            Rectangle { // upper fill
                width: dpadContainer.dThickness - 12; // the width is lower than the height therefore this is a vertical
                height: (dpadContainer.dLength / 2) - 4;
                anchors.bottom: parent.verticalCenter; // if the bottom is at the center, then the rest must be above the center
                anchors.horizontalCenter: parent.horizontalCenter;
                color: controllerRoot.dpadUp ? "white" : "transparent";
                radius: 4; z: 2
            }
            Rectangle { // lower fill
                width: dpadContainer.dThickness - 12; // also  a vertical
                height: (dpadContainer.dLength / 2) - 4;
                anchors.top: parent.verticalCenter;
                anchors.horizontalCenter: parent.horizontalCenter;
                color: controllerRoot.dpadDown ? "white" : "transparent";
                radius: 4; z: 2
            }
            Rectangle { // left fill
                width: (dpadContainer.dLength / 2) - 4;
                height: dpadContainer.dThickness - 12;
                anchors.right: parent.horizontalCenter;
                anchors.verticalCenter: parent.verticalCenter;
                color: controllerRoot.dpadLeft ? "white" : "transparent";
                radius: 4;
                z: 2
            }
            Rectangle { // right fill
                width: (dpadContainer.dLength / 2) - 4;
                height: dpadContainer.dThickness - 12;
                anchors.left: parent.horizontalCenter;
                anchors.verticalCenter: parent.verticalCenter;
                color: controllerRoot.dpadRight ? "white" : "transparent";
                radius: 4;
                z: 2
            }
        }
    }

    // RIGHT COLUMN
    // essentially a mirror of the left side really for themost part
    Item {
        id: rightSide
        width: 150;
        height: parent.height
        anchors.right: parent.right

        // Right Trigger
        Rectangle {
            id: rt
            width: 100;
            height: 30
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            color: ctrl.showBackground ? "black" : "transparent";
            border.color: "white";
            border.width: 4
            radius: 8;
            topRightRadius: 20
            Rectangle {
                anchors.fill: parent;
                anchors.margins: 4;
                color: "white";
                opacity: controllerRoot.rightTrigger
            }
        }

        // Right Shoulder (R)
        Rectangle {
            id: rb
            width: 110; height: 35
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: rt.bottom; anchors.topMargin: 5
            color: controllerRoot.buttonRBPressed ? "white" : (ctrl.showBackground ? "black" : "transparent")
            border.color: "white";
            border.width: 4
            radius: 8;
            bottomRightRadius: 15
        }

        // Face Buttons
        Item {
            id: faceButtons
            width: 110; height: 110
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: rb.bottom;
            anchors.topMargin: 30
            component DiamondButton : Rectangle { // a little reusable component for the face buttons, in a diamond shape
                property bool active: false
                width: 36;
                height: 36;
                radius: 18 // meaning its acircle
                color: active ? "white" : (controllerRoot.ctrl.showBackground ? "black" : "transparent") // is it active? then white, else, is show background true? then black, else transparent
                border.color: "white";
                border.width: 4
            }
            DiamondButton { active: controllerRoot.buttonYPressed; anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter }
            DiamondButton { active: controllerRoot.buttonXPressed; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
            DiamondButton { active: controllerRoot.buttonBPressed; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
            DiamondButton { active: controllerRoot.buttonAPressed; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter }
        }

        // Right Stick
        Rectangle {
            width: 100; height: 100; radius: 50
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: faceButtons.bottom; anchors.topMargin: 20
            color: ctrl.showBackground ? "black" : "transparent"
            border.color: "white"; border.width: 4

            Rectangle {
                id: rStickInner
                width: 60; height: 60; radius: 30
                color: controllerRoot.rightStickPressed ? "white" : "transparent"
                border.color: "white"; border.width: 4
                anchors.centerIn: parent

                transform: Translate {
                    x: controllerRoot.rightStickX * 15;
                    y: controllerRoot.rightStickY * 15
                }

                Behavior on color { ColorAnimation { duration: 50 } }
            }
        }
    }
}