import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import SddmComponents 2.0

Rectangle {
  id: root
  width: 1280
  height: 720
  color: "#090b0e"

  property int userIndex: {
    var last = userModel.lastUser || ""
    for (var i = 0; i < userModel.count; i++) {
      var u = userModel.data(userModel.index(i, 0), Qt.DisplayRole)
      if (u === last) return i
    }
    return 0
  }
  readonly property string currentUser: {
    if (userModel.count > 0) {
      var u = userModel.data(userModel.index(userIndex, 0), Qt.DisplayRole)
      if (u) return String(u)
    }
    return userModel.lastUser || "maxjalo"
  }

  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString().toLowerCase()
      if (name.indexOf("uwsm") !== -1 || name.indexOf("omarchy") !== -1 || name.indexOf("hyprland") !== -1)
        return i
    }
    return Math.max(0, sessionModel.lastIndex)
  }
  readonly property string currentSessionName: {
    if (sessionModel.rowCount() > 0) {
      var n = sessionModel.data(sessionModel.index(sessionIndex, 0), Qt.DisplayRole)
      if (n) return String(n)
    }
    return "Hyprland"
  }

  property bool loginFailed: false
  property bool submitting: false
  property bool transitioningOut: false
  property string failureMessage: ""
  property date currentTime: new Date()

  readonly property string placeholderText: "Введите пароль"
  readonly property int fieldWidth: 280
  readonly property int fieldHeight: 46
  readonly property int engagedWidth: 294
  readonly property int engagedHeight: 48
  readonly property int submitWidth: 48
  readonly property int fieldFontSize: 14
  readonly property int passwordDotFontSize: 15
  readonly property int passwordDotLetterSpacing: 4
  readonly property bool fieldEngaged: passwordInput.activeFocus || passwordInput.text.length > 0
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 6) / dotMetrics.advanceWidth)
    : 1

  function submitLogin() {
    if (root.submitting || passwordInput.text.length === 0) return
    root.submitting = true
    root.loginFailed = false
    root.failureMessage = ""
    loginDelayTimer.restart()
  }

  Timer {
    id: loginDelayTimer
    interval: 480
    repeat: false
    onTriggered: {
      sddm.login(root.currentUser, passwordInput.text, root.sessionIndex)
    }
  }

  Timer {
    id: fadeOutTimer
    interval: 220
    repeat: false
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      loginDelayTimer.stop()
      root.transitioningOut = false
      root.submitting = false
      root.loginFailed = true
      root.failureMessage = "Неверный пароль"
      passwordInput.text = ""
      passwordInput.forceActiveFocus()
      shakeAnim.restart()
    }
    function onLoginSucceeded() {
      root.transitioningOut = true
      root.submitting = false
      root.loginFailed = false
      root.failureMessage = ""
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: root.currentTime = new Date()
  }

  TextMetrics {
    id: dotMetrics
    font.family: "JetBrainsMono Nerd Font, monospace"
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Component.onCompleted: passwordInput.forceActiveFocus()

  Item {
    id: sceneRoot
    anchors.fill: parent
    opacity: root.transitioningOut ? 0.0 : 1.0
    scale: root.transitioningOut ? 1.03 : 1.0

    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    Image {
      id: wallpaper
      anchors.fill: parent
      source: "forest.jpg"
      fillMode: Image.PreserveAspectCrop
      asynchronous: false
      cache: true
      sourceSize.width: width
      sourceSize.height: height
    }

    Item {
      id: edgeBlurMask
      anchors.fill: parent
      visible: false

      Canvas {
        id: edgeBlurMaskCanvas
        anchors.fill: parent

        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          if (width <= 0 || height <= 0) return

          ctx.save()
          var cx = width * 0.5
          var cy = height * 0.5
          var rx = width * 0.54
          var ry = height * 0.54
          ctx.translate(cx, cy)
          ctx.scale(1, ry / rx)
          var grad = ctx.createRadialGradient(0, 0, rx * 0.34, 0, 0, rx * 1.02)
          grad.addColorStop(0.0, "rgba(255,255,255,0.0)")
          grad.addColorStop(0.38, "rgba(255,255,255,0.18)")
          grad.addColorStop(0.68, "rgba(255,255,255,0.68)")
          grad.addColorStop(0.88, "rgba(255,255,255,0.96)")
          grad.addColorStop(1.0, "rgba(255,255,255,1.0)")
          ctx.fillStyle = grad
          ctx.fillRect(-cx, -cy * (rx / ry), width, height * (rx / ry))
          ctx.restore()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()
      }
    }

    ShaderEffectSource {
      id: edgeBlurMaskSource
      sourceItem: edgeBlurMask
      hideSource: true
      live: true
    }

    MultiEffect {
      anchors.fill: wallpaper
      source: wallpaper
      autoPaddingEnabled: false
      blurEnabled: wallpaper.status === Image.Ready
      blur: 1.0
      blurMax: 72
      blurMultiplier: 1.25
      contrast: -0.04
      brightness: -0.03
      maskEnabled: true
      maskSource: edgeBlurMaskSource
    }

    Canvas {
      anchors.fill: parent
      onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (width <= 0 || height <= 0) return
        var grad = ctx.createRadialGradient(width * 0.5, height * 0.5, Math.min(width, height) * 0.25,
                                            width * 0.5, height * 0.5, Math.max(width, height) * 0.72)
        grad.addColorStop(0.0, "rgba(0,0,0,0.04)")
        grad.addColorStop(0.65, "rgba(0,0,0,0.20)")
        grad.addColorStop(1.0, "rgba(0,0,0,0.44)")
        ctx.fillStyle = grad
        ctx.fillRect(0, 0, width, height)
      }
      onWidthChanged: requestPaint()
      onHeightChanged: requestPaint()
    }

    MouseArea {
      anchors.fill: parent
      onClicked: passwordInput.forceActiveFocus()
    }

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: Math.round(parent.height * 0.10)
      width: clockBlock.implicitWidth + 24
      height: clockBlock.implicitHeight + 16

      Column {
        id: clockBlock
        anchors.centerIn: parent
        spacing: 2
        visible: false

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatDate(root.currentTime, "dddd, d MMMM")
          color: Qt.rgba(1, 1, 1, 0.90)
          font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
          font.pixelSize: 17
          font.weight: Font.Medium
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Qt.formatTime(root.currentTime, "HH:mm")
          color: Qt.rgba(1, 1, 1, 0.96)
          font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
          font.pixelSize: 78
          font.weight: Font.DemiBold
          font.letterSpacing: -2
        }
      }

      MultiEffect {
        anchors.fill: clockBlock
        source: clockBlock
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.45)
        shadowBlur: 0.55
        shadowVerticalOffset: 3
        shadowHorizontalOffset: 0
      }
    }

    Column {
      id: authCluster
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.round(parent.height * 0.13)
      spacing: 18

      Column {
        z: 2
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 56
          height: 56
          radius: 28
          color: userSwitchMouse.containsMouse && userModel.count > 1 ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.15)
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.30)

          Text {
            anchors.centerIn: parent
            text: root.currentUser.length > 0 ? root.currentUser.charAt(0).toUpperCase() : "M"
            color: Qt.rgba(1, 1, 1, 0.95)
            font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: 23
            font.weight: Font.DemiBold
          }

          MouseArea {
            id: userSwitchMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: userModel.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
              if (userModel.count > 1) root.userIndex = (root.userIndex + 1) % userModel.count
              passwordInput.forceActiveFocus()
            }
          }
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.currentUser
          color: Qt.rgba(1, 1, 1, 0.94)
          font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
          font.pixelSize: 15
          font.weight: Font.Medium
          bottomPadding: 2
        }
      }

      Item {
        id: inputFieldContainer
        z: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: inputField.width
        height: inputField.height

        property real shakeOffset: 0

        SequentialAnimation {
          id: shakeAnim
          NumberAnimation { target: inputFieldContainer; property: "shakeOffset"; to: -10; duration: 45; easing.type: Easing.OutQuad }
          NumberAnimation { target: inputFieldContainer; property: "shakeOffset"; to: 10; duration: 60; easing.type: Easing.InOutQuad }
          NumberAnimation { target: inputFieldContainer; property: "shakeOffset"; to: -7; duration: 55; easing.type: Easing.InOutQuad }
          NumberAnimation { target: inputFieldContainer; property: "shakeOffset"; to: 5; duration: 50; easing.type: Easing.InOutQuad }
          NumberAnimation { target: inputFieldContainer; property: "shakeOffset"; to: 0; duration: 45; easing.type: Easing.OutQuad }
        }

        Item {
          id: inputField
          readonly property int blurPadding: 12
          width: root.fieldWidth
          height: root.fieldHeight
          property real radius: 23
          x: inputFieldContainer.shakeOffset

          states: [
            State {
              name: "submitting"
              when: root.submitting
              PropertyChanges {
                inputField.width: root.submitWidth
                inputField.height: root.submitWidth
                inputField.radius: 24
              }
            },
            State {
              name: "engaged"
              when: !root.submitting && root.fieldEngaged
              PropertyChanges {
                inputField.width: root.engagedWidth
                inputField.height: root.engagedHeight
                inputField.radius: 24
              }
            }
          ]

          Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
          Behavior on radius { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

          Item {
            anchors.fill: parent
            z: -1

            ShaderEffectSource {
              id: fieldBackdropSource
              x: -inputField.blurPadding
              y: -inputField.blurPadding
              width: inputField.width + inputField.blurPadding * 2
              height: inputField.height + inputField.blurPadding * 2
              sourceItem: wallpaper
              live: true
              hideSource: false
              sourceRect: {
                var _deps = root.width + root.height + authCluster.y + authCluster.height + inputField.width + inputField.height + inputField.x
                var p = inputField.mapToItem(wallpaper, -inputField.blurPadding, -inputField.blurPadding)
                return Qt.rect(p.x, p.y, width, height)
              }
            }

            MultiEffect {
              id: fieldBackdropBlur
              anchors.fill: fieldBackdropSource
              source: fieldBackdropSource
              autoPaddingEnabled: false
              blurEnabled: wallpaper.status === Image.Ready
              blur: 1.0
              blurMax: 64
              blurMultiplier: 1.35
              saturation: 0.25
              brightness: 0.04
              visible: false
            }

            ShaderEffect {
              x: -inputField.blurPadding
              y: -inputField.blurPadding
              width: inputField.width + inputField.blurPadding * 2
              height: inputField.height + inputField.blurPadding * 2
              blending: true
              property var sourceTexture: fieldBackdropBlur
              property real fieldW: inputField.width
              property real fieldH: inputField.height
              property real fieldRadius: inputField.radius
              property real pad: inputField.blurPadding
              property real engaged: root.fieldEngaged ? 1.0 : 0.0
              property real errorState: root.loginFailed ? 1.0 : 0.0

              Behavior on engaged { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
              Behavior on errorState { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

              fragmentShader: Qt.resolvedUrl("liquidglass.frag.qsb")
            }
          }

          TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 38
            anchors.rightMargin: 38
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            activeFocusOnPress: true
            clip: true
            enabled: !root.submitting
            readOnly: root.submitting
            echoMode: TextInput.Password
            passwordCharacter: "\u25CF"
            passwordMaskDelay: 0
            color: "#ffffff"
            selectionColor: Qt.rgba(1, 1, 1, 0.30)
            selectedTextColor: "#ffffff"
            font.family: "JetBrainsMono Nerd Font, monospace"
            font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
            font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
            cursorVisible: activeFocus && !root.submitting && !root.loginFailed && text.length > 0
            opacity: root.submitting ? 0 : 1
            focus: true
            cursorDelegate: Rectangle {
              width: 2
              color: Qt.rgba(1, 1, 1, 0.9)
              visible: passwordInput.cursorVisible
            }

            onTextChanged: {
              if (text.length > 0 && root.loginFailed) {
                root.loginFailed = false
                root.failureMessage = ""
              }
            }

            onAccepted: root.submitLogin()

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                passwordInput.text = ""
                event.accepted = true
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            anchors.fill: passwordInput
            text: root.submitting ? "" : (root.loginFailed ? root.failureMessage : root.placeholderText)
            visible: passwordInput.text.length === 0 && !root.submitting
            color: root.loginFailed ? "#ffb4b4" : Qt.rgba(1, 1, 1, 0.72)
            font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: root.fieldFontSize
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          Rectangle {
            visible: passwordInput.text.length > 0 && !root.submitting
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 30
            height: 30
            radius: 15
            color: submitMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.34) : Qt.rgba(1, 1, 1, 0.20)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.38)

            Text {
              anchors.centerIn: parent
              text: "󰁔"
              color: "#ffffff"
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 15
            }

            MouseArea {
              id: submitMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.submitLogin()
            }
          }

          Canvas {
            id: ringSpinner
            anchors.centerIn: parent
            width: 24
            height: 24
            visible: root.submitting

            RotationAnimator {
              target: ringSpinner
              from: 0
              to: 360
              duration: 750
              loops: Animation.Infinite
              running: root.submitting
            }

            onPaint: {
              var ctx = getContext("2d")
              ctx.clearRect(0, 0, width, height)
              ctx.lineWidth = 2.5
              ctx.lineCap = "round"

              ctx.strokeStyle = "rgba(255,255,255,0.22)"
              ctx.beginPath()
              ctx.arc(width / 2, height / 2, width / 2 - 2.5, 0, Math.PI * 2)
              ctx.stroke()

              ctx.strokeStyle = "rgba(255,255,255,0.94)"
              ctx.beginPath()
              ctx.arc(width / 2, height / 2, width / 2 - 2.5, -Math.PI / 2, Math.PI * 0.45)
              ctx.stroke()
            }

            onVisibleChanged: if (visible) requestPaint()
          }
        }
      }
    }

    Row {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: 24
      anchors.bottomMargin: 22
      spacing: 10

      Rectangle {
        height: 34
        width: sessionLabel.implicitWidth + 24
        radius: 17
        visible: sessionModel.rowCount() > 0
        color: sessionMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.26)

        Text {
          id: sessionLabel
          anchors.centerIn: parent
          text: "󰍹  " + root.currentSessionName
          color: Qt.rgba(1, 1, 1, 0.90)
          font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
          font.pixelSize: 12
        }

        MouseArea {
          id: sessionMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (sessionModel.rowCount() > 1) {
              root.sessionIndex = (root.sessionIndex + 1) % sessionModel.rowCount()
            }
          }
        }
      }

      Rectangle {
        width: 34
        height: 34
        radius: 17
        color: rebootMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.24) : Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.26)

        Text {
          anchors.centerIn: parent
          text: "󰜉"
          color: Qt.rgba(1, 1, 1, 0.90)
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
        }

        MouseArea {
          id: rebootMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sddm.reboot()
        }
      }

      Rectangle {
        width: 34
        height: 34
        radius: 17
        color: powerMouse.containsMouse ? Qt.rgba(1, 0.35, 0.35, 0.35) : Qt.rgba(1, 1, 1, 0.12)
        border.width: 1
        border.color: powerMouse.containsMouse ? Qt.rgba(1, 0.55, 0.55, 0.65) : Qt.rgba(1, 1, 1, 0.26)

        Text {
          anchors.centerIn: parent
          text: "󰐥"
          color: Qt.rgba(1, 1, 1, 0.92)
          font.family: "JetBrainsMono Nerd Font"
          font.pixelSize: 15
        }

        MouseArea {
          id: powerMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: sddm.powerOff()
        }
      }
    }
  }
}
