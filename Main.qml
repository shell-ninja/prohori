import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import SddmComponents 2.0

Rectangle {
    id: root
    width: parent ? parent.width : Screen.width
    height: parent ? parent.height : Screen.height
    color: root.backgroundColor

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
            root.focusActiveInput()
        }
    }

    // Config options with safe fallbacks
    readonly property string themeName: (typeof config !== "undefined" && config.themeName) ? config.themeName : "Prohori Classic"
    readonly property string themeLayout: (typeof config !== "undefined" && config.themeLayout) ? config.themeLayout : (themeName.toLowerCase().indexOf("minimal") !== -1 ? "minimal" : (themeName.toLowerCase().indexOf("astral") !== -1 ? "astral" : "dialer"))
    readonly property bool isMinimalLayout: themeLayout === "minimal"
    readonly property bool isAstralLayout: themeLayout === "astral"
    readonly property bool isModernLayout: isMinimalLayout || isAstralLayout
    readonly property string themeMode: (typeof config !== "undefined" && config.themeMode) ? config.themeMode : "dark"
    readonly property bool isLight: themeMode === "light"
    readonly property color backgroundColor: (typeof config !== "undefined" && config.backgroundColor) ? config.backgroundColor : (isLight ? "#f8fafc" : "#080c12")
    readonly property bool hasBackground: typeof config !== "undefined" && config.background !== undefined && config.background !== "" && config.background !== "none"
    readonly property bool enableWindup: typeof config === "undefined" || (config.enableWindup !== "false" && config.enableWindup !== false)
    property string hourFormat: (typeof config !== "undefined" && config.hourFormat) ? config.hourFormat : "12"
    readonly property bool enableVirtualKeyboard: (typeof config !== "undefined" && config.enableVirtualKeyboard !== undefined) ? (config.enableVirtualKeyboard === "true" || config.enableVirtualKeyboard === true) : false

    function focusActiveInput() {
        if (root.isAstralLayout) {
            if (typeof astralPassInput !== "undefined" && astralPassInput) astralPassInput.forceActiveFocus()
        } else if (root.isMinimalLayout) {
            if (typeof minPassInput !== "undefined" && minPassInput) minPassInput.forceActiveFocus()
        } else {
            if (typeof passInput !== "undefined" && passInput) passInput.forceActiveFocus()
        }
        if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
    }

    function getActivePassword() {
        if (root.isAstralLayout) {
            return (typeof astralPassInput !== "undefined" && astralPassInput) ? astralPassInput.text : ""
        } else if (root.isMinimalLayout) {
            return (typeof minPassInput !== "undefined" && minPassInput) ? minPassInput.text : ""
        } else {
            return (typeof passInput !== "undefined" && passInput) ? passInput.text : ""
        }
    }


    // Clean, authentic minimal color palette (no artificial sparkles/flares)
    property bool isErrorState: false
    property real shakeOffset: 0
    readonly property color mainTextColor: isLight ? "#111827" : ((typeof config !== "undefined" && config.mainTextColor) ? config.mainTextColor : "#faf5ee")
    readonly property color dimTextColor: isLight ? "#6b7280" : ((typeof config !== "undefined" && config.dimTextColor) ? config.dimTextColor : "#6b7c93")
    readonly property color subTextColor: isLight ? "#4b5563" : ((typeof config !== "undefined" && config.subTextColor) ? config.subTextColor : "#94a3b8")
    readonly property color errorColor: (typeof config !== "undefined" && config.errorColor) ? config.errorColor : "#ff3366"
    readonly property color normalAccentColor: (typeof config !== "undefined" && config.accentColor) ? config.accentColor : "#38bdf8"
    property color accentColor: root.isErrorState ? root.errorColor : root.normalAccentColor

    Behavior on accentColor { ColorAnimation { duration: 250 } }

    readonly property color pillColor: isLight ? "#f1f5f9" : ((typeof config !== "undefined" && config.pillColor) ? config.pillColor : "#0d1520")
    readonly property color pillBorder: isLight ? "#cbd5e1" : ((typeof config !== "undefined" && config.pillBorder) ? config.pillBorder : "#1b2636")
    readonly property color pillInnerLine: isLight ? "#94a3b8" : ((typeof config !== "undefined" && config.pillInnerLine) ? config.pillInnerLine : "#2c3e55")

    readonly property bool enableAmbientGlow: (typeof config !== "undefined" && config.enableAmbientGlow !== undefined) ? (config.enableAmbientGlow === "true" || config.enableAmbientGlow === true) : false
    readonly property color ambientGlowColor: (typeof config !== "undefined" && config.ambientGlowColor) ? config.ambientGlowColor : Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.15)
    readonly property color ambientDimColor: (typeof config !== "undefined" && config.ambientDimColor) ? config.ambientDimColor : (isLight ? Qt.rgba(1, 1, 1, 0.06) : "#0d141e")
    readonly property real backgroundDim: (typeof config !== "undefined" && config.backgroundDim !== undefined) ? Number(config.backgroundDim) : 0.0
    readonly property bool showOrbitTracks: typeof config === "undefined" || (config.showOrbitTracks !== "false" && config.showOrbitTracks !== false)
    readonly property bool enableDustParticles: (typeof config !== "undefined" && config.enableDustParticles !== undefined) ? (config.enableDustParticles === "true" || config.enableDustParticles === true) : root.isMinimalLayout
    readonly property bool enableSmokeEffect: (typeof config !== "undefined" && config.enableSmokeEffect !== undefined) ? (config.enableSmokeEffect === "true" || config.enableSmokeEffect === true) : root.isAstralLayout



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
            root.focusActiveInput()
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
            source: root.hasBackground ? config.background : ""
            visible: root.hasBackground && status === Image.Ready
            asynchronous: true
            cache: true
        }

        // Contrast Dimmer for custom wallpapers
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.backgroundDim
            visible: opacity > 0
        }

        // Ambient radial illumination behind clock (only if enableAmbientGlow=true)
        RadialGradient {
            visible: root.enableAmbientGlow
            anchors.fill: parent
            horizontalOffset: root.isMinimalLayout ? -parent.width * 0.14 : -parent.width * 0.16
            verticalOffset: root.isMinimalLayout ? -parent.height * 0.06 : parent.height * 0.02
            horizontalRadius: parent.width * 0.58
            verticalRadius: parent.height * 0.68
            gradient: Gradient {
                GradientStop { position: 0.0; color: root.ambientGlowColor }
                GradientStop { position: 0.45; color: root.ambientDimColor }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // Ambient Falling Dust Layer (Soft, subtle micro-particles drifting from top)
    Item {
        id: dustLayer
        anchors.fill: parent
        z: 2
        visible: root.enableDustParticles
        opacity: root.uiOpacity

        Repeater {
            model: 32
            delegate: Item {
                id: particle

                // Deterministic pseudo-random distribution per particle index
                readonly property real s1: ((index * 37 + 13) % 100) / 100.0
                readonly property real s2: ((index * 59 + 29) % 100) / 100.0
                readonly property real s3: ((index * 83 + 47) % 100) / 100.0
                readonly property real s4: ((index * 97 + 71) % 100) / 100.0

                // Small micro-dust dimensions (1.2px - 2.8px)
                readonly property real pSize: Math.max(1.2, (1.2 + s1 * 1.6) * root.s)
                readonly property real baseOpacity: 0.15 + s2 * 0.25
                readonly property real baseX: (index / 32.0) * dustLayer.width + (s3 - 0.5) * (dustLayer.width / 16.0)
                readonly property int fallDuration: Math.round(11000 + s4 * 8000)
                readonly property real initialY: s2 * (dustLayer.height + 40) - 20

                x: baseX + swayX
                y: curY

                property real curY: initialY
                property real swayX: 0

                // Micro dust speck
                Rectangle {
                    width: particle.pSize
                    height: particle.pSize
                    radius: width * 0.5
                    color: root.accentColor
                    opacity: particle.baseOpacity
                }

                // Smooth vertical descent with staggered initial launch
                SequentialAnimation {
                    running: dustLayer.visible
                    NumberAnimation {
                        target: particle
                        property: "curY"
                        from: particle.initialY
                        to: dustLayer.height + 20
                        duration: Math.max(500, Math.round(particle.fallDuration * (1.0 - (particle.initialY + 20) / (dustLayer.height + 40))))
                    }
                    NumberAnimation {
                        target: particle
                        property: "curY"
                        from: -20
                        to: dustLayer.height + 20
                        duration: particle.fallDuration
                        loops: Animation.Infinite
                    }
                }

                // Gentle atmospheric horizontal sway
                SequentialAnimation {
                    loops: Animation.Infinite
                    running: dustLayer.visible
                    NumberAnimation {
                        target: particle
                        property: "swayX"
                        to: 10 + particle.s1 * 14
                        duration: Math.round(3000 + particle.s3 * 2500)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        target: particle
                        property: "swayX"
                        to: -(10 + particle.s1 * 14)
                        duration: Math.round(3200 + particle.s4 * 2500)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    // Ambient Rising Ethereal Violet Fog & Smoke Simulation (Billowing plumes rising from bottom to top)
    Item {
        id: smokeFogLayer
        anchors.fill: parent
        z: 2
        visible: root.enableSmokeEffect
        opacity: root.uiOpacity

        Canvas {
            id: cvSmoke
            anchors.fill: parent
            renderTarget: Canvas.FramebufferObject
            renderStrategy: Canvas.Threaded

            property real animTime: 0

            NumberAnimation on animTime {
                from: 0
                to: 3600000
                duration: 3600000
                loops: Animation.Infinite
                running: smokeFogLayer.visible
            }

            onAnimTimeChanged: requestPaint()

            readonly property var plumes: [
                { xFrac: 0.04, speed: 0.65, rBase: 180, swayAmp: 42, swayFreq: 0.0009, phase: 0.4, alpha: 0.28 },
                { xFrac: 0.12, speed: 0.88, rBase: 240, swayAmp: 52, swayFreq: 0.0007, phase: 1.8, alpha: 0.34 },
                { xFrac: 0.20, speed: 0.70, rBase: 200, swayAmp: 36, swayFreq: 0.0011, phase: 3.1, alpha: 0.26 },
                { xFrac: 0.28, speed: 0.82, rBase: 260, swayAmp: 58, swayFreq: 0.0006, phase: 0.9, alpha: 0.35 },
                { xFrac: 0.36, speed: 0.68, rBase: 220, swayAmp: 44, swayFreq: 0.0010, phase: 4.5, alpha: 0.30 },
                { xFrac: 0.45, speed: 0.95, rBase: 290, swayAmp: 64, swayFreq: 0.0008, phase: 2.3, alpha: 0.38 },
                { xFrac: 0.54, speed: 0.75, rBase: 230, swayAmp: 48, swayFreq: 0.0012, phase: 5.7, alpha: 0.32 },
                { xFrac: 0.62, speed: 0.88, rBase: 270, swayAmp: 54, swayFreq: 0.0007, phase: 1.2, alpha: 0.36 },
                { xFrac: 0.71, speed: 0.66, rBase: 210, swayAmp: 38, swayFreq: 0.0013, phase: 3.8, alpha: 0.27 },
                { xFrac: 0.79, speed: 0.85, rBase: 250, swayAmp: 56, swayFreq: 0.0009, phase: 2.7, alpha: 0.33 },
                { xFrac: 0.88, speed: 0.72, rBase: 220, swayAmp: 42, swayFreq: 0.0011, phase: 4.9, alpha: 0.29 },
                { xFrac: 0.96, speed: 0.80, rBase: 190, swayAmp: 36, swayFreq: 0.0008, phase: 1.5, alpha: 0.26 },
                { xFrac: 0.30, speed: 0.55, rBase: 320, swayAmp: 70, swayFreq: 0.0005, phase: 6.1, alpha: 0.34 },
                { xFrac: 0.50, speed: 0.60, rBase: 340, swayAmp: 75, swayFreq: 0.0006, phase: 3.4, alpha: 0.36 },
                { xFrac: 0.70, speed: 0.58, rBase: 310, swayAmp: 68, swayFreq: 0.0005, phase: 5.1, alpha: 0.32 },
                { xFrac: 0.16, speed: 0.62, rBase: 280, swayAmp: 60, swayFreq: 0.0007, phase: 0.7, alpha: 0.30 }
            ]

            onPaint: {
                var ctx = getContext('2d');
                ctx.clearRect(0, 0, width, height);

                var t = animTime;
                var w = width;
                var h = height;

                // 1. Triple Undulating Ground Fog Mist Banks across the bottom
                var wave1 = Math.sin(t * 0.0012) * 28;
                var groundH1 = 340 + wave1;
                var groundGrad1 = ctx.createLinearGradient(0, h - groundH1, 0, h);
                groundGrad1.addColorStop(0.0, "rgba(176, 38, 255, 0.0)");
                groundGrad1.addColorStop(0.35, "rgba(139, 92, 246, 0.18)");
                groundGrad1.addColorStop(1.0, "rgba(59, 7, 100, 0.42)");
                ctx.fillStyle = groundGrad1;
                ctx.fillRect(0, h - groundH1, w, groundH1);

                var wave2 = Math.cos(t * 0.0009) * 32;
                var groundH2 = 230 + wave2;
                var groundGrad2 = ctx.createLinearGradient(0, h - groundH2, 0, h);
                groundGrad2.addColorStop(0.0, "rgba(124, 58, 237, 0.0)");
                groundGrad2.addColorStop(0.45, "rgba(176, 38, 255, 0.18)");
                groundGrad2.addColorStop(1.0, "rgba(35, 4, 62, 0.52)");
                ctx.fillStyle = groundGrad2;
                ctx.fillRect(0, h - groundH2, w, groundH2);

                var wave3 = Math.sin(t * 0.0007 + 1.2) * 24;
                var groundH3 = 140 + wave3;
                var groundGrad3 = ctx.createLinearGradient(0, h - groundH3, 0, h);
                groundGrad3.addColorStop(0.0, "rgba(192, 60, 255, 0.0)");
                groundGrad3.addColorStop(0.50, "rgba(168, 85, 247, 0.22)");
                groundGrad3.addColorStop(1.0, "rgba(24, 2, 45, 0.65)");
                ctx.fillStyle = groundGrad3;
                ctx.fillRect(0, h - groundH3, w, groundH3);

                // 2. Rising Volumetric Smoke Plumes drifting upward
                for (var i = 0; i < plumes.length; i++) {
                    var p = plumes[i];
                    var loopH = h + p.rBase * 2.8;
                    var rawDist = ((t * 0.055 * p.speed + (p.phase * 340)) % loopH);
                    var py = h + p.rBase - rawDist;
                    var progress = Math.max(0.0, Math.min(1.0, 1.0 - (py / h)));

                    var px = (p.xFrac * w) + Math.sin(t * p.swayFreq + p.phase) * p.swayAmp;
                    var curR = p.rBase * (1.0 + progress * 1.45);
                    var curAlpha = p.alpha * Math.pow(Math.max(0.0, 1.0 - (progress * 0.78)), 1.15);

                    if (curAlpha > 0.01 && py > -curR && py < h + curR) {
                        var grad = ctx.createRadialGradient(px, py, 0, px, py, curR);
                        grad.addColorStop(0.0, "rgba(192, 60, 255, " + (curAlpha * 1.35).toFixed(3) + ")");
                        grad.addColorStop(0.35, "rgba(139, 92, 246, " + (curAlpha * 0.88).toFixed(3) + ")");
                        grad.addColorStop(0.70, "rgba(76, 29, 149, " + (curAlpha * 0.35).toFixed(3) + ")");
                        grad.addColorStop(1.0, "rgba(0, 0, 0, 0)");

                        ctx.fillStyle = grad;
                        ctx.beginPath();
                        ctx.arc(px, py, curR, 0, Math.PI * 2);
                        ctx.fill();
                    }
                }
            }
        }
    }


    // Error Alert Vignette Overlay (Red pulse on authentication failure)
    Rectangle {
        id: errorAlertOverlay
        anchors.fill: parent
        z: 3
        color: "transparent"
        visible: opacity > 0
        opacity: root.isErrorState ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 280 } }

        RadialGradient {
            anchors.fill: parent
            horizontalRadius: parent.width * 0.75
            verticalRadius: parent.height * 0.75
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.65; color: Qt.rgba(255/255, 30/255, 60/255, 0.06) }
                GradientStop { position: 1.0; color: Qt.rgba(255/255, 20/255, 50/255, 0.28) }
            }
        }
    }

    // Main Layout Container
    Item {
        id: mainContainer
        anchors.fill: parent
        z: 10
        opacity: root.uiOpacity
        transform: Translate { x: root.shakeOffset }

        // Clock & Dials Section (Left)
        Item {
            id: clockContainer
            visible: !root.isModernLayout
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.65
            height: parent.height

            // Center of the dials orbit
            readonly property real cx: 50 * s
            readonly property real cy: height * 0.5
            readonly property real minR: 380 * s
            readonly property real secR: 570 * s

            // Concentric Chronometer Orbit Guide Tracks
            Rectangle {
                id: minOrbitRing
                visible: root.showOrbitTracks
                z: 1
                x: clockContainer.cx - clockContainer.minR
                y: clockContainer.cy - clockContainer.minR
                width: clockContainer.minR * 2
                height: clockContainer.minR * 2
                radius: clockContainer.minR
                color: "transparent"
                border.color: root.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.08)
                border.width: 1 * s
            }

            Rectangle {
                id: secOrbitRing
                visible: root.showOrbitTracks
                z: 1
                x: clockContainer.cx - clockContainer.secR
                y: clockContainer.cy - clockContainer.secR
                width: clockContainer.secR * 2
                height: clockContainer.secR * 2
                radius: clockContainer.secR
                color: "transparent"
                border.color: root.isLight ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.06)
                border.width: 1 * s
            }

            // Horizontal Capsule Indicator Pill (iOS Liquid Glass Capsule)
            Rectangle {
                id: indicatorPill
                z: 10
                x: (clockContainer.cx + clockContainer.minR) - (60 * s)
                anchors.verticalCenter: parent.verticalCenter
                width: (clockContainer.secR - clockContainer.minR) + (120 * s)
                height: 76 * s
                radius: 38 * s
                color: root.pillColor
                opacity: 0.55
                border.color: root.pillBorder
                border.width: 1.5 * s

                // 1. Ambient Volumetric Liquid Aura behind the glass
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 12 * s
                    height: parent.height + 12 * s
                    radius: height * 0.5
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08)
                    z: -1
                }

                // 2. Left Dash Indicator (aligned with minute track)
                Rectangle {
                    x: 60 * s - width * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * s
                    height: 3 * s
                    radius: 1.5 * s
                    color: root.accentColor
                }

                // 3. Center Vertical Separator Line
                Rectangle {
                    x: parent.width * 0.5 - width * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1.5 * s
                    height: 32 * s
                    color: root.pillInnerLine
                }

                // 4. Right Dash Indicator (aligned with seconds track)
                Rectangle {
                    x: parent.width - (60 * s) - width * 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * s
                    height: 3 * s
                    radius: 1.5 * s
                    color: root.accentColor
                }

                // 5. iOS Liquid Glass Specular Sheen (Curved Gloss Crescent)
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1 * s
                    anchors.left: parent.left
                    anchors.leftMargin: 2 * s
                    anchors.right: parent.right
                    anchors.rightMargin: 2 * s
                    height: parent.height * 0.46
                    radius: parent.radius - 1 * s
                    clip: true
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.28) }
                        GradientStop { position: 0.40; color: Qt.rgba(255, 255, 255, 0.10) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                // 6. Inner Refraction Bevel Rim
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1.5 * s
                    radius: parent.radius - 1.5 * s
                    color: "transparent"
                    border.color: Qt.rgba(255, 255, 255, 0.12)
                    border.width: 1 * s
                }
            }

            // Minute Ring Dial (Inner Track: numbers on inside of arc)
            Repeater {
                model: 60
                delegate: Item {
                    z: 5
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
                    z: 5
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
                spacing: 6 * s

                Row {
                    spacing: 12 * s
                    Text {
                        text: Qt.formatDate(new Date(), "dd MMM yyyy").toUpperCase()
                        font.family: root.semiBoldFont
                        font.pixelSize: 15 * s
                        font.letterSpacing: 4 * s
                        font.weight: Font.DemiBold
                        color: root.subTextColor
                        antialiasing: true
                        renderType: Text.NativeRendering
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // AM / PM / 24H Period Indicator Badge
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36 * s
                        height: 18 * s
                        radius: 4 * s
                        color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
                        border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                        border.width: 1 * s

                        Text {
                            anchors.centerIn: parent
                            text: root.hourFormat === "12" ? (root.curH >= 12 ? "PM" : "AM") : "24H"
                            font.family: root.boldFont
                            font.pixelSize: 9 * s
                            font.letterSpacing: 1.5 * s
                            font.weight: Font.Bold
                            color: root.accentColor
                            renderType: Text.NativeRendering
                        }
                    }
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

        // 1. Prohori Minimal: Monolithic Unified Obsidian Status & Control Capsule
        Rectangle {
            id: minTopDeck
            visible: root.isMinimalLayout
            anchors.right: parent.right
            anchors.rightMargin: 130 * s
            anchors.top: parent.top
            anchors.topMargin: 46 * s
            height: 38 * s
            width: minDeckRow.width + 24 * s
            radius: 19 * s
            color: Qt.rgba(12/255, 17/255, 26/255, 0.75)
            border.color: Qt.rgba(255, 255, 255, 0.09)
            border.width: 1 * s

            Row {
                id: minDeckRow
                anchors.centerIn: parent
                spacing: 12 * s

                // Minimal Session Selector
                Item {
                    id: minSessionBtn
                    width: minSessContent.width + 16 * s
                    height: 28 * s
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 14 * s
                        color: minSessMa.containsMouse || root.sessionMenuOpen
                               ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                               : "transparent"
                        border.color: minSessMa.containsMouse || root.sessionMenuOpen
                                      ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                                      : "transparent"
                        border.width: 1 * s

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            id: minSessContent
                            anchors.centerIn: parent
                            spacing: 8 * s

                            // Live Session Indicator Dot
                            Rectangle {
                                width: 6 * s
                                height: 6 * s
                                radius: 3 * s
                                color: root.accentColor
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 12 * s
                                    height: 12 * s
                                    radius: 6 * s
                                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                                    z: -1
                                }
                            }

                            Text {
                                text: root.currentSessionDisplayName.toUpperCase()
                                color: minSessMa.containsMouse || root.sessionMenuOpen ? root.accentColor : root.mainTextColor
                                font.family: root.boldFont
                                font.pixelSize: 11 * s
                                font.letterSpacing: 2 * s
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: root.sessionMenuOpen ? "▲" : "▼"
                                color: minSessMa.containsMouse || root.sessionMenuOpen ? root.accentColor : root.dimTextColor
                                font.pixelSize: 8 * s
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    MouseArea {
                        id: minSessMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
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

                // Vertical Divider 1
                Rectangle {
                    width: 1 * s
                    height: 16 * s
                    color: Qt.rgba(255, 255, 255, 0.12)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Minimal Reboot Button
                Item {
                    id: minRebootBtn
                    width: minRebootRow.width + 16 * s
                    height: 28 * s
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 14 * s
                        color: minRebootMa.containsMouse
                               ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                               : "transparent"
                        border.color: minRebootMa.containsMouse
                                      ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                                      : "transparent"
                        border.width: 1 * s

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            id: minRebootRow
                            anchors.centerIn: parent
                            spacing: 6 * s

                            Text {
                                text: "⟳"
                                font.pixelSize: 13 * s
                                color: minRebootMa.containsMouse ? root.accentColor : root.subTextColor
                                anchors.verticalCenter: parent.verticalCenter
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: "REBOOT"
                                font.family: root.boldFont
                                font.pixelSize: 10 * s
                                font.letterSpacing: 1.8 * s
                                font.weight: Font.Bold
                                color: minRebootMa.containsMouse ? root.accentColor : root.subTextColor
                                anchors.verticalCenter: parent.verticalCenter
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    MouseArea {
                        id: minRebootMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sddm !== "undefined") sddm.reboot()
                        }
                    }
                }

                // Vertical Divider 2
                Rectangle {
                    width: 1 * s
                    height: 16 * s
                    color: Qt.rgba(255, 255, 255, 0.12)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Minimal Shutdown Button
                Item {
                    id: minPowerBtn
                    width: minPowerRow.width + 16 * s
                    height: 28 * s
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 14 * s
                        color: minPowerMa.containsMouse
                               ? Qt.rgba(255/255, 51/255, 102/255, 0.18)
                               : "transparent"
                        border.color: minPowerMa.containsMouse
                                      ? Qt.rgba(255/255, 51/255, 102/255, 0.50)
                                      : "transparent"
                        border.width: 1 * s

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Row {
                            id: minPowerRow
                            anchors.centerIn: parent
                            spacing: 6 * s

                            Text {
                                text: "⏻"
                                font.pixelSize: 12 * s
                                color: minPowerMa.containsMouse ? "#ff3366" : root.subTextColor
                                anchors.verticalCenter: parent.verticalCenter
                                renderType: Text.NativeRendering
                            }

                            Text {
                                text: "SHUTDOWN"
                                font.family: root.boldFont
                                font.pixelSize: 10 * s
                                font.letterSpacing: 1.8 * s
                                font.weight: Font.Bold
                                color: minPowerMa.containsMouse ? "#ff3366" : root.subTextColor
                                anchors.verticalCenter: parent.verticalCenter
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    MouseArea {
                        id: minPowerMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof sddm !== "undefined") sddm.powerOff()
                        }
                    }
                }
            }
        }

        // 2. Prohori Astral: Futuristic Cyber Telemetry Cluster
        Row {
            id: astralTopDeck
            visible: root.isAstralLayout
            anchors.right: parent.right
            anchors.rightMargin: 70 * s
            anchors.top: parent.top
            anchors.topMargin: 46 * s
            spacing: 12 * s

            // Cyber Session Selector Pill
            Rectangle {
                id: astralSessionBtn
                width: astralSessContent.width + 26 * s
                height: 38 * s
                radius: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                color: astralSessMa.containsMouse || root.sessionMenuOpen
                       ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
                       : Qt.rgba(14/255, 10/255, 26/255, 0.82)
                border.color: astralSessMa.containsMouse || root.sessionMenuOpen
                              ? root.accentColor
                              : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                border.width: 1.5 * s

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: astralSessContent
                    anchors.centerIn: parent
                    spacing: 8 * s

                    // Glowing Amethyst Diamond
                    Text {
                        text: "◈"
                        font.pixelSize: 13 * s
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: "SYS // "
                        font.family: root.boldFont
                        font.pixelSize: 9 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.Bold
                        color: root.dimTextColor
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: root.currentSessionDisplayName.toUpperCase()
                        color: astralSessMa.containsMouse || root.sessionMenuOpen ? root.accentColor : root.mainTextColor
                        font.family: root.boldFont
                        font.pixelSize: 11 * s
                        font.letterSpacing: 2 * s
                        font.weight: Font.Bold
                        anchors.verticalCenter: parent.verticalCenter
                        renderType: Text.NativeRendering
                    }

                    Text {
                        text: root.sessionMenuOpen ? "▲" : "▼"
                        color: astralSessMa.containsMouse || root.sessionMenuOpen ? root.accentColor : root.dimTextColor
                        font.pixelSize: 8 * s
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: astralSessMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
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

            // Cyber Reboot Pod
            Rectangle {
                id: astralRebootBtn
                width: 38 * s
                height: 38 * s
                radius: 11 * s
                anchors.verticalCenter: parent.verticalCenter
                color: astralRebootMa.containsMouse
                       ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.22)
                       : Qt.rgba(14/255, 10/255, 26/255, 0.82)
                border.color: astralRebootMa.containsMouse
                              ? root.accentColor
                              : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                border.width: 1.5 * s

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    id: astralRebootGlyph
                    anchors.centerIn: parent
                    text: "⟳"
                    font.family: root.boldFont
                    font.pixelSize: 16 * s
                    font.weight: Font.Bold
                    color: astralRebootMa.containsMouse ? root.accentColor : root.subTextColor
                    rotation: astralRebootMa.containsMouse ? 45 : 0
                    scale: astralRebootMa.containsMouse ? 1.15 : 1.0
                    renderType: Text.NativeRendering

                    Behavior on rotation { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Hover Micro Tooltip Badge
                Rectangle {
                    anchors.top: parent.bottom
                    anchors.topMargin: 8 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: astralRebootTipTxt.width + 16 * s
                    height: 22 * s
                    radius: 6 * s
                    color: Qt.rgba(14/255, 10/255, 26/255, 0.95)
                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                    border.width: 1 * s
                    opacity: astralRebootMa.containsMouse ? 1.0 : 0.0
                    visible: opacity > 0
                    z: 100

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        id: astralRebootTipTxt
                        anchors.centerIn: parent
                        text: "REBOOT"
                        font.family: root.boldFont
                        font.pixelSize: 9 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.Bold
                        color: root.accentColor
                        renderType: Text.NativeRendering
                    }
                }

                MouseArea {
                    id: astralRebootMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof sddm !== "undefined") sddm.reboot()
                    }
                }
            }

            // Cyber Power / Shutdown Pod
            Rectangle {
                id: astralPowerBtn
                width: 38 * s
                height: 38 * s
                radius: 11 * s
                anchors.verticalCenter: parent.verticalCenter
                color: astralPowerMa.containsMouse
                       ? Qt.rgba(255/255, 51/255, 102/255, 0.22)
                       : Qt.rgba(14/255, 10/255, 26/255, 0.82)
                border.color: astralPowerMa.containsMouse
                              ? "#ff3366"
                              : Qt.rgba(255/255, 51/255, 102/255, 0.35)
                border.width: 1.5 * s

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    id: astralPowerGlyph
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: root.boldFont
                    font.pixelSize: 15 * s
                    font.weight: Font.Bold
                    color: astralPowerMa.containsMouse ? "#ff3366" : root.subTextColor
                    scale: astralPowerMa.containsMouse ? 1.15 : 1.0
                    renderType: Text.NativeRendering

                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Hover Micro Tooltip Badge
                Rectangle {
                    anchors.top: parent.bottom
                    anchors.topMargin: 8 * s
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: astralPowerTipTxt.width + 16 * s
                    height: 22 * s
                    radius: 6 * s
                    color: Qt.rgba(14/255, 10/255, 26/255, 0.95)
                    border.color: Qt.rgba(255/255, 51/255, 102/255, 0.50)
                    border.width: 1 * s
                    opacity: astralPowerMa.containsMouse ? 1.0 : 0.0
                    visible: opacity > 0
                    z: 100

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        id: astralPowerTipTxt
                        anchors.centerIn: parent
                        text: "SHUTDOWN"
                        font.family: root.boldFont
                        font.pixelSize: 9 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.Bold
                        color: "#ff3366"
                        renderType: Text.NativeRendering
                    }
                }

                MouseArea {
                    id: astralPowerMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof sddm !== "undefined") sddm.powerOff()
                    }
                }
            }
        }

        // 3. Prohori Classic: Orbital Chronometer Classic Action Pills (Liquid Glass Effect)
        Row {
            id: hudRowClassic
            visible: !root.isModernLayout
            anchors.right: parent.right
            anchors.rightMargin: root.marginR
            anchors.top: parent.top
            anchors.topMargin: 46 * s
            spacing: 12 * s

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
                id: sessionBtnClassic
                label: root.currentSessionDisplayName + (root.sessionMenuOpen ? " ▲" : " ▼")
                isActive: root.sessionMenuOpen
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
            anchors.topMargin: 92 * s
            anchors.right: parent.right
            anchors.rightMargin: root.isAstralLayout ? (70 * s + 100 * s) : (root.isMinimalLayout ? 130 * s : root.marginR)
            width: 250 * s
            height: root.sessionMenuOpen ? Math.min(300 * s, ((typeof sessionModel !== "undefined" ? sessionModel.rowCount() : 1) * 44 * s) + 20 * s) : 0
            clip: true
            radius: 14 * s
            color: root.isLight ? "#f8fafc" : (root.isAstralLayout ? Qt.rgba(14/255, 10/255, 26/255, 0.95) : Qt.rgba(12/255, 17/255, 26/255, 0.92))
            border.color: root.isAstralLayout ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40) : Qt.rgba(255, 255, 255, 0.10)
            border.width: 1.5 * s
            visible: height > 0

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            ListView {
                anchors.fill: parent
                anchors.margins: 8 * s
                spacing: 4 * s
                model: typeof sessionModel !== "undefined" ? sessionModel : null
                delegate: Item {
                    width: parent.width
                    height: 38 * s
                    property bool itemHover: sItemMa.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        radius: 8 * s
                        color: (root.sessionIndex === index)
                               ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                               : (itemHover ? Qt.rgba(255, 255, 255, 0.06) : "transparent")
                        border.color: (root.sessionIndex === index)
                                      ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                                      : "transparent"
                        border.width: 1 * s

                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12 * s
                        anchors.right: parent.right
                        anchors.rightMargin: 12 * s
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10 * s

                        // Active Session Indicator Dot
                        Rectangle {
                            width: 6 * s
                            height: 6 * s
                            radius: 3 * s
                            color: (root.sessionIndex === index) ? root.accentColor : "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: root.formatSessionName(model.name || "")
                            font.family: root.boldFont
                            font.pixelSize: 12 * s
                            font.letterSpacing: 2 * s
                            font.weight: Font.Bold
                            color: (root.sessionIndex === index) ? root.accentColor : (itemHover ? root.mainTextColor : root.dimTextColor)
                            renderType: Text.NativeRendering
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                        }
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
            anchors.horizontalCenter: root.isAstralLayout ? parent.horizontalCenter : undefined
            anchors.right: root.isAstralLayout ? undefined : parent.right
            anchors.rightMargin: root.isAstralLayout ? 0 : (root.isMinimalLayout ? 130 * s : root.marginR)
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.isAstralLayout ? (parent.height * 0.15 + 84 * s) : (root.isMinimalLayout ? (parent.height * 0.5 + 155 * s) : 240 * s)
            width: root.isAstralLayout ? 360 * s : (root.isMinimalLayout ? 430 * s : 280 * s)
            height: root.userMenuOpen ? Math.min(320 * s, ((typeof userModel !== "undefined" ? userModel.rowCount() : 1) * 52 * s) + 40 * s) : 0
            clip: true
            radius: 16 * s
            color: root.isLight ? "#f8fafc" : Qt.rgba(12/255, 17/255, 26/255, 0.94)
            border.color: Qt.rgba(255, 255, 255, 0.10)
            border.width: 1.5 * s
            visible: height > 0

            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 12 * s
                spacing: 6 * s

                // Header
                Row {
                    spacing: 8 * s
                    Rectangle {
                        width: 5 * s
                        height: 5 * s
                        radius: 2.5 * s
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "SELECT USER ACCOUNT"
                        font.family: root.boldFont
                        font.pixelSize: 10 * s
                        font.letterSpacing: 2 * s
                        font.weight: Font.Bold
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Repeater {
                    model: typeof userModel !== "undefined" ? userModel : null
                    delegate: Item {
                        width: parent.width
                        height: 44 * s
                        property bool itemHover: uItemMa.containsMouse
                        readonly property string uDisplayName: {
                            var rname = model.realName || ""
                            var uname = model.name || ""
                            return root.formatDisplayName((rname && rname.length > 0) ? rname : uname)
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10 * s
                            color: (root.userIndex === index)
                                   ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                                   : (itemHover ? Qt.rgba(255, 255, 255, 0.06) : "transparent")
                            border.color: (root.userIndex === index)
                                          ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.40)
                                          : "transparent"
                            border.width: 1 * s

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12 * s

                            // User Avatar Monogram Circle
                            Rectangle {
                                width: 28 * s
                                height: 28 * s
                                radius: 14 * s
                                color: (root.userIndex === index)
                                       ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.20)
                                       : Qt.rgba(255, 255, 255, 0.08)
                                border.color: (root.userIndex === index)
                                              ? root.accentColor
                                              : Qt.rgba(255, 255, 255, 0.14)
                                border.width: 1 * s
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: uDisplayName.length > 0 ? uDisplayName.charAt(0) : "U"
                                    font.family: root.boldFont
                                    font.pixelSize: 12 * s
                                    font.weight: Font.Black
                                    color: (root.userIndex === index) ? root.accentColor : root.mainTextColor
                                }
                            }

                            Text {
                                text: uDisplayName
                                font.family: root.boldFont
                                font.pixelSize: 13 * s
                                font.letterSpacing: 2 * s
                                font.weight: Font.Bold
                                color: (root.userIndex === index) ? root.accentColor : (itemHover ? root.mainTextColor : root.dimTextColor)
                                renderType: Text.NativeRendering
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Right Active Pill
                        Rectangle {
                            visible: root.userIndex === index
                            anchors.right: parent.right
                            anchors.rightMargin: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 58 * s
                            height: 20 * s
                            radius: 4 * s
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                            border.color: root.accentColor
                            border.width: 1 * s

                            Text {
                                anchors.centerIn: parent
                                text: "ACTIVE"
                                font.family: root.boldFont
                                font.pixelSize: 9 * s
                                font.weight: Font.Black
                                font.letterSpacing: 1.5 * s
                                color: root.accentColor
                            }
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
                                if (typeof minPassInput !== "undefined" && minPassInput) minPassInput.text = ""
                                root.focusActiveInput()
                            }
                        }
                    }
                }
            }
        }

        // Bottom Right Login Form Section (Dialer Layout)
        Column {
            id: loginPanel
            visible: !root.isModernLayout
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

        // =====================================================================
        // Prohori Minimal Layout (Architectural Monolithic Digital Clock & Floating Auth Card)
        // =====================================================================
        Item {
            id: minimalContainer
            visible: root.isMinimalLayout
            anchors.fill: parent

            // 1. Viewfinder Crosshairs & Modern Architectural Frame Guides
            Item {
                id: frameGuides
                anchors.fill: parent
                opacity: 0.35

                // Top Left Viewfinder Bracket & System Code
                Row {
                    x: 60 * s
                    y: 50 * s
                    spacing: 12 * s

                    Text {
                        text: "┌"
                        font.family: root.boldFont
                        font.pixelSize: 18 * s
                        color: root.accentColor
                    }

                    Text {
                        text: "PROHORI // SENTINEL CORE"
                        font.family: root.boldFont
                        font.pixelSize: 11 * s
                        font.letterSpacing: 3 * s
                        font.weight: Font.Bold
                        color: root.dimTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Bottom Left Telemetry Status
                Row {
                    x: 60 * s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 45 * s
                    spacing: 10 * s

                    Rectangle {
                        width: 7 * s
                        height: 7 * s
                        radius: 3.5 * s
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.25; duration: 1200; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.25; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        text: root.isErrorState
                              ? "STATUS: SECURITY ALERT // ACCESS REJECTED"
                              : (root.isLoggingIn
                                 ? "STATUS: AUTHENTICATING // VERIFYING CREDENTIALS"
                                 : "STATUS: ENCRYPTED // SYSTEM READY")
                        font.family: root.boldFont
                        font.pixelSize: 11 * s
                        font.letterSpacing: 2 * s
                        font.weight: Font.Bold
                        color: root.isErrorState ? root.errorColor : (root.isLoggingIn ? root.accentColor : root.dimTextColor)
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                // Subtle Horizon Axis Rule Line across lower quadrant
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 60 * s
                    anchors.right: parent.right
                    anchors.rightMargin: 60 * s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 75 * s
                    height: 1 * s
                    color: Qt.rgba(1, 1, 1, 0.05)
                }
            }

            // 2. Minimal Hero Section: Monolithic Typographic Clock & Kinetic Sweep
            Item {
                id: minHeroClock
                visible: root.isMinimalLayout
                anchors.left: parent.left
                anchors.leftMargin: 120 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 650 * s
                height: 380 * s

                Column {
                    anchors.fill: parent
                    spacing: 14 * s

                    // Precision Category Pill
                    Row {
                        spacing: 8 * s
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6 * s
                            height: 6 * s
                            radius: 3 * s
                            color: root.accentColor
                        }
                        Text {
                            text: "CHRONO PRECISION // " + (root.hourFormat === "12" ? (root.curH >= 12 ? "PM" : "AM") : "24H")
                            font.family: root.boldFont
                            font.pixelSize: 12 * s
                            font.letterSpacing: 4 * s
                            font.weight: Font.Bold
                            color: root.accentColor
                            renderType: Text.NativeRendering
                        }
                    }

                    // Monolithic Giant Digital Time Display
                    Row {
                        spacing: 8 * s
                        Text {
                            text: String(root.displayHour).padStart(2, '0')
                            font.family: root.boldFont
                            font.pixelSize: 144 * s
                            font.weight: Font.Black
                            color: root.mainTextColor
                            renderType: Text.NativeRendering
                        }

                        Text {
                            text: ":"
                            font.family: root.boldFont
                            font.pixelSize: 132 * s
                            font.weight: Font.Black
                            color: root.accentColor
                            opacity: (root.curMS < 500) ? 1.0 : 0.20
                            renderType: Text.NativeRendering
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Text {
                            text: String(root.curM).padStart(2, '0')
                            font.family: root.boldFont
                            font.pixelSize: 144 * s
                            font.weight: Font.Black
                            color: root.mainTextColor
                            renderType: Text.NativeRendering
                        }
                    }

                    // Kinetic Seconds Progress Rail with Sticky Tens and Moving Units + "s"
                    Item {
                        id: secTrackItem
                        width: 540 * s
                        height: 38 * s

                        readonly property real secFrac: (root.curS * 1000 + root.curMS) / 60000.0
                        readonly property real railLen: 430 * s

                        // Sticky First Number (Seconds Tens Digit: 0, 1, 2, 3, 4, 5)
                        Rectangle {
                            id: stickyTensBadge
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32 * s
                            height: 28 * s
                            radius: 7 * s
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
                            border.width: 1.5 * s

                            Text {
                                anchors.centerIn: parent
                                text: String(Math.floor(root.curS / 10))
                                font.family: root.boldFont
                                font.pixelSize: 16 * s
                                font.weight: Font.Black
                                color: root.accentColor
                                renderType: Text.NativeRendering
                            }
                        }

                        // Progress Rail
                        Rectangle {
                            id: secRail
                            anchors.left: stickyTensBadge.right
                            anchors.leftMargin: 14 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: secTrackItem.railLen
                            height: 4 * s
                            radius: 2 * s
                            color: Qt.rgba(1, 1, 1, 0.08)

                            // Active progress fill
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(4 * s, Math.min(parent.width, parent.width * secTrackItem.secFrac))
                                radius: 2 * s
                                color: root.accentColor
                            }

                            // Moving Second Number + letter "s" (Attached to timer head)
                            Item {
                                id: movingSecHead
                                x: Math.max(0, Math.min(secRail.width - width, (secRail.width * secTrackItem.secFrac) - (width * 0.5)))
                                anchors.verticalCenter: parent.verticalCenter
                                width: movingPill.width
                                height: 32 * s

                                // Floating Pill with 2nd number and letter 's' (e.g. "4s", "9s")
                                Rectangle {
                                    id: movingPill
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: dotAnchor.top
                                    anchors.bottomMargin: 4 * s
                                    width: movingSecTxt.width + 12 * s
                                    height: 20 * s
                                    radius: 5 * s
                                    color: Qt.rgba(12/255, 17/255, 26/255, 0.90)
                                    border.color: root.accentColor
                                    border.width: 1 * s

                                    Text {
                                        id: movingSecTxt
                                        anchors.centerIn: parent
                                        text: (root.curS % 10) + "s"
                                        font.family: root.boldFont
                                        font.pixelSize: 11 * s
                                        font.weight: Font.Black
                                        font.letterSpacing: 1 * s
                                        color: root.accentColor
                                        renderType: Text.NativeRendering
                                    }
                                }

                                // Glowing Indicator Dot directly on the rail
                                Rectangle {
                                    id: dotAnchor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10 * s
                                    height: 10 * s
                                    radius: 5 * s
                                    color: root.mainTextColor
                                    border.color: root.accentColor
                                    border.width: 2 * s
                                }
                            }
                        }

                        // Static 60s End Marker
                        Text {
                            anchors.left: secRail.right
                            anchors.leftMargin: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: "60s"
                            font.family: root.boldFont
                            font.pixelSize: 11 * s
                            font.letterSpacing: 1.5 * s
                            font.weight: Font.Bold
                            color: Qt.rgba(1, 1, 1, 0.25)
                            renderType: Text.NativeRendering
                        }
                    }

                    // Day of Week
                    Text {
                        text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                        font.family: root.boldFont
                        font.pixelSize: 30 * s
                        font.letterSpacing: 8 * s
                        font.weight: Font.Black
                        color: root.mainTextColor
                        renderType: Text.NativeRendering
                    }

                    // Full Date
                    Text {
                        text: Qt.formatDate(new Date(), "dd MMMM yyyy").toUpperCase()
                        font.family: root.semiBoldFont
                        font.pixelSize: 15 * s
                        font.letterSpacing: 4 * s
                        font.weight: Font.DemiBold
                        color: root.subTextColor
                        renderType: Text.NativeRendering
                    }
                }
            }

            // 3. Center-Right Floating Authentication Monolith Dock
            Rectangle {
                id: minAuthCard
                anchors.right: parent.right
                anchors.rightMargin: 130 * s
                anchors.verticalCenter: parent.verticalCenter
                width: 430 * s
                height: 290 * s
                radius: 20 * s
                color: root.isErrorState ? Qt.rgba(36/255, 8/255, 14/255, 0.85) : Qt.rgba(12/255, 17/255, 26/255, 0.72)
                border.color: root.isErrorState ? root.errorColor : (root.isLoggingIn ? root.accentColor : Qt.rgba(255, 255, 255, 0.08))
                border.width: (root.isErrorState || root.isLoggingIn) ? 2 * s : 1.5 * s

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                Column {
                    anchors.fill: parent
                    anchors.margins: 28 * s
                    spacing: 18 * s

                    // User Identity Row
                    Item {
                        width: parent.width
                        height: 52 * s

                        Row {
                            anchors.fill: parent
                            spacing: 14 * s

                            // User Initial Avatar Circle
                            Rectangle {
                                width: 50 * s
                                height: 50 * s
                                radius: 25 * s
                                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
                                border.color: root.accentColor
                                border.width: 1.5 * s

                                Text {
                                    anchors.centerIn: parent
                                    text: root.currentUserDisplayName.length > 0 ? root.currentUserDisplayName.charAt(0) : "S"
                                    font.family: root.boldFont
                                    font.pixelSize: 22 * s
                                    font.weight: Font.Black
                                    color: root.accentColor
                                    renderType: Text.NativeRendering
                                }
                            }

                            // User Details
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3 * s

                                Row {
                                    spacing: 8 * s
                                    Text {
                                        text: root.currentUserDisplayName
                                        font.family: root.boldFont
                                        font.pixelSize: 18 * s
                                        font.letterSpacing: 3 * s
                                        font.weight: Font.Black
                                        color: root.mainTextColor
                                        renderType: Text.NativeRendering
                                    }

                                    Text {
                                        visible: typeof userModel !== "undefined" && userModel && userModel.rowCount() > 1
                                        text: root.userMenuOpen ? "▲" : "▼"
                                        font.pixelSize: 10 * s
                                        color: minUserMa.containsMouse ? root.accentColor : root.dimTextColor
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    text: "ACTIVE OPERATOR // STANDBY"
                                    font.family: root.semiBoldFont
                                    font.pixelSize: 10 * s
                                    font.letterSpacing: 2 * s
                                    font.weight: Font.DemiBold
                                    color: root.dimTextColor
                                    renderType: Text.NativeRendering
                                }
                            }
                        }

                        MouseArea {
                            id: minUserMa
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

                    // Divider
                    Rectangle {
                        width: parent.width
                        height: 1 * s
                        color: Qt.rgba(255, 255, 255, 0.06)
                    }

                    // Password Input Capsule Box
                    Rectangle {
                        id: minInputBox
                        width: parent.width
                        height: 52 * s
                        radius: 12 * s
                        clip: true
                        color: Qt.rgba(5/255, 8/255, 14/255, 0.65)
                        border.color: root.isErrorState ? root.errorColor : (root.isLoggingIn || minPassInput.activeFocus ? root.accentColor : Qt.rgba(255, 255, 255, 0.12))
                        border.width: (root.isErrorState || root.isLoggingIn) ? 2 * s : 1.5 * s

                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        // Scanning Laser Beam during authentication
                        Rectangle {
                            id: scanBar
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 1 * s
                            height: 2.5 * s
                            width: parent.width * 0.38
                            radius: 1 * s
                            visible: root.isLoggingIn
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: root.accentColor }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                            SequentialAnimation on x {
                                running: root.isLoggingIn
                                loops: Animation.Infinite
                                NumberAnimation { from: 0; to: minInputBox.width - scanBar.width; duration: 420; easing.type: Easing.InOutQuad }
                                NumberAnimation { from: minInputBox.width - scanBar.width; to: 0; duration: 420; easing.type: Easing.InOutQuad }
                            }
                        }

                        // Key Icon
                        Text {
                            id: minKeyIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 18 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.isErrorState ? "✕" : "⚿"
                            font.pixelSize: 18 * s
                            color: root.isErrorState ? root.errorColor : (root.isLoggingIn || minPassInput.activeFocus ? root.accentColor : root.dimTextColor)
                        }

                        // Password TextInput
                        TextInput {
                            id: minPassInput
                            anchors.left: minKeyIcon.right
                            anchors.leftMargin: 12 * s
                            anchors.right: minSubmitBtn.left
                            anchors.rightMargin: 10 * s
                            anchors.verticalCenter: parent.verticalCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            color: root.mainTextColor
                            font.family: root.boldFont
                            font.pixelSize: 18 * s
                            font.letterSpacing: 5 * s
                            focus: root.isMinimalLayout
                            activeFocusOnPress: false
                            cursorVisible: true
                            enabled: !root.isLoggingIn
                            renderType: Text.NativeRendering
                            inputMethodHints: root.enableVirtualKeyboard ? Qt.ImhNone : (Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText)
                            onActiveFocusChanged: {
                                if (activeFocus && !root.enableVirtualKeyboard) {
                                    Qt.inputMethod.hide()
                                }
                            }
                            Keys.onReturnPressed: root.startLoginSequence()
                        }

                        // Placeholder Text
                        Text {
                            anchors.left: minKeyIcon.right
                            anchors.leftMargin: 12 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.authSubtitle
                            font.family: root.semiBoldFont
                            font.pixelSize: 11 * s
                            font.letterSpacing: 2 * s
                            color: root.dimTextColor
                            visible: minPassInput.text.length === 0 && !minPassInput.activeFocus && !root.isLoggingIn
                        }

                        // Submit / Scanner Action Button
                        Rectangle {
                            id: minSubmitBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 8 * s
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38 * s
                            height: 38 * s
                            radius: 8 * s
                            color: root.isErrorState
                                   ? root.errorColor
                                   : ((minPassInput.text.length > 0 || minSubMa.containsMouse || root.isLoggingIn) ? root.accentColor : Qt.rgba(255, 255, 255, 0.06))

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                id: minSubmitIcon
                                anchors.centerIn: parent
                                text: root.isLoggingIn ? "◌" : (root.isErrorState ? "✕" : "→")
                                font.family: root.boldFont
                                font.pixelSize: root.isLoggingIn ? 20 * s : 18 * s
                                font.weight: Font.Black
                                color: (minPassInput.text.length > 0 || minSubMa.containsMouse || root.isLoggingIn || root.isErrorState) ? "#080c12" : root.dimTextColor

                                RotationAnimation on rotation {
                                    running: root.isLoggingIn
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 800
                                }
                            }

                            MouseArea {
                                id: minSubMa
                                anchors.fill: parent
                                enabled: !root.isLoggingIn
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.startLoginSequence()
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.IBeamCursor
                            onClicked: {
                                minPassInput.forceActiveFocus()
                                if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
                            }
                        }
                    }

                    // Prompt / Error / Status Label
                    Text {
                        id: minErrText
                        width: parent.width
                        text: root.isErrorState
                              ? "ACCESS DENIED // INVALID CREDENTIALS"
                              : (root.isLoggingIn
                                 ? "AUTHENTICATING CREDENTIALS..."
                                 : (minPassInput.text.length > 0 ? "PRESS ENTER TO UNLOCK" : root.authPrompt))
                        font.family: root.boldFont
                        font.pixelSize: 11 * s
                        font.letterSpacing: 2.5 * s
                        font.weight: Font.Bold
                        color: root.isErrorState
                               ? root.errorColor
                               : (root.isLoggingIn || minPassInput.text.length > 0 ? root.accentColor : root.subTextColor)
                        horizontalAlignment: Text.AlignRight
                        renderType: Text.NativeRendering

                        SequentialAnimation on opacity {
                            running: root.isLoggingIn
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 320; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 320; easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }

        // =====================================================================
        // Prohori Astral Layout: Centered Horizon Architecture
        // (Monumental Centered Chronometer, Horizontal Horizon Cyber-Deck & Rising Violet Smoke)
        // =====================================================================
        Item {
            id: astralContainer
            visible: root.isAstralLayout
            anchors.fill: parent

            // 1. Astral Viewfinder Brackets & Cybernetic Horizon Guidelines
            Item {
                id: astralFrameGuides
                anchors.fill: parent
                opacity: 0.40

                // Top Left Viewfinder Bracket & System Code
                Row {
                    x: 70 * s
                    y: 50 * s
                    spacing: 12 * s

                    Text {
                        text: "┌"
                        font.family: root.boldFont
                        font.pixelSize: 18 * s
                        color: root.accentColor
                    }

                    Text {
                        text: "PROHORI // ASTRAL SENTINEL"
                        font.family: root.boldFont
                        font.pixelSize: 11 * s
                        font.letterSpacing: 3.5 * s
                        font.weight: Font.Bold
                        color: root.dimTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                // Bottom Left Telemetry Status
                Row {
                    x: 70 * s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 45 * s
                    spacing: 10 * s

                    Rectangle {
                        width: 7 * s
                        height: 7 * s
                        radius: 3.5 * s
                        color: root.accentColor
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.25; duration: 1100; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: 0.25; to: 1.0; duration: 1100; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        text: root.isErrorState
                              ? "ASTRAL REJECTED // ACCESS DENIED"
                              : (root.isLoggingIn
                                 ? "ASTRAL LINK // VERIFYING QUANTUM KEY"
                                 : "ASTRAL LINK // SECURE QUANTUM NODE")
                        font.family: root.boldFont
                        font.pixelSize: 11 * s
                        font.letterSpacing: 2 * s
                        font.weight: Font.Bold
                        color: root.isErrorState ? root.errorColor : (root.isLoggingIn ? root.accentColor : root.dimTextColor)
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                // Subtle Horizon Axis Rule Line spanning across bottom
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 70 * s
                    anchors.right: parent.right
                    anchors.rightMargin: 70 * s
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 75 * s
                    height: 1 * s
                    color: Qt.rgba(1, 1, 1, 0.05)
                }
            }

            // 2. Monumental Centered Architectural Chronometer
            Item {
                id: astralCenterClock
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.17
                width: 700 * s
                height: 340 * s

                readonly property real secFrac: (root.curS * 1000 + root.curMS) / 60000.0

                Column {
                    anchors.fill: parent
                    spacing: 14 * s

                    // Telemetry Header Pill
                    Item {
                        width: parent.width
                        height: 28 * s

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 26 * s
                            width: astralTopTxt.width + 28 * s
                            radius: 13 * s
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.10)
                            border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                            border.width: 1 * s

                            Row {
                                anchors.centerIn: parent
                                spacing: 8 * s

                                Rectangle {
                                    width: 5 * s
                                    height: 5 * s
                                    radius: 2.5 * s
                                    color: root.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 1.0; to: 0.3; duration: 900; easing.type: Easing.InOutQuad }
                                        NumberAnimation { from: 0.3; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                                    }
                                }

                                Text {
                                    id: astralTopTxt
                                    text: "ASTRAL SENTINEL // ORBITAL FLUX STABLE"
                                    font.family: root.boldFont
                                    font.pixelSize: 10 * s
                                    font.letterSpacing: 3 * s
                                    font.weight: Font.Bold
                                    color: root.accentColor
                                    renderType: Text.NativeRendering
                                }

                                Rectangle {
                                    width: 5 * s
                                    height: 5 * s
                                    radius: 2.5 * s
                                    color: root.accentColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite
                                        NumberAnimation { from: 0.3; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                                        NumberAnimation { from: 1.0; to: 0.3; duration: 900; easing.type: Easing.InOutQuad }
                                    }
                                }
                            }
                        }
                    }

                    // Monumental Centered Digital Time Display
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16 * s

                        // Hours
                        Text {
                            text: String(root.displayHour).padStart(2, '0')
                            font.family: root.boldFont
                            font.pixelSize: 136 * s
                            font.letterSpacing: -2 * s
                            font.weight: Font.Black
                            color: root.mainTextColor
                            renderType: Text.NativeRendering
                        }

                        // Glowing Breathing Dual Diamond Colon Separator
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 22 * s
                            opacity: (root.curMS < 500) ? 1.0 : 0.25

                            Behavior on opacity { NumberAnimation { duration: 180 } }

                            Rectangle {
                                width: 12 * s
                                height: 12 * s
                                rotation: 45
                                color: root.accentColor
                            }

                            Rectangle {
                                width: 12 * s
                                height: 12 * s
                                rotation: 45
                                color: root.accentColor
                            }
                        }

                        // Minutes
                        Text {
                            text: String(root.curM).padStart(2, '0')
                            font.family: root.boldFont
                            font.pixelSize: 136 * s
                            font.letterSpacing: -2 * s
                            font.weight: Font.Black
                            color: root.accentColor
                            renderType: Text.NativeRendering
                        }

                        // 12H Period Pill (AM / PM)
                        Rectangle {
                            visible: root.hourFormat === "12"
                            anchors.top: parent.top
                            anchors.topMargin: 26 * s
                            width: 36 * s
                            height: 22 * s
                            radius: 6 * s
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
                            border.color: root.accentColor
                            border.width: 1 * s

                            Text {
                                anchors.centerIn: parent
                                text: root.curH >= 12 ? "PM" : "AM"
                                font.family: root.boldFont
                                font.pixelSize: 10 * s
                                font.weight: Font.Black
                                font.letterSpacing: 1 * s
                                color: root.accentColor
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    // Horizontal Cyber Seconds Plasma Rail
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 500 * s
                        height: 32 * s

                        readonly property real railW: 400 * s

                        // Left 00s Marker
                        Text {
                            anchors.right: plasmaRail.left
                            anchors.rightMargin: 12 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: "00s"
                            font.family: root.boldFont
                            font.pixelSize: 10 * s
                            font.letterSpacing: 1.5 * s
                            font.weight: Font.Bold
                            color: Qt.rgba(1, 1, 1, 0.25)
                            renderType: Text.NativeRendering
                        }

                        // Central Rail Track
                        Rectangle {
                            id: plasmaRail
                            anchors.centerIn: parent
                            width: parent.railW
                            height: 4 * s
                            radius: 2 * s
                            color: Qt.rgba(255, 255, 255, 0.08)

                            // Active progress fill
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.max(4 * s, parent.width * astralCenterClock.secFrac)
                                radius: 2 * s
                                color: root.accentColor
                            }

                            // Moving Plasma Cursor Head
                            Item {
                                x: Math.max(0, Math.min(plasmaRail.width - width, (plasmaRail.width * astralCenterClock.secFrac) - (width * 0.5)))
                                anchors.verticalCenter: parent.verticalCenter
                                width: plasmaPill.width
                                height: 32 * s

                                Rectangle {
                                    id: plasmaPill
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: plasmaDot.top
                                    anchors.bottomMargin: 3 * s
                                    width: plasmaTxt.width + 12 * s
                                    height: 18 * s
                                    radius: 5 * s
                                    color: Qt.rgba(14/255, 10/255, 26/255, 0.94)
                                    border.color: root.accentColor
                                    border.width: 1 * s

                                    Text {
                                        id: plasmaTxt
                                        anchors.centerIn: parent
                                        text: String(root.curS).padStart(2, '0') + "s"
                                        font.family: root.boldFont
                                        font.pixelSize: 10 * s
                                        font.weight: Font.Black
                                        font.letterSpacing: 1 * s
                                        color: root.accentColor
                                        renderType: Text.NativeRendering
                                    }
                                }

                                Rectangle {
                                    id: plasmaDot
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10 * s
                                    height: 10 * s
                                    radius: 5 * s
                                    color: root.mainTextColor
                                    border.color: root.accentColor
                                    border.width: 2 * s
                                }
                            }
                        }

                        // Right 60s Marker
                        Text {
                            anchors.left: plasmaRail.right
                            anchors.leftMargin: 12 * s
                            anchors.verticalCenter: parent.verticalCenter
                            text: "60s"
                            font.family: root.boldFont
                            font.pixelSize: 10 * s
                            font.letterSpacing: 1.5 * s
                            font.weight: Font.Bold
                            color: Qt.rgba(1, 1, 1, 0.25)
                            renderType: Text.NativeRendering
                        }
                    }

                    // Celestial Date & Calendar Row
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12 * s

                        Text {
                            text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                            font.family: root.boldFont
                            font.pixelSize: 15 * s
                            font.letterSpacing: 6 * s
                            font.weight: Font.Black
                            color: root.mainTextColor
                            renderType: Text.NativeRendering
                        }

                        Text {
                            text: "◆"
                            font.pixelSize: 8 * s
                            color: root.accentColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: Qt.formatDate(new Date(), "dd MMMM yyyy").toUpperCase()
                            font.family: root.semiBoldFont
                            font.pixelSize: 13 * s
                            font.letterSpacing: 4 * s
                            font.weight: Font.DemiBold
                            color: root.subTextColor
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }

            // 3. Floating Horizon Cyber-Deck (Centered Horizontal Command Console)
            Rectangle {
                id: astralAuthDeck
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.15
                width: 600 * s
                height: 76 * s
                radius: 18 * s
                color: root.isErrorState
                       ? Qt.rgba(36/255, 8/255, 14/255, 0.88)
                       : Qt.rgba(14/255, 10/255, 26/255, 0.80)
                border.color: root.isErrorState
                              ? root.errorColor
                              : (root.isLoggingIn || astralPassInput.activeFocus ? root.accentColor : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35))
                border.width: (root.isErrorState || root.isLoggingIn) ? 2 * s : 1.5 * s

                Behavior on color { ColorAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                // Left Section: User Identity Pod
                Item {
                    id: astralUserPod
                    anchors.left: parent.left
                    anchors.leftMargin: 20 * s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 170 * s
                    height: parent.height

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12 * s

                        // User Avatar Circle
                        Rectangle {
                            width: 44 * s
                            height: 44 * s
                            radius: 22 * s
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                            border.color: root.accentColor
                            border.width: 1.5 * s
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: root.currentUserDisplayName.length > 0 ? root.currentUserDisplayName.charAt(0) : "S"
                                font.family: root.boldFont
                                font.pixelSize: 18 * s
                                font.weight: Font.Black
                                color: root.accentColor
                                renderType: Text.NativeRendering
                            }
                        }

                        // User Display Name & Status
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2 * s
                            width: 110 * s

                            Row {
                                spacing: 6 * s
                                Text {
                                    text: root.currentUserDisplayName
                                    font.family: root.boldFont
                                    font.pixelSize: 14 * s
                                    font.letterSpacing: 2 * s
                                    font.weight: Font.Black
                                    color: root.mainTextColor
                                    elide: Text.ElideRight
                                    renderType: Text.NativeRendering
                                }

                                Text {
                                    visible: typeof userModel !== "undefined" && userModel && userModel.rowCount() > 1
                                    text: root.userMenuOpen ? "▲" : "▼"
                                    font.pixelSize: 9 * s
                                    color: astralUserMa.containsMouse ? root.accentColor : root.dimTextColor
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: "ASTRAL OPERATOR"
                                font.family: root.semiBoldFont
                                font.pixelSize: 9 * s
                                font.letterSpacing: 1.5 * s
                                font.weight: Font.DemiBold
                                color: root.dimTextColor
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    MouseArea {
                        id: astralUserMa
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

                // Vertical Divider 1
                Rectangle {
                    id: astralDiv1
                    anchors.left: astralUserPod.right
                    anchors.leftMargin: 14 * s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1 * s
                    height: 38 * s
                    color: Qt.rgba(255, 255, 255, 0.08)
                }

                // Right Section: Unlock Action Trigger
                Rectangle {
                    id: astralSubmitBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 18 * s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 42 * s
                    height: 42 * s
                    radius: 12 * s
                    color: root.isErrorState
                           ? root.errorColor
                           : ((astralPassInput.text.length > 0 || astralSubMa.containsMouse || root.isLoggingIn) ? root.accentColor : Qt.rgba(255, 255, 255, 0.06))

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        id: astralSubmitIcon
                        anchors.centerIn: parent
                        text: root.isLoggingIn ? "◌" : (root.isErrorState ? "✕" : "→")
                        font.family: root.boldFont
                        font.pixelSize: root.isLoggingIn ? 20 * s : 18 * s
                        font.weight: Font.Black
                        color: (astralPassInput.text.length > 0 || astralSubMa.containsMouse || root.isLoggingIn || root.isErrorState) ? "#080511" : root.dimTextColor

                        RotationAnimation on rotation {
                            running: root.isLoggingIn
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 800
                        }
                    }

                    MouseArea {
                        id: astralSubMa
                        anchors.fill: parent
                        enabled: !root.isLoggingIn
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.startLoginSequence()
                    }
                }

                // Vertical Divider 2
                Rectangle {
                    id: astralDiv2
                    anchors.right: astralSubmitBtn.left
                    anchors.rightMargin: 16 * s
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1 * s
                    height: 38 * s
                    color: Qt.rgba(255, 255, 255, 0.08)
                }

                // Middle Section: Dynamically Stretched Password Capsule & Laser Scanner
                Item {
                    id: astralPassCapsule
                    anchors.left: astralDiv1.right
                    anchors.leftMargin: 16 * s
                    anchors.right: astralDiv2.left
                    anchors.rightMargin: 16 * s
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    clip: true

                    // Scanning Laser Beam during authentication
                    Rectangle {
                        id: astralScanBar
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8 * s
                        height: 2.5 * s
                        width: parent.width * 0.40
                        radius: 1 * s
                        visible: root.isLoggingIn
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: root.accentColor }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        SequentialAnimation on x {
                            running: root.isLoggingIn
                            loops: Animation.Infinite
                            NumberAnimation { from: 0; to: astralPassCapsule.width - astralScanBar.width; duration: 420; easing.type: Easing.InOutQuad }
                            NumberAnimation { from: astralPassCapsule.width - astralScanBar.width; to: 0; duration: 420; easing.type: Easing.InOutQuad }
                        }
                    }

                    // Key Icon
                    Text {
                        id: astralKeyIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 4 * s
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.isErrorState ? "✕" : "⚿"
                        font.pixelSize: 18 * s
                        color: root.isErrorState ? root.errorColor : (root.isLoggingIn || astralPassInput.activeFocus ? root.accentColor : root.dimTextColor)
                    }

                    // Password Input Field
                    TextInput {
                        id: astralPassInput
                        anchors.left: astralKeyIcon.right
                        anchors.leftMargin: 12 * s
                        anchors.right: parent.right
                        anchors.rightMargin: 8 * s
                        anchors.verticalCenter: parent.verticalCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: root.mainTextColor
                        font.family: root.boldFont
                        font.pixelSize: 18 * s
                        font.letterSpacing: 5 * s
                        focus: root.isAstralLayout
                        activeFocusOnPress: false
                        cursorVisible: true
                        enabled: !root.isLoggingIn
                        renderType: Text.NativeRendering
                        inputMethodHints: root.enableVirtualKeyboard ? Qt.ImhNone : (Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText)
                        onActiveFocusChanged: {
                            if (activeFocus && !root.enableVirtualKeyboard) {
                                Qt.inputMethod.hide()
                            }
                        }
                        Keys.onReturnPressed: root.startLoginSequence()
                    }

                    // Placeholder Text
                    Text {
                        anchors.left: astralKeyIcon.right
                        anchors.leftMargin: 12 * s
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.authSubtitle
                        font.family: root.semiBoldFont
                        font.pixelSize: 11 * s
                        font.letterSpacing: 2 * s
                        color: root.dimTextColor
                        visible: astralPassInput.text.length === 0 && !astralPassInput.activeFocus && !root.isLoggingIn
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            astralPassInput.forceActiveFocus()
                            if (!root.enableVirtualKeyboard) Qt.inputMethod.hide()
                        }
                    }
                }
            }

            // 4. Centered Dynamic Status Readout (Below the Auth Deck)
            Text {
                id: astralStatusText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: astralAuthDeck.bottom
                anchors.topMargin: 14 * s
                text: root.isErrorState
                      ? "ACCESS DENIED // INVALID CREDENTIALS"
                      : (root.isLoggingIn
                         ? "AUTHENTICATING ASTRAL QUANTUM KEY..."
                         : (astralPassInput.text.length > 0 ? "PRESS ENTER TO INITIALIZE" : root.authPrompt))
                font.family: root.boldFont
                font.pixelSize: 11 * s
                font.letterSpacing: 3 * s
                font.weight: Font.Bold
                color: root.isErrorState
                       ? root.errorColor
                       : (root.isLoggingIn || astralPassInput.text.length > 0 ? root.accentColor : root.subTextColor)
                renderType: Text.NativeRendering

                SequentialAnimation on opacity {
                    running: root.isLoggingIn
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 320; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 320; easing.type: Easing.InOutSine }
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
            height: root.infoDrawerOpen ? 255 * s : 0
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
                        text: "THEME:"
                        font.family: root.semiBoldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.DemiBold
                        color: root.isLight ? "#64748b" : "#94a3b8"
                        renderType: Text.NativeRendering
                    }
                    Text {
                        text: root.themeName.toUpperCase()
                        font.family: root.boldFont
                        font.pixelSize: 13 * s
                        font.letterSpacing: 1.5 * s
                        font.weight: Font.Bold
                        color: root.accentColor
                        renderType: Text.NativeRendering
                    }
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
        var pw = root.getActivePassword()
        if (pw.length === 0 || root.isLoggingIn) {
            root.focusActiveInput()
            return
        }

        root.isLoggingIn = true
        root.isErrorState = false
        errorResetTimer.stop()

        if (root.isModernLayout) {
            minLoginAnim.start()
        } else if (root.enableWindup) {
            windupAnim.start()
        } else {
            doLogin()
        }
    }

    // High-tech authentication animation sequence timer for minimal layout
    PauseAnimation {
        id: minLoginAnim
        duration: 750
        onFinished: root.doLogin()
    }

    // Smooth unlock dissolve transition when session opens
    ParallelAnimation {
        id: minUnlockAnim
        NumberAnimation { target: mainContainer; property: "opacity"; to: 0; duration: 450; easing.type: Easing.OutCubic }
        NumberAnimation { target: mainContainer; property: "scale"; to: 1.04; duration: 450; easing.type: Easing.OutCubic }
    }

    // 3-Second Error State Reset Timer
    Timer {
        id: errorResetTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.isErrorState = false
            if (typeof minErrText !== "undefined" && minErrText) {
                minErrText.text = (minPassInput.text.length > 0 ? "PRESS ENTER TO UNLOCK" : root.authPrompt)
            }
            if (typeof astralStatusText !== "undefined" && astralStatusText) {
                astralStatusText.text = (astralPassInput.text.length > 0 ? "PRESS ENTER TO INITIALIZE" : root.authPrompt)
            }
            if (typeof errText !== "undefined" && errText) {
                errText.text = ""
            }
            root.focusActiveInput()
        }
    }

    function doLogin() {
        var uname = root.currentUserLoginName
        var pw = root.getActivePassword()
        if (typeof sddm !== "undefined") {
            sddm.login(uname, pw, root.sessionIndex)
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
            root.isLoggingIn = false
            root.isErrorState = false
            errText.text = ""
            if (typeof minErrText !== "undefined" && minErrText) minErrText.text = "ACCESS GRANTED // INITIALIZING SYSTEM"
            if (typeof astralStatusText !== "undefined" && astralStatusText) astralStatusText.text = "ACCESS GRANTED // ASTRAL LINK ESTABLISHED"
            if (root.isModernLayout) {
                minUnlockAnim.start()
            }
        }
        function onLoginFailed() {
            root.isLoggingIn = false
            minLoginAnim.stop()
            windupAnim.stop()
            root.windupOffset = 0
            root.isErrorState = true
            errText.text = "ACCESS DENIED"
            if (typeof minErrText !== "undefined" && minErrText) minErrText.text = "ACCESS DENIED // INVALID CREDENTIALS"
            if (typeof astralStatusText !== "undefined" && astralStatusText) astralStatusText.text = "ACCESS DENIED // INVALID CREDENTIALS"
            passInput.text = ""
            if (typeof minPassInput !== "undefined" && minPassInput) minPassInput.text = ""
            if (typeof astralPassInput !== "undefined" && astralPassInput) astralPassInput.text = ""
            root.focusActiveInput()
            shakeAnim.restart()
            errorResetTimer.restart()
        }
    }

    // High-impact decaying harmonic shake animation across all elements
    SequentialAnimation {
        id: shakeAnim
        alwaysRunToEnd: true
        NumberAnimation { target: root; property: "shakeOffset"; from: 0; to: -18 * s; duration: 40; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 18 * s; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: -14 * s; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 14 * s; duration: 50; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: -9 * s; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 9 * s; duration: 45; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: -4 * s; duration: 40; easing.type: Easing.InOutQuad }
        NumberAnimation { target: root; property: "shakeOffset"; to: 0; duration: 40; easing.type: Easing.OutQuad }
    }

    // Minimal/Classic Top Action Button Component (iOS Liquid Glass Capsule Pill)
    component CwAction: Item {
        id: actItem
        width: actBg.width
        height: 32 * s
        property string label: ""
        property bool isActive: false
        signal clicked()

        // Ambient Liquid Aura
        Rectangle {
            anchors.centerIn: actBg
            width: actBg.width + 6 * s
            height: actBg.height + 6 * s
            radius: actBg.radius + 3 * s
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
            visible: actM.containsMouse || actItem.isActive
            z: -1
        }

        Rectangle {
            id: actBg
            width: actTxt.width + 24 * s
            height: parent.height
            radius: 8 * s
            color: actM.containsMouse
                   ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)
                   : (actItem.isActive
                      ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.10)
                      : (root.isLight ? Qt.rgba(0, 0, 0, 0.05) : Qt.rgba(12/255, 17/255, 26/255, 0.65)))
            border.color: (actM.containsMouse || actItem.isActive)
                          ? root.accentColor
                          : (root.isLight ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(255, 255, 255, 0.08))
            border.width: 1 * s

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            // iOS Liquid Glass Specular Sheen
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1 * s
                anchors.left: parent.left
                anchors.leftMargin: 1 * s
                anchors.right: parent.right
                anchors.rightMargin: 1 * s
                height: parent.height * 0.48
                radius: parent.radius - 1 * s
                clip: true
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, actM.containsMouse ? 0.25 : 0.16) }
                    GradientStop { position: 0.45; color: Qt.rgba(255, 255, 255, 0.05) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Inner Refraction Bevel Rim
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1 * s
                radius: parent.radius - 1 * s
                color: "transparent"
                border.color: actM.containsMouse
                              ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                              : Qt.rgba(255, 255, 255, 0.10)
                border.width: 1 * s
            }

            Text {
                id: actTxt
                anchors.centerIn: parent
                text: label.toUpperCase()
                color: (actM.containsMouse || actItem.isActive) ? root.accentColor : root.subTextColor
                font.family: root.boldFont
                font.pixelSize: 11 * s
                font.letterSpacing: 2.5 * s
                font.weight: Font.Bold
                antialiasing: true
                renderType: Text.NativeRendering

                Behavior on color { ColorAnimation { duration: 150 } }
            }
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
