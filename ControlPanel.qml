import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import com.overlay.controls 1.0

Window {
    id: controlPanel
    width: 1080; height: 700
    title: "2D Input Overlay Configuration"
    visible: true
    color: "#111111"

    // FramelessWindowHint removes the native OS title bar
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    property string mainFont: "Montserrat" // a mistake i made in other files shouldve declared this so i dont have to write font: montserrat everytime
    /** must change in other files */
    property var ctrl: ControllerBridge // did this sometimes aswell. instead of writing ControllerBridge.something i can just do ctrl

    // State Management
    property string currentPage: "Mapping"
    property string deviceSource: "Controller"
    property bool isMaximized: false // Tracks the state of maximizing like on the click to prevent having to double click the maximize btn

    function executePendingNavigation(action) {
        KeyboardBridge.isListening = false
        MouseBridge.isListening = false
        ctrl.cancelRemap()

        if (action === "Mapping") {
            currentPage = "Mapping"
            panelStack.replace(mappingPage)
        } else if (action === "Presets") {
            currentPage = "Presets"
            panelStack.replace(presetsPage)
        } else if (action === "Settings") {
            currentPage = "Settings"
            panelStack.replace(settingsPage)
        } else if (action === "Controller") {
            deviceSource = "Controller"
        } else if (action === "Keyboard") {
            deviceSource = "Keyboard"
        } else if (action === "Close") {
            controlPanel.close()
        }
    }

    // Top nav item template
    component NavItem : Item {
        property string label: "";
        property string icon: "";
        property bool active: false
        signal clicked() // declaring that this component has a signal called clicked, which in the onclicked is there
        width: 100;
        height: 70

        MouseArea {
            anchors.fill: parent;
            cursorShape: Qt.PointingHandCursor;
            onClicked: parent.clicked()
        }
        Column {
            anchors.centerIn: parent;
            spacing: 4
            Rectangle {
                width: 28;
                height: 28;
                radius: 6
                color: active ? "#00AEEF" : "#333"
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    text: icon;
                    anchors.centerIn: parent;
                    color: "white";
                    font.bold: true;
                    font.family: mainFont
                }
            }
            Text {
                text: label;
                color: active ? "#00AEEF" : "#888"
                font.pixelSize: 11;
                font.bold: true;
                font.family: mainFont
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        Rectangle {
            width: parent.width * 0.6;
            height: 3;
            color: "#00AEEF"
            visible: active;
            anchors.bottom: parent.bottom;
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // Sidebar toggle template
    component SidebarButton : Rectangle {
        property string icon: "";
        property bool active: false
        signal clicked() // also has a clicked signal
        width: 50;
        height: 50;
        radius: 12
        color: active ? "#00AEEF" : "#1a1a1a"
        border.color: active ? "transparent" : "#333"
        border.width: 1
        Text {
            text: icon;
            anchors.centerIn:parent;
            font.pixelSize: 22
        }
        MouseArea {
            anchors.fill: parent;
            cursorShape: Qt.PointingHandCursor;
            onClicked: parent.clicked()
        }
    }

    // --- Main layout ---
    Column {
        anchors.fill: parent

        // CUSTOM TITLE BAR
                Rectangle { // background for the custom title bar
                    id: customTitleBar
                    width: parent.width // because it the titlebar should of course be the width of the window itself.
                    height: 35
                    color: "#141414" // black

                    // Drag area to move the frameless window
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: 135
                        // We have a margin here from the right. The reason why is so that we dont accidentally trigger drag from the btns.

                        /*
                          startSystemMove() is a function in the Qt Framework used to start a native window move.
                            It makes a custom or borderless window follow the mouse cursor smoothly.
                          */
                        // onPressed vs onClicked
                        /*
                          the main difference between onPressed and onClicked is when they fire:
                        onPressed runs the exact moment a button goes down,
                         onClicked runs only after a complete press and release
                          */
                        onPressed: controlPanel.startSystemMove()
                        // simple, if its maximized then call showNormal()
                        // showNormal() shows the window as normal, i.e. neither maximized, minimized, nor fullscreen.
                        // i.e it returns to the user defined dimensions.
                        onDoubleClicked: {
                            if (controlPanel.isMaximized) { // if controlPanel (Window id) is maximized
                                controlPanel.showNormal() // unmaximize it
                                controlPanel.isMaximized = false // set isMaximized to false
                            } else {
                                controlPanel.showMaximized() // if it isnt maximized then make it maximized and set the bool to true.
                                controlPanel.isMaximized = true
                            }
                        }
                    }

                    Row {
                        anchors.left: parent.left // on the left of the titlebar
                        anchors.leftMargin: 16 // leave a margin of 16px
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10 // spacing between the rows children will be 10px

                        Rectangle {
                            width: 8;
                            height: 8;
                            radius: 4
                            color: "#00AEEF" // lil blue circle
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "CONTROL PANEL"
                            color: "#888888"
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 1.2
                            font.family: mainFont
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Window Control Buttons
                    Row {
                        anchors.right: parent.right
                        height: parent.height

                        // Minimize Button
                        Rectangle {
                            width: 45;
                            height: parent.height
                            color: minHover.hovered ? "#222222" : "transparent"
                            Text {
                                text: "─"
                                color: minHover.hovered ? "white" : "#AAAAAA"
                                font.pixelSize: 10
                                anchors.centerIn: parent // c enter the text in the rectangle
                            }
                            HoverHandler {
                                id: minHover
                            }
                            TapHandler {
                                onTapped: controlPanel.showMinimized()
                            }
                        }

                        // Maximize / Restore Toggle Button
                        Rectangle {
                            width: 45;
                            height: parent.height
                            color: maxHover.hovered ? "#222222" : "transparent"
                            Text {
                                text: controlPanel.isMaximized ? "❐" : "🗖" // if maximized put the first one else put the second
                                color: maxHover.hovered ? "white" : "#AAAAAA"
                                font.pixelSize: 11
                                anchors.centerIn: parent
                            }
                            HoverHandler {
                                id: maxHover
                            }
                            TapHandler {
                                onTapped: {
                                    if (controlPanel.isMaximized) {
                                        controlPanel.showNormal()
                                        controlPanel.isMaximized = false
                                    } else {
                                        controlPanel.showMaximized()
                                        controlPanel.isMaximized = true
                                    }
                                }
                            }
                        }

                        // Close Button
                        Rectangle {
                            width: 45;
                            height: parent.height
                            color: closeHover.hovered ? "#E81123" : "transparent"
                            Text {
                                text: "✕"
                                color: closeHover.hovered ? "white" : "#AAAAAA"
                                font.pixelSize: 11
                                anchors.centerIn: parent
                            }
                            HoverHandler {
                                id: closeHover
                            }
                            TapHandler {
                                onTapped: {
                                    if (ctrl.hasUnsavedChanges) {
                                        globalUnsavedDialog.pendingAction = "Close"
                                        globalUnsavedDialog.open()
                                    } else {
                                        controlPanel.close()
                                    }
                                }
                            }
                        }
                    }
        /*
          This rectangle is a thin, one pixel high line pinned directly to the bottom edge of the title bar using anchors.bottom
         acts as a visual border separating the titlebar from the rest of the app content below it.

          */
                    Rectangle {
                        width: parent.width; height: 1
                        color: "#222222"
                        anchors.bottom: parent.bottom
                    }
                }
        //  TOP NAV BAR

        Rectangle {
            width: parent.width; height: 75; color: "#1a1a1a"
            Row {
                anchors.centerIn: parent; spacing: 40
                NavItem {
                    label: "Mapping"; icon: "M"; active: currentPage == "Mapping"
                    onClicked: {
                        if(ctrl.hasUnsavedChanges) {
                            globalUnsavedDialog.pendingAction = "Mapping"
                            globalUnsavedDialog.open()
                            return
                        }

                        KeyboardBridge.isListening = false
                        MouseBridge.isListening = false
                        ctrl.cancelRemap() // <--- Add this here
                        currentPage = "Mapping";
                        panelStack.replace(mappingPage)
                    }
                }
                NavItem {
                    label: "Presets"; icon: "P"; active: currentPage == "Presets"
                    onClicked: {
                        if(ctrl.hasUnsavedChanges) {
                            globalUnsavedDialog.pendingAction = "Presets"
                            globalUnsavedDialog.open()
                            return
                        }
                        KeyboardBridge.isListening = false
                        MouseBridge.isListening = false
                        ctrl.cancelRemap() // <--- Add this here
                        currentPage = "Presets";
                        panelStack.replace(presetsPage)
                    }
                }
                NavItem {
                    label: "Settings"; icon: "S"; active: currentPage == "Settings"
                    onClicked: {
                        if(ctrl.hasUnsavedChanges) {
                            globalUnsavedDialog.pendingAction = "Settings"
                            globalUnsavedDialog.open()
                            return
                        }
                        KeyboardBridge.isListening = false
                        MouseBridge.isListening = false
                        ctrl.cancelRemap() // <--- Add this here
                        currentPage = "Settings";
                        panelStack.replace(settingsPage)
                    }
                }
            }
        }


        //   MAIN CONTENT ROW

        Row {
            width: parent.width
            height: parent.height - 110

            //  Sidebar is device source selection
            Rectangle {
                width: 80; height: parent.height; color: "#0d0d0d"
                Column {
                    anchors.top: parent.top; anchors.topMargin: 30
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 25
                    SidebarButton {
                        icon: "🎮"; active: deviceSource == "Controller"
                        onClicked: {
                            if (deviceSource === "Keyboard" && ctrl.hasUnsavedChanges) {
                                globalUnsavedDialog.pendingAction = "Controller"
                                globalUnsavedDialog.open()
                                return
                            }
                            deviceSource = "Controller"
                        }
                    }
                    SidebarButton {
                        icon: "⌨️"; active: deviceSource == "Keyboard"
                        onClicked: {
                            if (deviceSource === "Controller" && ctrl.hasUnsavedChanges) {
                                globalUnsavedDialog.pendingAction = "Keyboard"
                                globalUnsavedDialog.open()
                                return
                            }
                            KeyboardBridge.isListening = false
                            MouseBridge.isListening = false
                            ctrl.cancelRemap()
                            deviceSource = "Keyboard"
                        }
                    }
                }
            }

            // main content
            StackView {
                id: panelStack
                width: parent.width - 80; height: parent.height
                initialItem: mappingPage
                clip: true
            }
        } // row
    }

    // bascially the page components

    Component {
        id: mappingPage
        // Instantiates a Loader that dynamically swaps between Controller and Keyboard mapping pages
                Loader {
                    anchors.fill: parent
                    source: controlPanel.deviceSource === "Controller" ? "MappingPage.qml" : "KeyboardMappingPage.qml"
                }
    }

    Component {
        id: presetsPage
        ScrollView {
            clip: true
            Column {
                padding: 40; spacing: 20
                width: parent.availableWidth

                Text {
                    text: "Visual Presets";
                    color: "white"
                    font.pixelSize: 22;
                    font.bold: true;
                    font.family: mainFont
                }

                Flow { // flows are like another layout type. row is always horizontal, so is column, flow is also horizontal but wraps to the next line if needed.
                    width: parent.width - 80;
                    spacing: 12
                    Repeater {
                        model: ["Default", "GameCube", "Horizontal GC", "Input History", "Minimalist Keyboard", "Full keyboard 1", "Full keyboard 2", "Mouse Preset", "Minimalist + Mouse", "Full Minimalist + mouse"]
                        Button {
                            text: modelData
                            onClicked: ctrl.mappingPreset = index
                            /*
                              essentially the blocks below are editing the normal button background and text and stuff
                              because normally qt will draw its own background its own way of text, so we're just editing it really.
                                unlike a rectangle or something, a Button does not have its own "color" property or "Text" property.
                                so we say "for the "background" use our rectangle here

                              */
                            background: Rectangle {
                                implicitWidth: 150;
                                implicitHeight: 50;
                                radius: 8
                                color: ctrl.mappingPreset === index ? "#00AEEF" : "#1a1a1a"
                                border.color: ctrl.mappingPreset === index ? "white" : "#333" // same idea
                            }
                            contentItem: Text {
                                text: parent.text;
                                color: "white";
                                font.bold: true;
                                font.family: mainFont
                                horizontalAlignment: Text.AlignHCenter; // center the text
                                verticalAlignment: Text.AlignVCenter // --
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: settingsPage
        ScrollView {
            clip: true
            Column {
                padding: 40;
                spacing: 30
                width: parent.availableWidth

                Text {
                    text: "Window & Behavior";
                    color: "white";
                    font.pixelSize: 22;
                    font.bold: true;
                    font.family: mainFont
                }

                Grid {
                    columns: 2;
                    spacing: 25;
                    verticalItemAlignment: Grid.AlignVCenter

                    Text {
                        text: "Show Title Bar";
                        color: "#AAA";
                        width: 200;
                        font.family: mainFont
                    }
                    Switch {
                        checked: ctrl.showTitleBar
                        onToggled: ctrl.showTitleBar = checked
                    }

                    Text {
                        text: "Background Toggle";
                        color: "#AAA";
                        width: 200;
                        font.family: mainFont
                    }
                    Switch {
                        checked: ctrl.showBackground
                        onToggled: ctrl.showBackground = checked
                    }

                    Text {
                        text: "Click-Through Mode";
                        color: "#AAA";
                        width: 200;
                        font.family: mainFont
                    }
                    Switch {
                        checked: ctrl.clickThrough
                        onToggled: ctrl.clickThrough = checked
                    }
                }

                Rectangle {
                    width: parent.width - 80;
                    height: 100;
                    color: "#1a1a1a";
                    radius: 10
                    border.color: "#333"
                    Text {
                        anchors.centerIn: parent;
                        width: parent.width - 40
                        text: "⚠️ Click-Through Mode locks the overlay in place so you can play your game. To move it again, toggle this OFF from this menu.";
                        color: "#666";
                        font.pixelSize: 12;
                        wrapMode: Text.WordWrap;
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
    Dialog {
        id: globalUnsavedDialog
        modal: true
        focus: true
        anchors.centerIn: parent
        implicitWidth: 360

        property string pendingAction: ""

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
        }
        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 120; easing.type: Easing.InCubic }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.85; duration: 120; easing.type: Easing.InCubic }
        }

        background: Rectangle {
            color: "#17191C"
            border.color: "#2D3238"
            border.width: 1
            radius: 8
        }

        contentItem: Item {
            implicitWidth: layoutUnsaved.implicitWidth + 32
            implicitHeight: layoutUnsaved.implicitHeight + 32

            ColumnLayout {
                id: layoutUnsaved
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Text {
                    text: "Unsaved Changes"
                    color: "white"
                    font.family: mainFont
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: "You have unsaved changes in your current profile. Would you like to save them before switching?"
                    color: "#7C848E"
                    font.family: mainFont
                    font.pixelSize: 12
                    Layout.maximumWidth: 300
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Layout.topMargin: 4
                    spacing: 8

                    // 1. Cancel Button
                    Button {
                        text: "Cancel"
                        onClicked: {
                            globalUnsavedDialog.pendingAction = ""
                            globalUnsavedDialog.close()
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#23272D" : "#15181B"
                            border.color: "#2D3238"
                            border.width: 1
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#7C848E"
                            font.family: mainFont
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // 2. Discard Button
                    Button {
                        text: "Discard"
                        onClicked: {
                                let action = globalUnsavedDialog.pendingAction
                                globalUnsavedDialog.pendingAction = ""
                                globalUnsavedDialog.close()

                                // Discard uncommitted RAM edits and reset the dirty flag
                                ctrl.discardChanges()

                                executePendingNavigation(action)
                            }
                        background: Rectangle {
                            color: parent.hovered ? "#3A1F1F" : "#2A1515"
                            border.color: "#FF5555"
                            border.width: 1
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#FF8888"
                            font.family: mainFont
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // 3. Save Changes Button
                    Button {
                        text: "Save Changes"
                        onClicked: {
                            ctrl.saveCurrentProfile()
                            let action = globalUnsavedDialog.pendingAction
                            globalUnsavedDialog.pendingAction = ""
                            globalUnsavedDialog.close()

                            executePendingNavigation(action)
                        }
                        background: Rectangle {
                            color: parent.hovered ? "#15B8F5" : "#0099FF"
                            radius: 6
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.family: mainFont
                            font.bold: true
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}