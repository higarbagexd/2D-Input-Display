import QtQuick
import com.overlay.controls 1.0

// THIS IS THE DEFAULT CONTROLLER OVERLAY BICHROME (WHITE BLACK) - REUSABLE COMPONENT
Item {
    id: controllerRoot
    implicitWidth: 500
    implicitHeight: 400
    width: implicitWidth
    height: implicitHeight

    // --- State Properties not from controllerbridge
    property bool showBackground: true

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

    // --- LEFT COLUMN ---
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
            color: controllerRoot.showBackground ? "black" : "transparent";
            border.color: "white";
            border.width: 4
            radius: 8;
            topLeftRadius: 20

            Rectangle {
                anchors.fill: parent; anchors.margins: 4
                color: "white"
                opacity: controllerRoot.leftTrigger
            }
        }

        // Left Shoulder
        Rectangle {
            id: lb
            width: 110;
            height: 35
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lt.bottom;
            anchors.topMargin: 5
            color: controllerRoot.buttonLBPressed ? "white" : (controllerRoot.showBackground ? "black" : "transparent")
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
            radius: 50
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lb.bottom;
            anchors.topMargin: 30
            color: controllerRoot.showBackground ? "black" : "transparent"
            border.color: "white";
            border.width: 4

            Rectangle {
                id: lStickInner
                width: 60;
                height: 60;
                radius: 30
                color: controllerRoot.leftStickPressed ? "white" : "transparent"
                border.color: "white";
                border.width: 4
                anchors.centerIn: parent

                transform: Translate {
                    x: controllerRoot.leftStickX * 15; y: controllerRoot.leftStickY * 15
                }

                Behavior on color { ColorAnimation { duration: 50 } }
            }
        }

        // DPad
        Item {
            id: dpadContainer
            width: 90;
            height: 90
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: lStick.bottom;
            anchors.topMargin: 20
            property int dThickness: 30
            property int dLength: 85

            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dLength;
                height: dpadContainer.dThickness
                color: controllerRoot.showBackground ? "black" : "transparent";
                border.color: "white";
                border.width: 4; radius: 8
            }
            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dThickness;
                height: dpadContainer.dLength
                color: controllerRoot.showBackground ? "black" : "transparent";
                border.color: "white";
                border.width: 4; radius: 8
            }

            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dLength - 8;
                height: dpadContainer.dThickness - 7
                color: "black";
                z: 1
            }
            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dThickness - 7;
                height: dpadContainer.dLength - 8
                color: "black";
                z: 1
            }

            // DPad Fills
            Rectangle {
                anchors.centerIn: parent
                width: dpadContainer.dThickness - 12;
                height: dpadContainer.dThickness - 12
                color: (controllerRoot.dpadUp || controllerRoot.dpadDown || controllerRoot.dpadLeft || controllerRoot.dpadRight) ? "white" : "transparent"
                radius: 4;
                z: 2
            }
            Rectangle {
                width: dpadContainer.dThickness - 12;
                height: (dpadContainer.dLength / 2) - 4;
                anchors.bottom: parent.verticalCenter;
                anchors.horizontalCenter: parent.horizontalCenter;
                color: controllerRoot.dpadUp ? "white" : "transparent"; radius: 4; z: 2 }
            Rectangle
            {
                width: dpadContainer.dThickness - 12; height: (dpadContainer.dLength / 2) - 4; anchors.top: parent.verticalCenter; anchors.horizontalCenter: parent.horizontalCenter; color: controllerRoot.dpadDown ? "white" : "transparent"; radius: 4; z: 2 }
            Rectangle {
                width: (dpadContainer.dLength / 2) - 4;
                height: dpadContainer.dThickness - 12;
                anchors.right: parent.horizontalCenter;
                anchors.verticalCenter: parent.verticalCenter;
                color: controllerRoot.dpadLeft ? "white" : "transparent"; radius: 4; z: 2 }
            Rectangle {
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

    // --- RIGHT COLUMN ---
    Item {
        id: rightSide
        width: 150;
        height: parent.height
        anchors.right: parent.right

        // Right Trigger
        Rectangle {
            id: rt
            width: 100; height: 30
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            color: controllerRoot.showBackground ? "black" : "transparent";
            border.color: "white";
            border.width: 4
            radius: 8;
            topRightRadius: 20
            Rectangle {
                anchors.fill: parent;
                anchors.margins: 4;
                color: "white";
                opacity: controllerRoot.rightTrigger }
        }

        // Right Shoulder
        Rectangle {
            id: rb
            width: 110;
            height: 35
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: rt.bottom;
            anchors.topMargin: 5
            color: controllerRoot.buttonRBPressed ? "white" : (controllerRoot.showBackground ? "black" : "transparent")
            border.color: "white";
            border.width: 4
            radius: 8;
            bottomRightRadius: 15
        }

        // Face Buttons
        Item {
            id: faceButtons
            width: 110;
            height: 110
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: rb.bottom;
            anchors.topMargin: 30

            component DiamondButton : Rectangle {
                property bool active: false
                property string label: ""
                width: 36;
                height: 36;
                radius: 18
                color: active ? "white" : (controllerRoot.showBackground ? "black" : "transparent")
                border.color: "white";
                border.width: 4

                Text {
                    anchors.centerIn: parent
                    text: label
                    color: active ? "black" : "white"
                    font.bold: true
                    font.pixelSize: 14
                    font.family: "Montserrat"
                }
            }
            DiamondButton {
                label: "Y";
                active: controllerRoot.buttonYPressed;
                anchors.top: parent.top;
                anchors.horizontalCenter: parent.horizontalCenter
            }
            DiamondButton {
                label: "X";
                active: controllerRoot.buttonXPressed;
                anchors.left: parent.left;
                anchors.verticalCenter: parent.verticalCenter
            }
            DiamondButton {
                label: "B";
                active: controllerRoot.buttonBPressed;
                anchors.right: parent.right;
                anchors.verticalCenter: parent.verticalCenter
            }
            DiamondButton {
                label: "A";
                active: controllerRoot.buttonAPressed;
                anchors.bottom: parent.bottom;
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Right Stick
        Rectangle {
            width: 100;
            height: 100;
            radius: 50
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: faceButtons.bottom;
            anchors.topMargin: 20
            color: controllerRoot.showBackground ? "black" : "transparent"
            border.color: "white";
            border.width: 4

            Rectangle {
                id: rStickInner
                width: 60;
                height: 60;
                radius: 30
                color: controllerRoot.rightStickPressed ? "white" : "transparent"
                border.color: "white";
                border.width: 4
                anchors.centerIn: parent

                transform: Translate {
                    x: controllerRoot.rightStickX * 15; y: controllerRoot.rightStickY * 15
                }

                Behavior on color { ColorAnimation { duration: 50 } }
            }
        }
    }
}