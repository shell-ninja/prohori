import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Rectangle {
    id: root
    width: parent ? parent.width : Screen.width
    height: parent ? parent.height : Screen.height
    color: "#080c12"

    // Responsive scaling factor supporting 720p, 1080p, 2K (1440p), 4K (2160p), 16:10 & Ultrawide
    readonly property real scaleFactor: Math.min(width / 1920.0, height / 1080.0)
    readonly property real s: Math.max(0.48, scaleFactor)

    // Cursor for Wayland/X11
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
        onClicked: {
            root.userMenuOpen = false
            root.sessionMenuOpen = false
            passInput.forceActiveFocus()
            if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
        }
    }

    // Config options with safe fallbacks
    readonly property string themeMode: (typeof config !== "undefined" && config.themeMode) ? config.themeMode : "dark"
    readonly property bool isLight: themeMode === "light"
    readonly property bool enableWindup: typeof config === "undefined" || (config.enableWindup !== "false" && config.enableWindup !== false)
    property string hourFormat: (typeof config !== "undefined" && config.hourFormat) ? config.hourFormat : "12"
    readonly property bool enableVirtualKeyboard: (typeof config !== "undefined" && config.enableVirtualKeyboard !== undefined) ? (config.enableVirtualKeyboard === "true" || config.enableVirtualKeyboard === true) : false

    // Clean, authentic minimal color palette (no artificial sparkles/flares)
    readonly property color mainTextColor: isLight ? "#111827" : ((typeof config !== "undefined" && config.mainTextColor) ? config.mainTextColor : "#faf5ee")
    readonly property color dimTextColor: isLight ? "#6b7280" : ((typeof config !== "undefined" && config.dimTextColor) ? config.dimTextColor : "#6b7c93")
    readonly property color subTextColor: isLight ? "#4b5563" : ((typeof config !== "undefined" && config.subTextColor) ? config.subTextColor : "#94a3b8")
    readonly property color accentColor: (typeof config !== "undefined" && config.accentColor) ? config.accentColor : "#38bdf8"
    readonly property color errorColor: (typeof config !== "undefined" && config.errorColor) ? config.errorColor : "#f87171"

    readonly property color pillColor: isLight ? "#f1f5f9" : ((typeof config !== "undefined" && config.pillColor) ? config.pillColor : "#0d1520")
    readonly property color pillBorder: isLight ? "#cbd5e1" : ((typeof config !== "undefined" && config.pillBorder) ? config.pillBorder : "#1b2636")
    readonly property color pillInnerLine: isLight ? "#94a3b8" : ((typeof config !== "undefined" && config.pillInnerLine) ? config.pillInnerLine : "#2c3e55")

    readonly property string authSubtitle: (typeof config !== "undefined" && config.authSubtitle) ? config.authSubtitle : "TYPE PASSWORD OR FIDO PIN"
    readonly property string authPrompt: (typeof config !== "undefined" && config.authPrompt) ? config.authPrompt : "TRY TOUCH ONLY"

    // State Variables
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property bool userMenuOpen: false
    property bool sessionMenuOpen: false
    property bool infoDrawerOpen: false
    property bool isLoggingIn: false
    property real uiOpacity: 0
    readonly property real marginR: 90 * s

    // Reactive user & session properties
    readonly property string currentUserDisplayName: {
        if (typeof userModel !== "undefined" && userModel && userModel.rowCount() > 0) {
            var idx = Math.max(0, Math.min(root.userIndex, userModel.rowCount() - 1))
            var rname = userModel.data(userModel.index(idx, 0), 258) || ""
            var uname = userModel.data(userModel.index(idx, 0), 257) || ""
            var chosen = (rname && rname.length > 0) ? rname : uname
            if (chosen && chosen.length > 0) {
                return root.formatDisplayName(chosen)
            }
        }
        return "SHELL NINJA"
    }

    readonly property string currentUserLoginName: {
        if (typeof userModel !== "undefined" && userModel && userModel.rowCount() > 0) {
            var idx = Math.max(0, Math.min(root.userIndex, userModel.rowCount() - 1))
            var uname = userModel.data(userModel.index(idx, 0), 257) || ""
            if (uname && uname.length > 0) {
                return uname
            }
        }
        return (typeof userModel !== "undefined" && userModel && userModel.lastUser) ? userModel.lastUser : "shell-ninja"
    }

    readonly property string currentSessionDisplayName: {
        if (typeof sessionModel !== "undefined" && sessionModel && sessionModel.rowCount() > 0) {
            var idx = Math.max(0, Math.min(root.sessionIndex, sessionModel.rowCount() - 1))
            // SDDM SessionModel: 260 is NameRole, 258 is FileRole
            var sname = sessionModel.data(sessionModel.index(idx, 0), 260) || ""
            if (!sname) {
                var fpath = sessionModel.data(sessionModel.index(idx, 0), 258) || ""
                if (fpath) {
                    var parts = fpath.split("/")
                    sname = parts[parts.length - 1].replace(/\.desktop$/i, "")
                }
            }
            if (sname) {
                return root.formatSessionName(sname)
            }
        }
        return "HYPRLAND"
    }

    // High-refresh-rate synchronization (60Hz, 75Hz, 120Hz, 144Hz, 165Hz, 240Hz+)
    // FrameAnimation synchronizes directly with Qt's VSync scene graph renderer
    property int curH: new Date().getHours()
    property int curM: new Date().getMinutes()
    property int curS: new Date().getSeconds()
    property int curMS: new Date().getMilliseconds()
    readonly property real localTimeMS: (curH * 3600000) + (curM * 60000) + (curS * 1000) + curMS

    FrameAnimation {
        running: true
        onTriggered: {
            var d = new Date()
            root.curH = d.getHours()
            root.curM = d.getMinutes()
            root.curS = d.getSeconds()
            root.curMS = d.getMilliseconds()
        }
    }

    // Display Hour calculation
    readonly property int displayHour: {
        if (root.hourFormat === "24") {
            return root.curH
        }
        var h = root.curH % 12
        return h === 0 ? 12 : h
    }

    // Smooth rotation animation on login submit
    property real windupOffset: 0

    NumberAnimation {
        id: windupAnim
        target: root
        property: "windupOffset"
        from: 0
        to: 120000
        duration: 800
        easing.type: Easing.InCubic
        onFinished: root.doLogin()
    }

    readonly property real smoothSecAngle: -((localTimeMS % 60000) / 60000.0) * 360.0 - (windupOffset * 8.0)
    readonly property real smoothMinAngle: -((localTimeMS % 3600000) / 3600000.0) * 360.0 - (windupOffset * 4.0)

    // Load bundled typography with dedicated static weights
    FontLoader { id: outfitBlack; source: "fonts/Outfit-Black.ttf" }
    FontLoader { id: outfitBold; source: "fonts/Outfit-Bold.ttf" }
    FontLoader { id: outfitSemiBold; source: "fonts/Outfit-SemiBold.ttf" }
    FontLoader { id: outfitMedium; source: "fonts/Outfit-Medium.ttf" }
    FontLoader { id: outfitRegular; source: "fonts/Outfit-Regular.ttf" }

    readonly property string mainFont: outfitBlack.name.length > 0 ? outfitBlack.name : "Outfit"
    readonly property string boldFont: outfitBold.name.length > 0 ? outfitBold.name : mainFont
    readonly property string semiBoldFont: outfitSemiBold.name.length > 0 ? outfitSemiBold.name : boldFont
    readonly property string bodyFont: outfitMedium.name.length > 0 ? outfitMedium.name : (outfitRegular.name.length > 0 ? outfitRegular.name : mainFont)

    TextConstants { id: textConstants }

    // Session display name formatter (accurately supporting Hyprland UWSM)
    function formatSessionName(rawName) {
        if (!rawName) return "HYPRLAND"
        var clean = rawName.toUpperCase().trim()
        if (clean.indexOf("HYPRLAND") !== -1 && (clean.indexOf("UWSM") !== -1 || clean.indexOf("HYPRLAND-UWSM") !== -1)) {
            return "HYPRLAND (UWSM)"
        }
        if (clean.indexOf("HYPRLAND") !== -1) {
            return "HYPRLAND"
        }
        if (clean.indexOf("PLASMA") !== -1 || clean.indexOf("KDE") !== -1) {
            return "KDE PLASMA"
        }
        if (clean.indexOf("GNOME") !== -1) return "GNOME"
        if (clean.indexOf("SWAY") !== -1) return "SWAY"
        if (clean.indexOf("NIRI") !== -1) return "NIRI"
        return clean.replace(/\s*\(.*\)/g, "")
    }

    // Helper to format display username cleanly
    function formatDisplayName(rawName) {
        if (!rawName) return "SHELL NINJA"
        var clean = rawName.trim()
        if (clean.toLowerCase() === "shell-ninja" || clean.toLowerCase() === "shell_ninja" || clean.toLowerCase() === "shell ninja") {
            return "SHELL NINJA"
        }
        return clean.replace(/[_-]/g, " ").toUpperCase()
    }

    // Auto focus password input
    Timer {
        interval: 250
        running: true
        onTriggered: {
            passInput.forceActiveFocus()
            if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
        }
    }



    Component.onCompleted: {
        fadeIn.start()
        if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
        if (typeof keyboard !== "undefined") {
            keyboard.numLock = true
        }
        // Set Shell Ninja as the primary default user account if present
        if (typeof userModel !== "undefined" && userModel && userModel.rowCount() > 0) {
            for (var i = 0; i < userModel.rowCount(); i++) {
                var uname = (userModel.data(userModel.index(i, 0), 257) || "").toLowerCase()
                var rname = (userModel.data(userModel.index(i, 0), 258) || "").toLowerCase()
                if (uname.indexOf("shell") !== -1 || rname.indexOf("shell") !== -1) {
                    root.userIndex = i
                    break
                }
            }
        }
    }

    NumberAnimation {
        id: fadeIn
        target: root
        property: "uiOpacity"
        to: 1
        duration: 350
        easing.type: Easing.OutCubic
    }

    // Background Layer
    Item {
        id: bgContainer
        anchors.fill: parent
        z: 0

        Image {
            id: bgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            source: (typeof config !== "undefined" && config.background) ? config.background : "backgrounds/default.jpg"
            asynchronous: true
            cache: true
        }

        // Ambient radial illumination behind dial clock
        RadialGradient {
            anchors.fill: parent
            horizontalOffset: -parent.width * 0.16
            verticalOffset: parent.height * 0.02
            horizontalRadius: parent.width * 0.60
            verticalRadius: parent.height * 0.70
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.isLight ? "#25ffffff" : "#2a3d54" }
                GradientStop { position: 0.45; color: root.isLight ? "#10ffffff" : "#121a26" }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: 0.90
        }
    }

    // Main Layout Container
    Item {
        id: mainContainer
        anchors.fill: parent
        z: 10
        opacity: root.uiOpacity

        // Clock & Dials Section (Left)
        Item {
            id: clockContainer
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.65
            height: parent.height

            // Center of the dials orbit
            readonly property real cx: 50 * s
            readonly property real cy: height * 0.5
            readonly property real minR: 380 * s
            readonly property real secR: 570 * s

            // Horizontal Capsule Indicator Pill
            Rectangle {
                id: indicatorPill
                z: 2
                x: (clockContainer.cx + clockContainer.minR) - (60 * s)
                anchors.verticalCenter: parent.verticalCenter
                width: (clockContainer.secR - clockContainer.minR) + (120 * s)
                height: 76 * s
                radius: 38 * s
                color: root.pillColor
                opacity: 0.55
                border.color: root.pillBorder
                border.width: 1.5 * s

                // Left Dash Indicator (aligned with minute track)
                Rectangle {
                    x: 60 * s - width * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * s
                    height: 3 * s
                    radius: 1.5 * s
                    color: root.mainTextColor
                }

                // Center Vertical Separator Line
                Rectangle {
                    x: parent.width * 0.5 - width * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1.5 * s
                    height: 32 * s
                    color: root.pillInnerLine
                }

                // Right Dash Indicator (aligned with seconds track)
                Rectangle {
                    x: parent.width - (60 * s) - width * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * s
                    height: 3 * s
                    radius: 1.5 * s
                    color: root.mainTextColor
                }
            }

            // Minute Ring Dial (Inner Track: numbers on inside of arc)
            Repeater {
                model: 60
                delegate: Item {
                    z: 15
                    property real base: index * 6
                    property real relAngle: {
                        var a = (base + root.smoothMinAngle) % 360
                        if (a > 180) a -= 360
                        if (a < -180) a += 360
                        return a
                    }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 5.5)
                    property bool isMajor: index % 5 === 0
                    property real disp: (base + root.smoothMinAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.minR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.minR * Math.sin(disp)

                    visible: tx > -700 * s && tx < 2200 * s

                    // Tick Mark
                    Rectangle {
                        x: parent.tx - width / 2
                        y: parent.ty - height / 2
                        width: isMajor ? 2.5 * s : 1.2 * s
                        height: isMajor ? 14 * s : 8 * s
                        color: root.isLight
                               ? Qt.rgba(0, 0, 0, spotlight > 0 ? 1.0 : (isMajor ? 0.75 : 0.40))
                               : Qt.rgba(1, 1, 1, spotlight > 0 ? 1.0 : (isMajor ? 0.40 : 0.18))
                        rotation: disp * 180 / Math.PI + 90
                        antialiasing: true
                        transformOrigin: Item.Center
                    }

                    // Major Minute Numbers (40, 45, 50, 55, 00, 05...)
                    Text {
                        visible: isMajor && Math.abs(relAngle) > 3.2
                        property real nRad: clockContainer.minR - 36 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width / 2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height / 2
                        text: String(index).padStart(2, '0')
                        font.family: root.boldFont
                        font.pixelSize: 22 * s
                        font.weight: spotlight > 0.4 ? Font.Black : Font.Bold
                        color: root.isLight
                               ? Qt.rgba(0, 0, 0, spotlight > 0 ? (0.6 + 0.4 * spotlight) : 0.5)
                               : Qt.rgba(1, 1, 1, spotlight > 0 ? (0.45 + spotlight * 0.55) : 0.32)
                        rotation: disp * 180 / Math.PI
                        transformOrigin: Item.Center
                        antialiasing: true
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Seconds Ring Dial (Outer Track: numbers on outside of arc)
            Repeater {
                model: 60
                delegate: Item {
                    z: 15
                    property real base: index * 6
                    property real relAngle: {
                        var a = (base + root.smoothSecAngle) % 360
                        if (a > 180) a -= 360
                        if (a < -180) a += 360
                        return a
                    }
                    property real spotlight: Math.max(0, 1.0 - Math.abs(relAngle) / 5.5)
                    property bool isMajor: index % 5 === 0
                    property real disp: (base + root.smoothSecAngle) * Math.PI / 180
                    property real tx: clockContainer.cx + clockContainer.secR * Math.cos(disp)
                    property real ty: clockContainer.cy + clockContainer.secR * Math.sin(disp)

                    visible: tx > -700 * s && tx < 2200 * s

                    // Tick Mark
                    Rectangle {
                        x: parent.tx - width / 2
                        y: parent.ty - height / 2
                        width: isMajor ? 2.2 * s : 1.2 * s
                        height: isMajor ? 14 * s : 8 * s
                        color: root.isLight
                               ? Qt.rgba(0, 0, 0, spotlight > 0 ? 1.0 : (isMajor ? 0.75 : 0.40))
                               : Qt.rgba(1, 1, 1, spotlight > 0 ? 1.0 : (isMajor ? 0.40 : 0.18))
                        rotation: disp * 180 / Math.PI + 90
                        antialiasing: true
                        transformOrigin: Item.Center
                    }

                    // Major Second Numbers (Placed on the outside of the track)
                    Text {
                        visible: isMajor && Math.abs(relAngle) > 3.2
                        property real nRad: clockContainer.secR + 32 * s
                        x: clockContainer.cx + nRad * Math.cos(disp) - width / 2
                        y: clockContainer.cy + nRad * Math.sin(disp) - height / 2
                        text: String(index).padStart(2, '0')
                        font.family: root.boldFont
                        font.pixelSize: 18 * s
                        font.weight: spotlight > 0.4 ? Font.Black : Font.Bold
                        color: root.isLight
                               ? Qt.rgba(0, 0, 0, spotlight > 0 ? (0.6 + 0.4 * spotlight) : 0.5)
                               : Qt.rgba(1, 1, 1, spotlight > 0 ? (0.45 + spotlight * 0.55) : 0.30)
                        rotation: disp * 180 / Math.PI
                        transformOrigin: Item.Center
                        antialiasing: true
                        renderType: Text.NativeRendering
                    }
                }
            }

            // Big Bold Hour Display (Left of capsule pill)
            Text {
                id: hourDisplay
                anchors.right: indicatorPill.left
                anchors.rightMargin: 42 * s
                anchors.verticalCenter: parent.verticalCenter
                text: String(root.displayHour).padStart(2, '0')
                font.family: root.mainFont
                font.pixelSize: 136 * s
                font.weight: Font.Black
                color: root.mainTextColor
                antialiasing: true
                renderType: Text.NativeRendering
            }

            // Date & Day Display (Right of capsule pill)
            Column {
                id: dateDisplay
                anchors.left: indicatorPill.right
                anchors.leftMargin: 85 * s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5 * s

                Text {
                    text: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase()
                    font.family: root.semiBoldFont
                    font.pixelSize: 15 * s
                    font.letterSpacing: 4 * s
                    font.weight: Font.DemiBold
                    color: root.subTextColor
                    antialiasing: true
                    renderType: Text.NativeRendering
                }

                Text {
                    text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                    font.family: root.boldFont
                    font.pixelSize: 24 * s
                    font.letterSpacing: 8 * s
                    font.weight: Font.Black
                    color: root.mainTextColor
                    antialiasing: true
                    renderType: Text.NativeRendering
                }
            }
        }
    }

    // Top Right HUD Actions (Session, Reboot, Shutdown)
    Item {
        id: hudContainer
        anchors.fill: parent
        z: 20
        opacity: root.uiOpacity

        Row {
            id: hudRow
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.top: parent.top
            anchors.topMargin: 50 * s
            spacing: 45 * s

            // Reboot Action
            CwAction {
                label: "REBOOT"
                onClicked: {
                    if (typeof sddm !== "undefined") sddm.reboot()
                }
            }

            // Shutdown Action
            CwAction {
                label: "SHUTDOWN"
                onClicked: {
                    if (typeof sddm !== "undefined") sddm.powerOff()
                }
            }

            // Session Selector
            CwAction {
                id: sessionBtn
                label: root.currentSessionDisplayName
                onClicked: {
                    if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 1) {
                        root.sessionMenuOpen = !root.sessionMenuOpen
                        root.userMenuOpen = false
                    } else if (typeof sessionModel !== "undefined" && sessionModel.rowCount() > 0) {
                        root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
                    }
                }
            }
        }

        // Session Dropdown Menu
        Rectangle {
            id: sessionDropdown
            z: 7000
            anchors.top: parent.top
            anchors.topMargin: 85 * s
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            width: 240 * s
            height: root.sessionMenuOpen ? Math.min(300 * s, ((typeof sessionModel !== "undefined" ? sessionModel.rowCount() : 1) * 38 * s) + 16 * s) : 0
            clip: true
            radius: 8 * s
            color: root.isLight ? "#f8fafc" : "#0d141e"
            border.color: root.pillBorder
            border.width: 1 * s
            visible: height > 0

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ListView {
                anchors.fill: parent
                anchors.margins: 8 * s
                model: typeof sessionModel !== "undefined" ? sessionModel : null
                delegate: Item {
                    width: parent.width
                    height: 34 * s
                    property bool itemHover: sItemMa.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        radius: 4 * s
                        color: (root.sessionIndex === index) ? (root.isLight ? "#e2e8f0" : "#1a2534") : (itemHover ? (root.isLight ? "#f1f5f9" : "#141c26") : "transparent")
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 12 * s
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.formatSessionName(model.name || "")
                        font.family: root.boldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 2 * s
                        font.weight: Font.Bold
                        color: (root.sessionIndex === index || itemHover) ? root.mainTextColor : root.dimTextColor
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: sItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.sessionIndex = index
                            root.sessionMenuOpen = false
                        }
                    }
                }
            }
        }

        // User Selection Popup
        Rectangle {
            id: uMenuContainer
            z: 6000
            anchors.bottom: loginPanel.top
            anchors.bottomMargin: 14 * s
            anchors.right: loginPanel.right
            width: 260 * s
            height: root.userMenuOpen ? Math.min(300 * s, ((typeof userModel !== "undefined" ? userModel.rowCount() : 1) * 38 * s) + 16 * s) : 0
            clip: true
            radius: 8 * s
            color: root.isLight ? "#f8fafc" : "#0d141e"
            border.color: root.pillBorder
            border.width: 1 * s
            visible: height > 0

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 8 * s
                spacing: 4 * s

                Repeater {
                    model: typeof userModel !== "undefined" ? userModel : null
                    delegate: Item {
                        width: parent.width
                        height: 34 * s
                        property bool itemHover: uItemMa.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            radius: 4 * s
                            color: (root.userIndex === index) ? (root.isLight ? "#e2e8f0" : "#1a2534") : (itemHover ? (root.isLight ? "#f1f5f9" : "#141c26") : "transparent")
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 12 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                var rname = model.realName || ""
                                var uname = model.name || ""
                                return root.formatDisplayName((rname && rname.length > 0) ? rname : uname)
                            }
                            font.family: root.boldFont
                            font.pixelSize: 13 * s
                            font.letterSpacing: 3 * s
                            font.weight: Font.Bold
                            color: (root.userIndex === index || itemHover) ? root.mainTextColor : root.dimTextColor
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: uItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.userIndex = index
                                root.userMenuOpen = false
                                passInput.text = ""
                                passInput.forceActiveFocus()
                                if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
                            }
                        }
                    }
                }
            }
        }

        // Bottom Right Login Form Section
        Column {
            id: loginPanel
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 110 * s
            width: 440 * s
            spacing: 10 * s

            // Username Header
            Item {
                width: parent.width
                height: 36 * s

                Row {
                    anchors.right: parent.right
                    spacing: 8 * s
                    layoutDirection: Qt.RightToLeft

                    Text {
                        id: userNameDisp
                        text: root.currentUserDisplayName
                        font.family: root.boldFont
                        font.pixelSize: 22 * s
                        font.weight: Font.Black
                        font.letterSpacing: 7 * s
                        color: root.mainTextColor
                        antialiasing: true
                        renderType: Text.NativeRendering
                    }

                    // Multi-user dropdown indicator
                    Text {
                        visible: typeof userModel !== "undefined" && userModel && userModel.rowCount() > 1
                        text: root.userMenuOpen ? "▲" : "▼"
                        font.pixelSize: 10 * s
                        color: uMa.containsMouse ? root.accentColor : root.dimTextColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    id: uMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (typeof userModel !== "undefined" && userModel && userModel.rowCount() > 1) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (typeof userModel !== "undefined" && userModel.rowCount() > 1) {
                            root.userMenuOpen = !root.userMenuOpen
                            root.sessionMenuOpen = false
                        }
                    }
                }
            }

            // Subtitle / Instruction Header ("TYPE PASSWORD OR FIDO PIN")
            Item {
                width: parent.width
                height: 22 * s

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: passInput.text.length === 0 ? root.authSubtitle : "AUTHENTICATING KEY"
                    font.family: root.semiBoldFont
                    font.pixelSize: 12 * s
                    font.letterSpacing: 3.5 * s
                    font.weight: Font.DemiBold
                    color: passInput.text.length === 0 ? root.subTextColor : root.mainTextColor
                    antialiasing: true
                    renderType: Text.NativeRendering
                }
            }

            // Password Input Box with Blinking Needle Cursor
            Item {
                width: parent.width
                height: 28 * s

                TextInput {
                    id: passInput
                    anchors.fill: parent
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    color: root.mainTextColor
                    font.family: root.boldFont
                    font.pixelSize: 18 * s
                    font.letterSpacing: 6 * s
                    horizontalAlignment: TextInput.AlignRight
                    verticalAlignment: TextInput.AlignVCenter
                    focus: true
                    activeFocusOnPress: false
                    cursorVisible: false
                    renderType: Text.NativeRendering
                    cursorDelegate: Item { width: 0; height: 0 }

                    inputMethodHints: root.enableVirtualKeyboard ? Qt.ImhNone : (Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText)
                    onActiveFocusChanged: {
                        if (activeFocus && !root.enableVirtualKeyboard) {
                            Qt.inputMethod.hide()
                        }
                    }

                    Keys.onReturnPressed: root.startLoginSequence()

                    // Blinking Needle Cursor
                    Rectangle {
                        id: needleCursor
                        width: 2 * s
                        height: 18 * s
                        color: root.mainTextColor
                        anchors.verticalCenter: parent.verticalCenter
                        x: passInput.cursorRectangle.x - width
                        visible: passInput.focus

                        SequentialAnimation {
                            loops: Animation.Infinite
                            running: needleCursor.visible
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 1.0; to: 0.1; duration: 450 }
                            NumberAnimation { target: needleCursor; property: "opacity"; from: 0.1; to: 1.0; duration: 450 }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        passInput.forceActiveFocus()
                        if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
                    }
                }
            }

            // Secondary Action: "TRY TOUCH ONLY" / "PRESS ENTER"
            Item {
                width: parent.width
                height: 28 * s

                Text {
                    id: touchOnlyBtn
                    anchors.right: parent.right
                    text: passInput.text.length > 0 ? "PRESS ENTER TO UNLOCK" : root.authPrompt
                    font.family: root.boldFont
                    font.pixelSize: 13 * s
                    font.letterSpacing: 4 * s
                    font.weight: Font.Bold
                    color: touchMa.containsMouse ? root.mainTextColor : (passInput.text.length > 0 ? root.accentColor : root.subTextColor)
                    antialiasing: true
                    renderType: Text.NativeRendering

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    id: touchMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.startLoginSequence()
                }
            }

            // Error Display Label
            Item {
                width: parent.width
                height: 18 * s

                Text {
                    id: errText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: root.errorColor
                    font.family: root.boldFont
                    font.pixelSize: 12 * s
                    font.weight: Font.Bold
                    font.letterSpacing: 3 * s
                    renderType: Text.NativeRendering
                }
            }
        }

        // Bottom Right Terminal Action Button (`>_`)
        Rectangle {
            id: termBtn
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40 * s
            width: 44 * s
            height: 44 * s
            radius: 10 * s
            color: termMa.containsMouse ? (root.isLight ? "#e2e8f0" : "#1e2b3a") : (root.isLight ? "#f1f5f9" : "#101824")
            border.color: termMa.containsMouse ? root.accentColor : root.pillBorder
            border.width: 1.5 * s

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: ">_"
                font.family: root.boldFont
                font.pixelSize: 16 * s
                font.weight: Font.Bold
                color: termMa.containsMouse ? root.mainTextColor : root.subTextColor
                renderType: Text.NativeRendering
            }

            MouseArea {
                id: termMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.infoDrawerOpen = !root.infoDrawerOpen
            }
        }

        // Quick Info / Controls Drawer
        Rectangle {
            id: infoDrawer
            z: 8000
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.bottom: termBtn.top
            anchors.bottomMargin: 14 * s
            width: 370 * s
            height: root.infoDrawerOpen ? 210 * s : 0
            clip: true
            radius: 14 * s
            color: root.isLight ? "#f8fafc" : "#0e1622"
            border.color: root.pillBorder
            border.width: 1.5 * s
            visible: height > 0

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 20 * s
                spacing: 14 * s

                Text {
                    text: "SYSTEM DASHBOARD"
                    font.family: root.boldFont
                    font.pixelSize: 13 * s
                    font.letterSpacing: 3 * s
                    font.weight: Font.Bold
                    color: root.accentColor
                    renderType: Text.NativeRendering
                }

                Row {
                    spacing: 10 * s
                    Text {
                        text: "HOST:"
                        font.family: root.semiBoldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.DemiBold
                        color: root.isLight ? "#64748b" : "#94a3b8"
                        renderType: Text.NativeRendering
                    }
                    Text {
                        text: typeof sddm !== "undefined" && sddm.hostName ? sddm.hostName.toUpperCase() : "ARCH LINUX"
                        font.family: root.boldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.Bold
                        color: root.isLight ? "#0f172a" : "#ffffff"
                        renderType: Text.NativeRendering
                    }
                }

                Row {
                    spacing: 10 * s
                    Text {
                        text: "SESSION:"
                        font.family: root.semiBoldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.DemiBold
                        color: root.isLight ? "#64748b" : "#94a3b8"
                        renderType: Text.NativeRendering
                    }
                    Text {
                        text: root.currentSessionDisplayName
                        font.family: root.boldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.Bold
                        color: root.isLight ? "#0f172a" : "#ffffff"
                        renderType: Text.NativeRendering
                    }
                }

                Row {
                    spacing: 12 * s
                    Text {
                        text: "TIME FORMAT:"
                        font.family: root.semiBoldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.DemiBold
                        color: root.isLight ? "#64748b" : "#94a3b8"
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering
                    }
                    Rectangle {
                        width: 95 * s
                        height: 28 * s
                        radius: 6 * s
                        color: fmtMa.containsMouse ? (root.isLight ? "#e2e8f0" : "#22354a") : (root.isLight ? "#f1f5f9" : "#172433")
                        border.color: fmtMa.containsMouse ? root.accentColor : root.pillBorder
                        border.width: 1.2 * s

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.hourFormat === "12" ? "12 HOUR" : "24 HOUR"
                            font.family: root.boldFont
                            font.pixelSize: 11 * s
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5 * s
                            color: root.isLight ? "#0f172a" : "#ffffff"
                            renderType: Text.NativeRendering
                        }

                        MouseArea {
                            id: fmtMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.hourFormat = (root.hourFormat === "12" ? "24" : "12")
                            }
                        }
                    }
                }
            }
        }
    }

    // Login Action Logic
    function startLoginSequence() {
        if (passInput.text.length === 0 || root.isLoggingIn) {
            passInput.forceActiveFocus()
            return
        }

        root.isLoggingIn = true
        if (root.enableWindup) {
            windupAnim.start()
        } else {
            doLogin()
        }
    }

    function doLogin() {
        var uname = root.currentUserLoginName
        if (typeof sddm !== "undefined") {
            sddm.login(uname, passInput.text, root.sessionIndex)
        }
    }

    function capitalizeFirst(str) {
        if (!str) return ""
        return str.charAt(0).toUpperCase() + str.slice(1)
    }

    // SDDM Authentication Signals
    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginSucceeded() {
            errText.text = ""
        }
        function onLoginFailed() {
            root.isLoggingIn = false
            windupAnim.stop()
            root.windupOffset = 0
            errText.text = "ACCESS DENIED"
            passInput.text = ""
            passInput.forceActiveFocus()
            if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
            shakeAnim.start()
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; from: root.marginR; to: root.marginR + 10 * s; duration: 40; easing.type: Easing.InOutSine }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: root.marginR - 10 * s; duration: 40; easing.type: Easing.InOutSine }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: root.marginR + 6 * s; duration: 40; easing.type: Easing.InOutSine }
        NumberAnimation { target: loginPanel; property: "anchors.rightMargin"; to: root.marginR; duration: 40; easing.type: Easing.InOutSine }
    }

    // Minimal Top Action Button Component (Clean typography, no artificial icons)
    component CwAction: Item {
        id: actItem
        width: actTxt.width + 10 * s
        height: 22 * s
        property string label: ""
        signal clicked()

        Text {
            id: actTxt
            anchors.centerIn: parent
            text: label.toUpperCase()
            color: actM.containsMouse ? root.mainTextColor : root.subTextColor
            font.family: root.boldFont
            font.pixelSize: 12 * s
            font.letterSpacing: 4 * s
            font.weight: Font.Bold
            antialiasing: true
            renderType: Text.NativeRendering

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: actM
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: actItem.clicked()
        }
    }
}
