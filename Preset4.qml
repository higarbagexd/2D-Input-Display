import QtQuick
import com.overlay.controls 1.0
// IINPUT HISTORY
Item {
    id: historyRoot
    width: 300;
    height: 500
    anchors.centerIn: parent
    readonly property var ctrl: ControllerBridge

    ListModel {
        id: historyModel
    }
    Component.onCompleted: { // once this project has been created run this i.e when the preset opens
            ctrl.historyActive = true
        }
        Component.onDestruction: { // then when its destroyed or as in this preset is closed, then tell cpp
            ctrl.historyActive = false
        }
    function getBtnSymbol(btn) { // this is generally to make stuf flook good
        let base = btn; // suppose btn = C-UP, then base = C-UP
        if (btn.startsWith("C-")) base = btn.substring(2); // substring it so it removes the first two characters. e.g C-UP to UP
        if (btn.startsWith("D-")) base = btn.substring(2);

        switch(base) {
            case "UP":    return (btn.startsWith("D-") || btn.startsWith("C-")) ? "▲" : "↑"
            case "DOWN":  return (btn.startsWith("D-") || btn.startsWith("C-")) ? "▼" : "↓"
            case "LEFT":  return (btn.startsWith("D-") || btn.startsWith("C-")) ? "◀" : "←"
            case "RIGHT": return (btn.startsWith("D-") || btn.startsWith("C-")) ? "▶" : "→"
            case "UL": return "↖"; case "UR": return "↗";
            case "DL": return "↙"; case "DR": return "↘";
            default: return btn
        }
    }

    function getBtnColor(btn) {
        if (btn.startsWith("D-")) return "#888888"
        if (btn.startsWith("C-")) return "#FFD700" // Yellow for C-Stick
        if (["UP", "DOWN", "LEFT", "RIGHT", "UL", "UR", "DL", "DR"].includes(btn)) return "#FFFFFF" // White for LS
        if (btn === "A") return "#00FFAB"
        if (btn === "B") return "#FF4B4B"
        if (btn === "X") return "#00008B"
        if (btn === "Y") return "#FFD700"

        if (btn === "L" || btn === "R") return "#AAAAAA"
        if (btn === "ZL" || btn === "ZR") return "#777777"
        return "#555555"
    }

    Timer {
        id: frameTimer
        interval: 16 // every 16 ms
        running: false // dont start yet
        repeat: true // repeat forever
        onTriggered: {
            if (historyModel.count > 0) { // only do something if the list isnt empty
                let currentFrames = historyModel.get(0).frames; // index 0 is the newest entry. Suppose A frames = 10. Then currentframes = 10
                historyModel.setProperty(0, "frames", currentFrames + 1);
            }
        }
    }

    Connections {
            target: ControllerBridge // listen for signals from ControllerBridge
            function onHistoryInputTriggered(groupedInputs) { // normally its something like "onControllerUpdated" now its historyInputTriggered

                historyModel.insert(0, { "btn": groupedInputs, "frames": 1 });
                // this is why index 0 is always the newest
                // suppose you press A
                // now Index 0 is A, frames = 1
                // now you press B. index 0 is B, index 1 is A
                frameTimer.restart();

                if (historyModel.count > 15) historyModel.remove(15); // limit
            }
        }
    ListView {
        anchors.fill: parent
        model: historyModel
        spacing: 2
        clip: true

        header: Item {
            height: 10
        }

        delegate: Rectangle { // the "template" for one row.
            width: historyRoot.width
            height: 48
            color: index % 2 === 0 ? "#15FFFFFF" : "transparent" // ones grey ones transparent.

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 15
                spacing: 20

                // Frame count
                Text {
                    text: model.frames
                    color: "#BBBBBB"
                    font.pixelSize: 22
                    font.family: "Montserrat"
                    font.bold: true
                    width: 45
                    horizontalAlignment: Text.AlignRight
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Input icons
                Row {
                    spacing: 6
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: btn.split("+")

                        delegate: Rectangle {
                            width: 38;
                            height: 38;
                            radius: 19
                            color: getBtnColor(modelData)
                            border.color: "white"
                            border.width: 2

                            Text {
                                text: getBtnSymbol(modelData)
                                anchors.centerIn: parent
                                color: parent.color == "#ffffff" ? "#000000" : "#FFFFFF"
                                font.bold: true
                                font.pixelSize: (text.length > 1) ? 14 : 22
                                font.family: "Montserrat"
                            }
                        }
                    }
                }
            }
        }
    }
}