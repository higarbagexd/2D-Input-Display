import QtQuick
import QtQuick.Shapes
import com.overlay.controls 1.0

Item {
    id: gcRoot
    width: 600; height: 450
    anchors.centerIn: parent
    readonly property var ctrl: ControllerBridge


    // --- LOCAL CONTROLLER STATE PROPERTIES ---
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
    // made it a separate function here but its really just oncontrollerupdated like in preset1.qml
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
        function onControllerUpdated() { // cpp
            gcRoot.updateStates()
        }
    }

    Component.onCompleted: {
        gcRoot.updateStates() // when everything has been completely made also call the update states stuff here aswell.
    }

    /*
       Now basically this function is going to handle the "snapping" to the notches  because thats how the GC controllers work.
       Step 1 is to calculate the magnitude which is going to be the distance from the center of the stick. This is calculated
       using the pythagorean theorem.
       If you push the stick, SDL gives you something like e.g:
       rawX: 0.6
       rawY: 0.8

       You can think of this as a point. The question is, how far is the center from that point?
       Thats just the pythagorean theorem.
  distance² = x² + y²
       therefore
       distance = √(x² + y²)

Magnitude meaning the length of the vector, or simply just how far from the center is the stick.
       if (mag <0.8) is basically : "Has the stick reached the outside edge yet?"
       if not, dont snap.
     center area > move freely
     edge area > snap to notches

     Now mathematically:
       atan means arcTangent which is tan^-1.
       It answers, given the angle sides, whats the angle?
       Normally tangent is tan(angle) = opp/adj as we know from SOH CAH TOA.
        Although arcTangent is different it calculates the angle using : angle = atan(opposite/adjacent)

        Now why does atan2 exist? Its because lets say we have x= -1 and y= 1 . that point is top left. but atan(y/x) cannot tell if the point
        is top left or bottom right because both give the same ratio.

    What atan2 gives us:
        example:
        rawX = 1
        rawY = 0
        angle = 0° to the right

        rawX = 0
        rawY = 1
        angle = 90° to up

        rawX = -1
        rawY = 0
        angle = 180° to the left

        once we know the direction we can snap it cause gc notches are:
        0
        45
        90
        135
        180
       */

    function getSnappedPos(rawX, rawY, radius) {
        let mag = Math.sqrt(rawX * rawX + rawY * rawY);
        if (mag < 0.8) {
            return { x: rawX * radius, y: rawY * radius };
        } // if its not too far from the center then just give the normal values

        let angle = Math.atan2(rawY, rawX);
        /* now lets try an example
         lets say angle is 20
         Math.PI/4 returns 45
        20/45 is ~0.4
        Round that to the nearest whole number: 0
        Now do 0 * (Math.PI/4)
        = 0 * 45
        = 0

        Lets try another example - 70
        70/45 = 1.56
        Round that to the nearest whole number: 2
        2 * 45
        90

        */
        let snappedAngle = Math.round(angle / (Math.PI / 4)) * (Math.PI / 4);

        return {
            // We have: The angle and the magnitude (hypotenuse)
            // we know how far it is which is the hypotenuse.
            // If we wanted to find the y, that would be the opposite, and we have the hypotenuse. Therefore, we use sin.
            // If we wanted to find the x, that would be the adjacent and we have the hypotenuse. Therefore, we use cos.
            x: Math.cos(snappedAngle) * mag * radius,
            y: Math.sin(snappedAngle) * mag * radius
        };
    }

    // trigger "progress" bars so like zl and zr
    Row { // place the children next to each other
        anchors.top: parent.top
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 60 // space the children 60 px from each other

        // Left Trigger Bar
        Rectangle {
            width: 140;
            height: 12;
            radius: 6
            color: "transparent";  // it doesnt fill itself
            border.color: "white";
            border.width: 3
            // this above rectangle is the "outline" basically.
            Rectangle { // now we put a rectangle inside the parent rect so we can "fill" it.
                width: parent.width * gcRoot.leftTrigger
                height: parent.height;
                radius: 6
                color: "white"
                // QML coordinates start from the top left corner of the parent. This is why we dont have to write "anchors.left = parent.left"
                // Because itll just do x = 0 and y = 0
            }
        }

        // Right Trigger Bar
        Rectangle {
            width: 140;
            height: 12;
            radius: 6
            color: "transparent";
            border.color: "white";
            border.width: 3
            Rectangle {
                width: parent.width * gcRoot.rightTrigger
                height: parent.height;
                radius: 6
                color: "white";
                anchors.right: parent.right
            }
        }
    }

    // --- Octagon Component ---
    component OctagonGate : Shape { // base type is a QML Shape
        property color gateColor: "white"
        width: 130; height: 130
        ShapePath {
            strokeColor: gateColor; // stroke is the outline
            strokeWidth: 5 // makes the outline thicker
            fillColor: ctrl.showBackground ? "black" : "transparent" // fill the inside color
            PathPolyline { // connect these points wiht straight lines
                path: [
                    // 65 0 being the middle of the top edge
                    // 130 65 being the right edge with middle height
                    Qt.point(65, 0), Qt.point(110, 20), Qt.point(130, 65),
                    Qt.point(110, 110), Qt.point(65, 130), Qt.point(20, 110),
                    Qt.point(0, 65), Qt.point(20, 20), Qt.point(65, 0)
                ]
            }
        }
    }

    // --- LEFT SIDE: Left Stick and DPAD ---
    Column { // stacks children vertically so left stick and then below that is the dpad
        anchors.left: parent.left;
        anchors.leftMargin: 40
        anchors.verticalCenter: parent.verticalCenter // put it in the vertical middle
        anchors.verticalCenterOffset: 20 // move down by 20px
        spacing: 40

        OctagonGate {
            Rectangle {
                width: 70;
                height: 70;
                radius: 35 // circle
                color: gcRoot.leftStickPressed ? "white" : "transparent" // pressed then white else make transparent
                border.color: "white";
                border.width: 4;
                anchors.centerIn: parent // normally the stick starts in the center of the octagon
                transform: Translate {
                    property var pos: gcRoot.getSnappedPos(gcRoot.leftStickX, gcRoot.leftStickY, 30)
                    x: pos.x
                    y: pos.y
                }
            }
        }

        // d-PAD with Arrowhead Symbols
        Item {
            width: 90;
            height: 90;
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                width: 90;
                height: 32;
                radius: 4;
                color: "black";
                border.color: "white";
                border.width: 3;
                anchors.centerIn: parent
            }
            Rectangle {
                width: 32;
                height: 90;
                radius: 4;
                color: "black";
                border.color: "white";
                border.width: 3;
                anchors.centerIn: parent
            }
            Rectangle {
                width: 28;
                height: 28;
                color: "black";
                anchors.centerIn: parent;
                z: 1
            }

            Text { // self explanatory for the most part. if dpadUp is true then make the arrows white color else make them grey ish
                text: "▲";
                color: gcRoot.dpadUp ? "white" : "#555";
                font.pixelSize: 18; anchors.top: parent.top;
                anchors.topMargin: 2;
                anchors.horizontalCenter: parent.horizontalCenter; z: 2
            }
            Text {
                text: "▼";
                color: gcRoot.dpadDown ? "white" : "#555";
                font.pixelSize: 18;
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 2;
                anchors.horizontalCenter: parent.horizontalCenter;
                z: 2
            }
            Text {
                text: "◀";
                color: gcRoot.dpadLeft ? "white" : "#555";
                font.pixelSize: 18;
                anchors.left: parent.left;
                anchors.leftMargin: 2;
                anchors.verticalCenter: parent.verticalCenter;
                z: 2
            }
            Text {
                text: "▶";
                color: gcRoot.dpadRight ? "white" : "#555";
                font.pixelSize: 18;
                anchors.right: parent.right;
                anchors.rightMargin: 2;
                anchors.verticalCenter: parent.verticalCenter;
                z: 2
            }
        }
    }

    // --- RIGHT SIDE: Buttons and the C stick ---
    Item { // jus tlike the left side item
        anchors.right: parent.right;
        anchors.rightMargin: 50
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 20
        width: 250;
        height: 300

        //
        Rectangle {
            width: 60;
            height: 22;
            radius: 11;
            anchors.top: parent.top;
            anchors.right: parent.right
            color: gcRoot.buttonRBPressed ? "#A080FF" : "transparent";
            border.color: "#A080FF"; border.width: 3
        }

        // face buttons
        Rectangle {
            id: btnA
            width: 90;
            height: 90;
            radius: 45; // circle
            anchors.centerIn: parent
            color: gcRoot.buttonAPressed ? "#00FFAB" : "transparent";
            border.color: "#00FFAB";
            border.width: 5
        }
        Rectangle { // B
            width: 42;
            height: 42;
            radius: 21;
            x: 30;
            y: 160
            color: gcRoot.buttonBPressed ? "#FF4B4B" : "transparent";
            border.color: "#FF4B4B";
            border.width: 4
        }
        Rectangle { // Y
            width: 70;
            height: 28;
            radius: 14;
            x: 90;
            y: 60;
            rotation: 15
            color: gcRoot.buttonYPressed ? "#AAAAFF" : "transparent";
            border.color: "#AAAAFF";
            border.width: 4
        }

        Rectangle { // X
            width: 28;
            height: 70;
            radius: 14;
            x: 185;
            y: 100;
            rotation: -15
            color: gcRoot.buttonXPressed ? "#AAAAFF" : "transparent";
            border.color: "#AAAAFF";
            border.width: 4
        }

        // C-Stick (Right Stick)
        OctagonGate { // just like left just smaller and yellow
            gateColor: "#FFD700";
            scale: 0.75;
            x: 20;
            y: 210
            Rectangle {
                width: 60;
                height: 60;
                radius: 30
                color: gcRoot.rightStickPressed ? "#FFD700" : "transparent"
                border.color: "#FFD700";
                border.width: 4;
                anchors.centerIn: parent

                transform: Translate {
                    property var pos: gcRoot.getSnappedPos(gcRoot.rightStickX, gcRoot.rightStickY, 20)
                    x: pos.x
                    y: pos.y
                }
            }
        }
    }
}