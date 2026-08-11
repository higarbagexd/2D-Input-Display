import QtQuick
import QtQuick.Shapes
import com.overlay.controls 1.0

Item {
    id: presetRoot
    width: 450
    height: 450

    // Properties linked to MouseBridge singleton
    property bool leftPressed: MouseBridge.effectiveLeftPressed
    property bool rightPressed: MouseBridge.effectiveRightPressed
    property bool middlePressed: MouseBridge.effectiveMiddlePressed
    property bool upperPressed: MouseBridge.effectiveUpperPressed
    property bool lowerPressed: MouseBridge.effectiveLowerPressed

    // Live movement values from MouseBridge (used by the dot/ring below).
    // dotX/dotY are an offset from center that grows as the mouse moves and
    // decays back toward 0 when it stops, clamped to +/- maxRadius.
    property real liveDotX: MouseBridge.dotX
    property real liveDotY: MouseBridge.dotY
    property real liveMaxRadius: MouseBridge.maxRadius

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Item {
            id: mouseCanvas
            width: 424.0
            height: 598.0
            anchors.centerIn: parent
            // Whole icon traced at 2x native resolution from your reference images.
            // Scale this Item (not the path data) if you need it bigger/smaller —
            // e.g. add "scale: 0.6" here and it stays crisp.
            scale: 0.6
            // 1. Main Mouse Body Outline
            Shape {
                id: bodyOutline
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2.5
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 47.0; startY: 265.0
                    PathLine { x: 41.0; y: 269.0 }
                    PathLine { x: 37.0; y: 275.0 }
                    PathLine { x: 35.0; y: 281.0 }
                    PathLine { x: 35.0; y: 287.0 }
                    PathLine { x: 37.0; y: 293.0 }
                    PathLine { x: 39.0; y: 299.0 }
                    PathLine { x: 45.0; y: 299.0 }
                    PathLine { x: 51.0; y: 299.0 }
                    PathLine { x: 57.0; y: 299.0 }
                    PathLine { x: 63.0; y: 299.0 }
                    PathLine { x: 69.0; y: 301.0 }
                    PathLine { x: 75.0; y: 305.0 }
                    PathLine { x: 77.0; y: 311.0 }
                    PathLine { x: 79.0; y: 317.0 }
                    PathLine { x: 81.0; y: 323.0 }
                    PathLine { x: 81.0; y: 329.0 }
                    PathLine { x: 83.0; y: 335.0 }
                    PathLine { x: 83.0; y: 341.0 }
                    PathLine { x: 85.0; y: 347.0 }
                    PathLine { x: 85.0; y: 353.0 }
                    PathLine { x: 87.0; y: 359.0 }
                    PathLine { x: 89.0; y: 365.0 }
                    PathLine { x: 89.0; y: 371.0 }
                    PathLine { x: 91.0; y: 377.0 }
                    PathLine { x: 91.0; y: 383.0 }
                    PathLine { x: 93.0; y: 389.0 }
                    PathLine { x: 93.0; y: 395.0 }
                    PathLine { x: 95.0; y: 401.0 }
                    PathLine { x: 97.0; y: 407.0 }
                    PathLine { x: 97.0; y: 413.0 }
                    PathLine { x: 99.0; y: 419.0 }
                    PathLine { x: 101.0; y: 425.0 }
                    PathLine { x: 101.0; y: 431.0 }
                    PathLine { x: 103.0; y: 437.0 }
                    PathLine { x: 103.0; y: 443.0 }
                    PathLine { x: 105.0; y: 449.0 }
                    PathLine { x: 105.0; y: 455.0 }
                    PathLine { x: 107.0; y: 461.0 }
                    PathLine { x: 107.0; y: 467.0 }
                    PathLine { x: 105.0; y: 473.0 }
                    PathLine { x: 99.0; y: 475.0 }
                    PathLine { x: 93.0; y: 475.0 }
                    PathLine { x: 87.0; y: 475.0 }
                    PathLine { x: 81.0; y: 475.0 }
                    PathLine { x: 75.0; y: 475.0 }
                    PathLine { x: 73.0; y: 481.0 }
                    PathLine { x: 75.0; y: 487.0 }
                    PathLine { x: 77.0; y: 493.0 }
                    PathLine { x: 77.0; y: 499.0 }
                    PathLine { x: 79.0; y: 505.0 }
                    PathLine { x: 79.0; y: 511.0 }
                    PathLine { x: 81.0; y: 517.0 }
                    PathLine { x: 81.0; y: 523.0 }
                    PathLine { x: 83.0; y: 529.0 }
                    PathLine { x: 85.0; y: 535.0 }
                    PathLine { x: 85.0; y: 541.0 }
                    PathLine { x: 87.0; y: 547.0 }
                    PathLine { x: 89.0; y: 553.0 }
                    PathLine { x: 89.0; y: 559.0 }
                    PathLine { x: 91.0; y: 565.0 }
                    PathLine { x: 93.0; y: 571.0 }
                    PathLine { x: 99.0; y: 577.0 }
                    PathLine { x: 105.0; y: 581.0 }
                    PathLine { x: 111.0; y: 583.0 }
                    PathLine { x: 117.0; y: 583.0 }
                    PathLine { x: 123.0; y: 583.0 }
                    PathLine { x: 129.0; y: 583.0 }
                    PathLine { x: 135.0; y: 583.0 }
                    PathLine { x: 141.0; y: 583.0 }
                    PathLine { x: 147.0; y: 583.0 }
                    PathLine { x: 153.0; y: 583.0 }
                    PathLine { x: 159.0; y: 583.0 }
                    PathLine { x: 165.0; y: 583.0 }
                    PathLine { x: 171.0; y: 583.0 }
                    PathLine { x: 177.0; y: 583.0 }
                    PathLine { x: 183.0; y: 583.0 }
                    PathLine { x: 189.0; y: 583.0 }
                    PathLine { x: 195.0; y: 583.0 }
                    PathLine { x: 201.0; y: 583.0 }
                    PathLine { x: 207.0; y: 583.0 }
                    PathLine { x: 213.0; y: 583.0 }
                    PathLine { x: 219.0; y: 583.0 }
                    PathLine { x: 225.0; y: 583.0 }
                    PathLine { x: 231.0; y: 583.0 }
                    PathLine { x: 237.0; y: 583.0 }
                    PathLine { x: 243.0; y: 583.0 }
                    PathLine { x: 249.0; y: 583.0 }
                    PathLine { x: 255.0; y: 583.0 }
                    PathLine { x: 261.0; y: 583.0 }
                    PathLine { x: 267.0; y: 583.0 }
                    PathLine { x: 273.0; y: 583.0 }
                    PathLine { x: 279.0; y: 583.0 }
                    PathLine { x: 285.0; y: 583.0 }
                    PathLine { x: 291.0; y: 583.0 }
                    PathLine { x: 297.0; y: 583.0 }
                    PathLine { x: 303.0; y: 583.0 }
                    PathLine { x: 309.0; y: 583.0 }
                    PathLine { x: 315.0; y: 583.0 }
                    PathLine { x: 321.0; y: 583.0 }
                    PathLine { x: 327.0; y: 583.0 }
                    PathLine { x: 333.0; y: 583.0 }
                    PathLine { x: 339.0; y: 581.0 }
                    PathLine { x: 345.0; y: 577.0 }
                    PathLine { x: 349.0; y: 573.0 }
                    PathLine { x: 353.0; y: 567.0 }
                    PathLine { x: 355.0; y: 561.0 }
                    PathLine { x: 357.0; y: 555.0 }
                    PathLine { x: 359.0; y: 549.0 }
                    PathLine { x: 359.0; y: 543.0 }
                    PathLine { x: 361.0; y: 537.0 }
                    PathLine { x: 361.0; y: 531.0 }
                    PathLine { x: 363.0; y: 525.0 }
                    PathLine { x: 365.0; y: 519.0 }
                    PathLine { x: 365.0; y: 513.0 }
                    PathLine { x: 367.0; y: 507.0 }
                    PathLine { x: 367.0; y: 501.0 }
                    PathLine { x: 369.0; y: 495.0 }
                    PathLine { x: 369.0; y: 489.0 }
                    PathLine { x: 371.0; y: 483.0 }
                    PathLine { x: 373.0; y: 477.0 }
                    PathLine { x: 373.0; y: 471.0 }
                    PathLine { x: 375.0; y: 465.0 }
                    PathLine { x: 375.0; y: 459.0 }
                    PathLine { x: 377.0; y: 453.0 }
                    PathLine { x: 379.0; y: 447.0 }
                    PathLine { x: 379.0; y: 441.0 }
                    PathLine { x: 381.0; y: 435.0 }
                    PathLine { x: 381.0; y: 429.0 }
                    PathLine { x: 383.0; y: 423.0 }
                    PathLine { x: 385.0; y: 417.0 }
                    PathLine { x: 385.0; y: 411.0 }
                    PathLine { x: 387.0; y: 405.0 }
                    PathLine { x: 387.0; y: 399.0 }
                    PathLine { x: 389.0; y: 393.0 }
                    PathLine { x: 391.0; y: 387.0 }
                    PathLine { x: 391.0; y: 381.0 }
                    PathLine { x: 393.0; y: 375.0 }
                    PathLine { x: 393.0; y: 369.0 }
                    PathLine { x: 395.0; y: 363.0 }
                    PathLine { x: 397.0; y: 357.0 }
                    PathLine { x: 397.0; y: 351.0 }
                    PathLine { x: 399.0; y: 345.0 }
                    PathLine { x: 399.0; y: 339.0 }
                    PathLine { x: 401.0; y: 333.0 }
                    PathLine { x: 401.0; y: 327.0 }
                    PathLine { x: 403.0; y: 321.0 }
                    PathLine { x: 405.0; y: 315.0 }
                    PathLine { x: 405.0; y: 309.0 }
                    PathLine { x: 407.0; y: 303.0 }
                    PathLine { x: 407.0; y: 297.0 }
                    PathLine { x: 409.0; y: 291.0 }
                    PathLine { x: 409.0; y: 285.0 }
                    PathLine { x: 409.0; y: 279.0 }
                    PathLine { x: 407.0; y: 273.0 }
                    PathLine { x: 401.0; y: 267.0 }
                    PathLine { x: 395.0; y: 265.0 }
                    PathLine { x: 389.0; y: 265.0 }
                    PathLine { x: 383.0; y: 265.0 }
                    PathLine { x: 377.0; y: 265.0 }
                    PathLine { x: 371.0; y: 265.0 }
                    PathLine { x: 365.0; y: 265.0 }
                    PathLine { x: 359.0; y: 265.0 }
                    PathLine { x: 353.0; y: 265.0 }
                    PathLine { x: 347.0; y: 265.0 }
                    PathLine { x: 341.0; y: 265.0 }
                    PathLine { x: 335.0; y: 265.0 }
                    PathLine { x: 329.0; y: 265.0 }
                    PathLine { x: 323.0; y: 265.0 }
                    PathLine { x: 317.0; y: 265.0 }
                    PathLine { x: 311.0; y: 265.0 }
                    PathLine { x: 305.0; y: 265.0 }
                    PathLine { x: 299.0; y: 265.0 }
                    PathLine { x: 293.0; y: 265.0 }
                    PathLine { x: 287.0; y: 265.0 }
                    PathLine { x: 281.0; y: 265.0 }
                    PathLine { x: 275.0; y: 265.0 }
                    PathLine { x: 269.0; y: 265.0 }
                    PathLine { x: 263.0; y: 265.0 }
                    PathLine { x: 257.0; y: 265.0 }
                    PathLine { x: 251.0; y: 265.0 }
                    PathLine { x: 245.0; y: 265.0 }
                    PathLine { x: 239.0; y: 265.0 }
                    PathLine { x: 233.0; y: 265.0 }
                    PathLine { x: 227.0; y: 265.0 }
                    PathLine { x: 221.0; y: 265.0 }
                    PathLine { x: 215.0; y: 265.0 }
                    PathLine { x: 209.0; y: 265.0 }
                    PathLine { x: 203.0; y: 265.0 }
                    PathLine { x: 197.0; y: 265.0 }
                    PathLine { x: 191.0; y: 265.0 }
                    PathLine { x: 185.0; y: 265.0 }
                    PathLine { x: 179.0; y: 265.0 }
                    PathLine { x: 173.0; y: 265.0 }
                    PathLine { x: 167.0; y: 265.0 }
                    PathLine { x: 161.0; y: 265.0 }
                    PathLine { x: 155.0; y: 265.0 }
                    PathLine { x: 149.0; y: 265.0 }
                    PathLine { x: 143.0; y: 265.0 }
                    PathLine { x: 137.0; y: 265.0 }
                    PathLine { x: 131.0; y: 265.0 }
                    PathLine { x: 125.0; y: 265.0 }
                    PathLine { x: 119.0; y: 265.0 }
                    PathLine { x: 113.0; y: 265.0 }
                    PathLine { x: 107.0; y: 265.0 }
                    PathLine { x: 101.0; y: 265.0 }
                    PathLine { x: 95.0; y: 265.0 }
                    PathLine { x: 89.0; y: 265.0 }
                    PathLine { x: 83.0; y: 265.0 }
                    PathLine { x: 77.0; y: 265.0 }
                    PathLine { x: 71.0; y: 265.0 }
                    PathLine { x: 65.0; y: 265.0 }
                    PathLine { x: 59.0; y: 265.0 }
                    PathLine { x: 53.0; y: 265.0 }
                    PathLine { x: 47.0; y: 265.0 }
                }
            }

            // 2. Left Click Button
            Shape {
                id: leftButton
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2.5
                    fillColor: leftPressed ? "#ffffff" : "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 121.0; startY: 35.0
                    PathLine { x: 115.0; y: 37.0 }
                    PathLine { x: 109.0; y: 37.0 }
                    PathLine { x: 103.0; y: 37.0 }
                    PathLine { x: 97.0; y: 41.0 }
                    PathLine { x: 91.0; y: 45.0 }
                    PathLine { x: 87.0; y: 51.0 }
                    PathLine { x: 83.0; y: 57.0 }
                    PathLine { x: 81.0; y: 63.0 }
                    PathLine { x: 81.0; y: 69.0 }
                    PathLine { x: 79.0; y: 75.0 }
                    PathLine { x: 77.0; y: 81.0 }
                    PathLine { x: 75.0; y: 87.0 }
                    PathLine { x: 73.0; y: 93.0 }
                    PathLine { x: 73.0; y: 99.0 }
                    PathLine { x: 71.0; y: 105.0 }
                    PathLine { x: 69.0; y: 111.0 }
                    PathLine { x: 67.0; y: 117.0 }
                    PathLine { x: 67.0; y: 123.0 }
                    PathLine { x: 65.0; y: 129.0 }
                    PathLine { x: 63.0; y: 135.0 }
                    PathLine { x: 61.0; y: 141.0 }
                    PathLine { x: 59.0; y: 147.0 }
                    PathLine { x: 59.0; y: 153.0 }
                    PathLine { x: 57.0; y: 159.0 }
                    PathLine { x: 55.0; y: 165.0 }
                    PathLine { x: 53.0; y: 171.0 }
                    PathLine { x: 53.0; y: 177.0 }
                    PathLine { x: 51.0; y: 183.0 }
                    PathLine { x: 49.0; y: 189.0 }
                    PathLine { x: 47.0; y: 195.0 }
                    PathLine { x: 45.0; y: 201.0 }
                    PathLine { x: 45.0; y: 207.0 }
                    PathLine { x: 43.0; y: 213.0 }
                    PathLine { x: 41.0; y: 219.0 }
                    PathLine { x: 41.0; y: 225.0 }
                    PathLine { x: 37.0; y: 231.0 }
                    PathLine { x: 37.0; y: 237.0 }
                    PathLine { x: 35.0; y: 243.0 }
                    PathLine { x: 37.0; y: 249.0 }
                    PathLine { x: 37.0; y: 255.0 }
                    PathLine { x: 43.0; y: 261.0 }
                    PathLine { x: 49.0; y: 263.0 }
                    PathLine { x: 55.0; y: 265.0 }
                    PathLine { x: 61.0; y: 265.0 }
                    PathLine { x: 67.0; y: 265.0 }
                    PathLine { x: 73.0; y: 265.0 }
                    PathLine { x: 79.0; y: 265.0 }
                    PathLine { x: 85.0; y: 265.0 }
                    PathLine { x: 91.0; y: 265.0 }
                    PathLine { x: 97.0; y: 265.0 }
                    PathLine { x: 103.0; y: 265.0 }
                    PathLine { x: 109.0; y: 265.0 }
                    PathLine { x: 115.0; y: 265.0 }
                    PathLine { x: 121.0; y: 265.0 }
                    PathLine { x: 127.0; y: 265.0 }
                    PathLine { x: 133.0; y: 265.0 }
                    PathLine { x: 139.0; y: 265.0 }
                    PathLine { x: 145.0; y: 265.0 }
                    PathLine { x: 151.0; y: 265.0 }
                    PathLine { x: 157.0; y: 263.0 }
                    PathLine { x: 163.0; y: 261.0 }
                    PathLine { x: 169.0; y: 259.0 }
                    PathLine { x: 173.0; y: 253.0 }
                    PathLine { x: 177.0; y: 247.0 }
                    PathLine { x: 177.0; y: 241.0 }
                    PathLine { x: 177.0; y: 235.0 }
                    PathLine { x: 177.0; y: 229.0 }
                    PathLine { x: 177.0; y: 223.0 }
                    PathLine { x: 177.0; y: 217.0 }
                    PathLine { x: 177.0; y: 211.0 }
                    PathLine { x: 177.0; y: 205.0 }
                    PathLine { x: 177.0; y: 199.0 }
                    PathLine { x: 177.0; y: 193.0 }
                    PathLine { x: 177.0; y: 187.0 }
                    PathLine { x: 177.0; y: 181.0 }
                    PathLine { x: 177.0; y: 175.0 }
                    PathLine { x: 177.0; y: 169.0 }
                    PathLine { x: 177.0; y: 163.0 }
                    PathLine { x: 177.0; y: 157.0 }
                    PathLine { x: 179.0; y: 151.0 }
                    PathLine { x: 181.0; y: 145.0 }
                    PathLine { x: 185.0; y: 139.0 }
                    PathLine { x: 189.0; y: 133.0 }
                    PathLine { x: 195.0; y: 129.0 }
                    PathLine { x: 201.0; y: 127.0 }
                    PathLine { x: 207.0; y: 127.0 }
                    PathLine { x: 213.0; y: 125.0 }
                    PathLine { x: 217.0; y: 123.0 }
                    PathLine { x: 217.0; y: 117.0 }
                    PathLine { x: 217.0; y: 111.0 }
                    PathLine { x: 217.0; y: 105.0 }
                    PathLine { x: 217.0; y: 99.0 }
                    PathLine { x: 217.0; y: 93.0 }
                    PathLine { x: 217.0; y: 87.0 }
                    PathLine { x: 217.0; y: 81.0 }
                    PathLine { x: 217.0; y: 75.0 }
                    PathLine { x: 217.0; y: 69.0 }
                    PathLine { x: 219.0; y: 63.0 }
                    PathLine { x: 217.0; y: 57.0 }
                    PathLine { x: 217.0; y: 51.0 }
                    PathLine { x: 215.0; y: 45.0 }
                    PathLine { x: 209.0; y: 39.0 }
                    PathLine { x: 203.0; y: 37.0 }
                    PathLine { x: 197.0; y: 37.0 }
                    PathLine { x: 191.0; y: 37.0 }
                    PathLine { x: 185.0; y: 37.0 }
                    PathLine { x: 179.0; y: 37.0 }
                    PathLine { x: 173.0; y: 37.0 }
                    PathLine { x: 167.0; y: 37.0 }
                    PathLine { x: 161.0; y: 37.0 }
                    PathLine { x: 155.0; y: 37.0 }
                    PathLine { x: 149.0; y: 37.0 }
                    PathLine { x: 143.0; y: 37.0 }
                    PathLine { x: 137.0; y: 37.0 }
                    PathLine { x: 131.0; y: 37.0 }
                    PathLine { x: 125.0; y: 37.0 }
                    PathLine { x: 121.0; y: 35.0 }
                }
            }

            // 3. Right Click Button
            Shape {
                id: rightButton
                anchors.fill: parent
                antialiasing: true
                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2.5
                    fillColor: rightPressed ? "#ffffff" : "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 255.0; startY: 35.0
                    PathLine { x: 249.0; y: 37.0 }
                    PathLine { x: 243.0; y: 37.0 }
                    PathLine { x: 237.0; y: 39.0 }
                    PathLine { x: 231.0; y: 43.0 }
                    PathLine { x: 229.0; y: 49.0 }
                    PathLine { x: 227.0; y: 55.0 }
                    PathLine { x: 227.0; y: 61.0 }
                    PathLine { x: 227.0; y: 67.0 }
                    PathLine { x: 227.0; y: 73.0 }
                    PathLine { x: 227.0; y: 79.0 }
                    PathLine { x: 227.0; y: 85.0 }
                    PathLine { x: 227.0; y: 91.0 }
                    PathLine { x: 227.0; y: 97.0 }
                    PathLine { x: 227.0; y: 103.0 }
                    PathLine { x: 227.0; y: 109.0 }
                    PathLine { x: 227.0; y: 115.0 }
                    PathLine { x: 227.0; y: 121.0 }
                    PathLine { x: 229.0; y: 125.0 }
                    PathLine { x: 235.0; y: 125.0 }
                    PathLine { x: 241.0; y: 127.0 }
                    PathLine { x: 247.0; y: 129.0 }
                    PathLine { x: 253.0; y: 131.0 }
                    PathLine { x: 259.0; y: 137.0 }
                    PathLine { x: 263.0; y: 143.0 }
                    PathLine { x: 265.0; y: 149.0 }
                    PathLine { x: 267.0; y: 155.0 }
                    PathLine { x: 267.0; y: 161.0 }
                    PathLine { x: 267.0; y: 167.0 }
                    PathLine { x: 267.0; y: 173.0 }
                    PathLine { x: 267.0; y: 179.0 }
                    PathLine { x: 267.0; y: 185.0 }
                    PathLine { x: 267.0; y: 191.0 }
                    PathLine { x: 267.0; y: 197.0 }
                    PathLine { x: 267.0; y: 203.0 }
                    PathLine { x: 267.0; y: 209.0 }
                    PathLine { x: 267.0; y: 215.0 }
                    PathLine { x: 267.0; y: 221.0 }
                    PathLine { x: 267.0; y: 227.0 }
                    PathLine { x: 267.0; y: 233.0 }
                    PathLine { x: 267.0; y: 239.0 }
                    PathLine { x: 269.0; y: 245.0 }
                    PathLine { x: 269.0; y: 251.0 }
                    PathLine { x: 275.0; y: 257.0 }
                    PathLine { x: 281.0; y: 261.0 }
                    PathLine { x: 287.0; y: 263.0 }
                    PathLine { x: 293.0; y: 265.0 }
                    PathLine { x: 299.0; y: 265.0 }
                    PathLine { x: 305.0; y: 265.0 }
                    PathLine { x: 311.0; y: 265.0 }
                    PathLine { x: 317.0; y: 265.0 }
                    PathLine { x: 323.0; y: 265.0 }
                    PathLine { x: 329.0; y: 265.0 }
                    PathLine { x: 335.0; y: 265.0 }
                    PathLine { x: 341.0; y: 265.0 }
                    PathLine { x: 347.0; y: 265.0 }
                    PathLine { x: 353.0; y: 265.0 }
                    PathLine { x: 359.0; y: 265.0 }
                    PathLine { x: 365.0; y: 265.0 }
                    PathLine { x: 371.0; y: 265.0 }
                    PathLine { x: 377.0; y: 265.0 }
                    PathLine { x: 383.0; y: 265.0 }
                    PathLine { x: 389.0; y: 265.0 }
                    PathLine { x: 395.0; y: 265.0 }
                    PathLine { x: 401.0; y: 261.0 }
                    PathLine { x: 405.0; y: 257.0 }
                    PathLine { x: 409.0; y: 251.0 }
                    PathLine { x: 409.0; y: 245.0 }
                    PathLine { x: 409.0; y: 239.0 }
                    PathLine { x: 407.0; y: 233.0 }
                    PathLine { x: 405.0; y: 227.0 }
                    PathLine { x: 405.0; y: 221.0 }
                    PathLine { x: 403.0; y: 215.0 }
                    PathLine { x: 401.0; y: 209.0 }
                    PathLine { x: 399.0; y: 203.0 }
                    PathLine { x: 399.0; y: 197.0 }
                    PathLine { x: 397.0; y: 191.0 }
                    PathLine { x: 395.0; y: 185.0 }
                    PathLine { x: 393.0; y: 179.0 }
                    PathLine { x: 391.0; y: 173.0 }
                    PathLine { x: 391.0; y: 167.0 }
                    PathLine { x: 389.0; y: 161.0 }
                    PathLine { x: 387.0; y: 155.0 }
                    PathLine { x: 385.0; y: 149.0 }
                    PathLine { x: 385.0; y: 143.0 }
                    PathLine { x: 383.0; y: 137.0 }
                    PathLine { x: 381.0; y: 131.0 }
                    PathLine { x: 379.0; y: 125.0 }
                    PathLine { x: 377.0; y: 119.0 }
                    PathLine { x: 377.0; y: 113.0 }
                    PathLine { x: 375.0; y: 107.0 }
                    PathLine { x: 373.0; y: 101.0 }
                    PathLine { x: 371.0; y: 95.0 }
                    PathLine { x: 369.0; y: 89.0 }
                    PathLine { x: 369.0; y: 83.0 }
                    PathLine { x: 367.0; y: 77.0 }
                    PathLine { x: 365.0; y: 71.0 }
                    PathLine { x: 363.0; y: 65.0 }
                    PathLine { x: 363.0; y: 59.0 }
                    PathLine { x: 359.0; y: 53.0 }
                    PathLine { x: 355.0; y: 47.0 }
                    PathLine { x: 351.0; y: 43.0 }
                    PathLine { x: 345.0; y: 39.0 }
                    PathLine { x: 339.0; y: 37.0 }
                    PathLine { x: 333.0; y: 35.0 }
                    PathLine { x: 327.0; y: 37.0 }
                    PathLine { x: 321.0; y: 35.0 }
                    PathLine { x: 315.0; y: 37.0 }
                    PathLine { x: 309.0; y: 37.0 }
                    PathLine { x: 303.0; y: 37.0 }
                    PathLine { x: 297.0; y: 37.0 }
                    PathLine { x: 291.0; y: 35.0 }
                    PathLine { x: 285.0; y: 37.0 }
                    PathLine { x: 279.0; y: 37.0 }
                    PathLine { x: 273.0; y: 37.0 }
                    PathLine { x: 267.0; y: 37.0 }
                    PathLine { x: 261.0; y: 37.0 }
                    PathLine { x: 255.0; y: 35.0 }
                }
            }

            // 4. Scroll Wheel / Middle Button — separate floating pill, not connected to either dome
            Shape {
                id: scrollWheel
                anchors.fill: parent
                antialiasing: true
                z: 2
                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2.5
                    fillColor: middlePressed ? "#ffffff" : "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 211.0; startY: 139.0
                    PathLine { x: 205.0; y: 141.0 }
                    PathLine { x: 199.0; y: 147.0 }
                    PathLine { x: 195.0; y: 153.0 }
                    PathLine { x: 193.0; y: 159.0 }
                    PathLine { x: 191.0; y: 165.0 }
                    PathLine { x: 191.0; y: 171.0 }
                    PathLine { x: 191.0; y: 177.0 }
                    PathLine { x: 191.0; y: 183.0 }
                    PathLine { x: 191.0; y: 189.0 }
                    PathLine { x: 191.0; y: 195.0 }
                    PathLine { x: 191.0; y: 201.0 }
                    PathLine { x: 191.0; y: 207.0 }
                    PathLine { x: 191.0; y: 213.0 }
                    PathLine { x: 191.0; y: 219.0 }
                    PathLine { x: 191.0; y: 225.0 }
                    PathLine { x: 191.0; y: 231.0 }
                    PathLine { x: 191.0; y: 237.0 }
                    PathLine { x: 191.0; y: 243.0 }
                    PathLine { x: 193.0; y: 249.0 }
                    PathLine { x: 197.0; y: 255.0 }
                    PathLine { x: 201.0; y: 261.0 }
                    PathLine { x: 207.0; y: 263.0 }
                    PathLine { x: 213.0; y: 265.0 }
                    PathLine { x: 219.0; y: 265.0 }
                    PathLine { x: 225.0; y: 265.0 }
                    PathLine { x: 231.0; y: 265.0 }
                    PathLine { x: 237.0; y: 265.0 }
                    PathLine { x: 243.0; y: 261.0 }
                    PathLine { x: 247.0; y: 257.0 }
                    PathLine { x: 251.0; y: 251.0 }
                    PathLine { x: 253.0; y: 245.0 }
                    PathLine { x: 253.0; y: 239.0 }
                    PathLine { x: 253.0; y: 233.0 }
                    PathLine { x: 253.0; y: 227.0 }
                    PathLine { x: 253.0; y: 221.0 }
                    PathLine { x: 253.0; y: 215.0 }
                    PathLine { x: 253.0; y: 209.0 }
                    PathLine { x: 253.0; y: 203.0 }
                    PathLine { x: 253.0; y: 197.0 }
                    PathLine { x: 253.0; y: 191.0 }
                    PathLine { x: 253.0; y: 185.0 }
                    PathLine { x: 253.0; y: 179.0 }
                    PathLine { x: 253.0; y: 173.0 }
                    PathLine { x: 253.0; y: 167.0 }
                    PathLine { x: 253.0; y: 161.0 }
                    PathLine { x: 251.0; y: 155.0 }
                    PathLine { x: 249.0; y: 149.0 }
                    PathLine { x: 243.0; y: 143.0 }
                    PathLine { x: 237.0; y: 141.0 }
                    PathLine { x: 231.0; y: 139.0 }
                    PathLine { x: 225.0; y: 139.0 }
                    PathLine { x: 219.0; y: 139.0 }
                    PathLine { x: 213.0; y: 139.0 }
                    PathLine { x: 211.0; y: 139.0 }
                }
            }

            // 5. Upper Side Button
            Shape {
                id: sideButtonTop
                anchors.fill: parent
                antialiasing: true
                z: 2
                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2.5
                    fillColor: upperPressed ? "#ffffff" : "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 39.0; startY: 309.0
                    PathLine { x: 33.0; y: 313.0 }
                    PathLine { x: 33.0; y: 319.0 }
                    PathLine { x: 33.0; y: 325.0 }
                    PathLine { x: 35.0; y: 331.0 }
                    PathLine { x: 37.0; y: 337.0 }
                    PathLine { x: 37.0; y: 343.0 }
                    PathLine { x: 39.0; y: 349.0 }
                    PathLine { x: 39.0; y: 355.0 }
                    PathLine { x: 41.0; y: 361.0 }
                    PathLine { x: 43.0; y: 367.0 }
                    PathLine { x: 43.0; y: 373.0 }
                    PathLine { x: 47.0; y: 379.0 }
                    PathLine { x: 53.0; y: 381.0 }
                    PathLine { x: 59.0; y: 383.0 }
                    PathLine { x: 65.0; y: 383.0 }
                    PathLine { x: 71.0; y: 383.0 }
                    PathLine { x: 77.0; y: 381.0 }
                    PathLine { x: 81.0; y: 377.0 }
                    PathLine { x: 81.0; y: 371.0 }
                    PathLine { x: 79.0; y: 365.0 }
                    PathLine { x: 79.0; y: 359.0 }
                    PathLine { x: 77.0; y: 353.0 }
                    PathLine { x: 75.0; y: 347.0 }
                    PathLine { x: 75.0; y: 341.0 }
                    PathLine { x: 73.0; y: 335.0 }
                    PathLine { x: 73.0; y: 329.0 }
                    PathLine { x: 71.0; y: 323.0 }
                    PathLine { x: 69.0; y: 317.0 }
                    PathLine { x: 65.0; y: 311.0 }
                    PathLine { x: 59.0; y: 309.0 }
                    PathLine { x: 53.0; y: 309.0 }
                    PathLine { x: 47.0; y: 309.0 }
                    PathLine { x: 41.0; y: 309.0 }
                    PathLine { x: 39.0; y: 309.0 }
                }
            }

            // 6. Lower Side Button
            Shape {
                id: sideButtonBottom
                anchors.fill: parent
                antialiasing: true
                z: 2
                ShapePath {
                    strokeColor: "white"
                    strokeWidth: 2.5
                    fillColor: lowerPressed ? "#ffffff" : "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    startX: 53.0; startY: 391.0
                    PathLine { x: 49.0; y: 397.0 }
                    PathLine { x: 49.0; y: 403.0 }
                    PathLine { x: 51.0; y: 409.0 }
                    PathLine { x: 51.0; y: 415.0 }
                    PathLine { x: 53.0; y: 421.0 }
                    PathLine { x: 53.0; y: 427.0 }
                    PathLine { x: 55.0; y: 433.0 }
                    PathLine { x: 57.0; y: 439.0 }
                    PathLine { x: 57.0; y: 445.0 }
                    PathLine { x: 59.0; y: 451.0 }
                    PathLine { x: 61.0; y: 457.0 }
                    PathLine { x: 65.0; y: 463.0 }
                    PathLine { x: 71.0; y: 465.0 }
                    PathLine { x: 77.0; y: 465.0 }
                    PathLine { x: 83.0; y: 465.0 }
                    PathLine { x: 89.0; y: 465.0 }
                    PathLine { x: 95.0; y: 463.0 }
                    PathLine { x: 97.0; y: 457.0 }
                    PathLine { x: 95.0; y: 451.0 }
                    PathLine { x: 95.0; y: 445.0 }
                    PathLine { x: 93.0; y: 439.0 }
                    PathLine { x: 93.0; y: 433.0 }
                    PathLine { x: 91.0; y: 427.0 }
                    PathLine { x: 91.0; y: 421.0 }
                    PathLine { x: 89.0; y: 415.0 }
                    PathLine { x: 87.0; y: 409.0 }
                    PathLine { x: 87.0; y: 403.0 }
                    PathLine { x: 85.0; y: 397.0 }
                    PathLine { x: 79.0; y: 391.0 }
                    PathLine { x: 73.0; y: 391.0 }
                    PathLine { x: 67.0; y: 391.0 }
                    PathLine { x: 61.0; y: 391.0 }
                    PathLine { x: 55.0; y: 391.0 }
                    PathLine { x: 53.0; y: 391.0 }
                }
            }

            // 7. Movement Indicator — ring + dot showing live mouse movement
            // (this is a real circle, not a hand-traced path like the shapes above,
            // so it's just a Rectangle with radius = half its width/height)
            Item {
                id: movementIndicator
                anchors.fill: parent
                z: 3

                // Where the ring/dot sit, in the same 424x598 coordinate space
                // used by all the paths above. Placed low in the body, clear of
                // every button shape (buttons only go down to about y:265).
                property real centerX: 222.0
                property real centerY: 420.0

                // How big the ring is drawn. Kept smaller than the body's edges
                // at this height so there's visible margin all the way around.
                property real ringRadius: 70.0

                // Turn MouseBridge's raw offset into a position inside the ring.
                // MouseBridge clamps dotX/dotY to +/- maxRadius, so dividing by
                // maxRadius and multiplying by ringRadius means the dot always
                // lands inside the ring, and just touches the edge at max offset.
                property real dotOffsetX: liveMaxRadius > 0 ? (liveDotX / liveMaxRadius) * ringRadius : 0
                property real dotOffsetY: liveMaxRadius > 0 ? (liveDotY / liveMaxRadius) * ringRadius : 0

                // The ring itself: white outline, transparent inside, centered on centerX/centerY
                Rectangle {
                    width: movementIndicator.ringRadius * 2
                    height: movementIndicator.ringRadius * 2
                    radius: width / 2
                    color: "transparent"
                    border.color: "white"
                    border.width: 2.5
                    antialiasing: true
                    x: movementIndicator.centerX - width / 2
                    y: movementIndicator.centerY - height / 2
                }

                // The dot: small solid white circle, starts at center and slides
                // around inside the ring as dotOffsetX/dotOffsetY change
                Rectangle {
                    width: 14
                    height: 14
                    radius: width / 2
                    color: "white"
                    antialiasing: true
                    x: movementIndicator.centerX + movementIndicator.dotOffsetX - width / 2
                    y: movementIndicator.centerY + movementIndicator.dotOffsetY - height / 2
                }
            }
        }
    }
}
