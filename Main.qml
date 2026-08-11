import QtQuick
import QtQuick.Window
import com.overlay.controls 1.0

Window {
    // root refers to this window
    id: root
    width: 600
    height: 500
    visible: true
    color: "transparent" // makes the actual window transparent
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint // no Windows title bar, always stay on top
    minimumWidth: 200
    minimumHeight: 250
    property string mainFont: "Montserrat"
    property var ctrl: ControllerBridge

    // ---- INIT ----
    Component.onCompleted: { // run once everything has been created
        // Essentially we are linking this window to the backend (setWindow defined there which does m_window = inputWindow)
        ctrl.setWindow(root)
        // Load mapping configuration
        ctrl.loadMappingConfig("")
        updateWindowSizeForPreset(ctrl.mappingPreset)
    }

    // Listens for changes to mappingPreset so the window updates its initial size when switching presets
    Connections {
        target: ctrl
        function onMappingPresetChanged() {
            updateWindowSizeForPreset(ctrl.mappingPreset)
        }
    }

    // ---- UPDATE CHECKER SIGNAL LISTENER ----
    Connections {
        target: updateChecker
        function onUpdateAvailable(latestVersion, downloadUrl) {
            updatePopup.latestTag = latestVersion
            updatePopup.downloadUrl = downloadUrl
            updatePopup.visible = true
        }
    }

    function updateWindowSizeForPreset(preset) {
        if (preset === 5) {
            root.width = 920;
            root.height = 450;
        } else if (preset === 4 || preset === 6) {
            root.width = 520;
            root.height = 300;
        } else {
            root.width = 600;
            root.height = 500;
        }
    }

    // --- custom title bar ----
    Rectangle {
        id: titleBar
        width: parent.width // the parent is the Window
        height: 35 // titleBar is 35 px tall
        color: "#1A1A1A"
        visible: ctrl.showTitleBar // binding, whenever showTitleBar changes the UI updates. This was declared as a property in InputBridge.h
        z: 10
        radius: 4

        MouseArea {
            anchors.fill: parent // mousearea will fill parent which is the titleBar
            anchors.rightMargin: 45
            onPressed: root.startSystemMove() // signal handler, when mouse is pressed call this Qt method which allows for moving the window
        }
        // text of the titlebar
        Text {
            // ternary operator, if mapping preset is 3 then display input history else display 2D INPUT OVERLAY and if its 4 then display that
            text: ctrl.mappingPreset === 3 ? "INPUT HISTORY" : ((ctrl.mappingPreset >= 4 && ctrl.mappingPreset <= 6) ? "KEYBOARD OVERLAY" : "2D INPUT OVERLAY")
            color: "#AAAAAA"
            font.pixelSize: 11
            font.letterSpacing: 1.2
            font.bold: true
            font.family: mainFont
            anchors.centerIn: parent
        }

        // Close Button
        Rectangle {
            id: closeBtn
            width: 45; height: parent.height
            color: closeHover.hovered ? "#E81123" : "transparent" // ternary operator, if its hovered go for red else transparent
            anchors.right: parent.right
            z: 11
            Text {
                text: "✕";
                color: "white";
                anchors.centerIn: parent // parent is the titleBar
            }
            HoverHandler {
                id: closeHover
            }
            TapHandler {
                onTapped: Qt.quit()
            } // on clicked call Qt.quit()
        }
    }

    // --- BACKGROUND ---
    Rectangle {
        id: mainBg
        anchors.fill: parent // fills the whole Window.
        color: "#121212"
        opacity: 0.85
        visible: ctrl.showBackground // property binding
        radius: 8
        z: -1 // the background is behind everything because it has the smallest z
    }

    // --- LOADER ---
    Loader { // A loader loads another QML file.
        id: presetLoader
        anchors.centerIn: parent // center of root Window
        anchors.verticalCenterOffset: ctrl.showTitleBar ? 17 : 0

        // Based on current active index load this qml file.
        source: {
            if (ctrl.mappingPreset === 1) return "Preset2.qml"
            if (ctrl.mappingPreset === 2) return "Preset3.qml"
            if (ctrl.mappingPreset === 3) return "Preset4.qml"
            if (ctrl.mappingPreset === 4) return "Preset5.qml"
            if (ctrl.mappingPreset === 5) return "Preset6.qml"
            if (ctrl.mappingPreset === 6) return "Preset7.qml"
            if(ctrl.mappingPreset === 7) return "MousePreset.qml"
            if(ctrl.mappingPreset === 8 ) return "Preset8.qml"
            if(ctrl.mappingPreset === 9) return "Preset9.qml"
            // basically this is what it starts with. I might change this later to have a "remember" feature.
            return "Preset1.qml"
        }

        // Dynamically scales down if window is too small, but caps max scale at 1.0 to prevent zooming in
        scale: {
            if (!item) return 1.0

            let horizontalPadding = 40
            let verticalPadding = titleBar.visible ? (35 + 40) : 40
            let availableWidth = root.width - horizontalPadding
            let availableHeight = root.height - verticalPadding

            return Math.min(1.0, availableWidth / item.width, availableHeight / item.height)
        }

        transformOrigin: Item.Center
        Behavior on scale { NumberAnimation { duration: 50 } } // animates over 50 ms
    }

    // --- UPDATE POPUP DIALOG ---
    Rectangle {
        id: updatePopup
        property string latestTag: ""
        property string downloadUrl: ""

        visible: false
        width: 300
        height: 130
        color: "#1E1E1E"
        border.color: "#333333"
        border.width: 1
        radius: 8
        anchors.centerIn: parent
        z: 100

        Column {
            anchors.centerIn: parent
            spacing: 12

            Text {
                text: " New Update Available (" + updatePopup.latestTag + ")"
                color: "#FFFFFF"
                font.bold: true
                font.pixelSize: 12
                font.family: mainFont
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "A new beta version is ready to download."
                color: "#888888"
                font.pixelSize: 10
                font.family: mainFont
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Row {
                spacing: 10
                anchors.horizontalCenter: parent.horizontalCenter

                // Download Button
                Rectangle {
                    width: 90; height: 28
                    color: btnHover.hovered ? "#005999" : "#007ACC"
                    radius: 4
                    Text { text: "Download"; color: "white"; anchors.centerIn: parent; font.pixelSize: 11; font.bold: true }
                    HoverHandler { id: btnHover }
                    TapHandler {
                        onTapped: {
                            Qt.openUrlExternally(updatePopup.downloadUrl)
                            updatePopup.visible = false
                        }
                    }
                }

                // Ignore Button
                Rectangle {
                    width: 70; height: 28
                    color: cancelHover.hovered ? "#444444" : "#2A2A2A"
                    radius: 4
                    Text { text: "Later"; color: "#AAAAAA"; anchors.centerIn: parent; font.pixelSize: 11 }
                    HoverHandler { id: cancelHover }
                    TapHandler {
                        onTapped: updatePopup.visible = false
                    }
                }
            }
        }
    }

    // --- resize handle on bottom right ---
    MouseArea {
        id: resizeHandle
        width: 30; height: 30
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeBDiagCursor
        z: 20
        onPressed: root.startSystemResize(Qt.RightEdge | Qt.BottomEdge)

        Rectangle {
            width: 12; height: 12
            color: "white"; opacity: 0.15
            anchors.bottom: parent.bottom; anchors.right: parent.right
            anchors.margins: 4
            visible: ctrl.showBackground
        }
    }
}