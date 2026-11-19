import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  property string passwordText: ""
  property bool syncingPasswordText: false
  property string userName: Quickshell.env("USER") || "maxjalo"
  property bool unlockingTransition: false

  property bool pseudoSubmitting: false
  property string queuedPassword: ""
  property date currentTime: new Date()

  readonly property string resolvedBgPath: root.backgroundPath.length > 0
    ? root.backgroundPath
    : (Quickshell.env("HOME") + "/Pictures/forest.jpg")
  readonly property string placeholderText: "Введите пароль"
  readonly property int fieldWidth: 280
  readonly property int fieldHeight: 46
  readonly property int engagedWidth: 294
  readonly property int engagedHeight: 48
  readonly property int submitWidth: 48
  readonly property int fieldFontSize: 14
  readonly property int passwordDotFontSize: 15
  readonly property int passwordDotLetterSpacing: 4
  readonly property real fingerprintReserve: (fingerprintConfigured || passwordInput.text.length > 0) ? 34 : 16
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 6) / dotMetrics.advanceWidth)
    : 1
  readonly property bool submitting: authenticatingPassword || pseudoSubmitting
  readonly property bool showPasswordCursor: inputEnabled && !submitting && failureMessage.length === 0
  readonly property bool fieldEngaged: passwordInput.activeFocus || passwordInput.text.length > 0
  readonly property bool hasError: failureMessage.length > 0

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function fileUrl(path) {
    if (!path) return ""
    var encoded = String(path).split("/").map(encodeURIComponent).join("/")
    return "file://" + encoded + "?v=" + backgroundVersion
  }

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  function beginSubmit(pwd) {
    if (!pwd || pwd.length === 0 || root.submitting) return
    root.queuedPassword = pwd
    root.pseudoSubmitting = true
    submitDelayTimer.restart()
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  onPasswordTextChanged: syncPasswordText()
  onFailedAttemptsChanged: {
    if (failedAttempts > 0) {
      root.pseudoSubmitting = false
      shakeAnim.restart()
    }
  }
  onInputEnabledChanged: {
    if (inputEnabled) {
      root.pseudoSubmitting = false
      Qt.callLater(forcePasswordFocus)
    }
  }
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  Timer {
    id: submitDelayTimer
    interval: 480
    repeat: false
    onTriggered: {
      var pwd = root.queuedPassword
      root.queuedPassword = ""
      if (pwd.length > 0) root.submitPassword(pwd)
      Qt.callLater(function() {
        if (!root.authenticatingPassword) root.pseudoSubmitting = false
      })
    }
  }

  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    onTriggered: root.currentTime = new Date()
  }

  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    id: sceneRoot
    anchors.fill: parent
    color: "#090b0e"
    opacity: root.unlockingTransition ? 0.0 : 1.0
    scale: root.unlockingTransition ? 1.03 : 1.0

    Behavior on opacity { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.loadBackground ? root.fileUrl(root.resolvedBgPath) : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: width
      sourceSize.height: height
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
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    // macOS-style top date + large clock with soft drop shadow (no harsh outline)
    Item {
      id: clockBlockWrapper
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

    // Lower-center user badge + Liquid Glass input pill
    Column {
      id: authCluster
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.round(parent.height * 0.13)
      spacing: 18

      // User avatar + name above the pill (z: 2 so pill blur padding never clips text)
      Column {
        id: userBadge
        z: 2
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 56
          height: 56
          radius: 28
          color: Qt.rgba(1, 1, 1, 0.15)
          border.width: 1
          border.color: Qt.rgba(1, 1, 1, 0.30)

          Text {
            anchors.centerIn: parent
            text: root.userName.length > 0 ? root.userName.charAt(0).toUpperCase() : "M"
            color: Qt.rgba(1, 1, 1, 0.95)
            font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
            font.pixelSize: 23
            font.weight: Font.DemiBold
          }
        }

        Text {
          id: userNameLabel
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.userName
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
              blurEnabled: root.loadBackground && wallpaper.status === Image.Ready
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
              property real errorState: root.hasError ? 1.0 : 0.0

              Behavior on engaged { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
              Behavior on errorState { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

              fragmentShader: Qt.resolvedUrl("liquidglass.frag.qsb")
            }
          }

          TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 16 + root.fingerprintReserve
            anchors.rightMargin: 16 + root.fingerprintReserve
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            activeFocusOnPress: true
            clip: true
            enabled: root.inputEnabled && !root.submitting
            readOnly: root.submitting
            echoMode: TextInput.Password
            passwordCharacter: "\u25CF"
            passwordMaskDelay: 0
            color: "#ffffff"
            selectionColor: Qt.rgba(1, 1, 1, 0.30)
            selectedTextColor: "#ffffff"
            font.family: Style.font.family
            font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
            font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
            cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
            opacity: root.submitting ? 0 : 1
            cursorDelegate: Rectangle {
              width: 2
              color: Qt.rgba(1, 1, 1, 0.9)
              visible: passwordInput.cursorVisible
            }

            onTextChanged: {
              if (!root.syncingPasswordText) root.passwordTextEdited(text)
              if (text.length > 0) root.wakeRequested()
              if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
            }

            onAccepted: {
              var submitted = root.passwordText
              root.passwordTextEdited("")
              if (submitted.length > 0) root.beginSubmit(submitted)
            }

            Keys.onPressed: function(event) {
              root.wakeRequested()
              if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
                root.passwordTextEdited("")
                event.accepted = true
              }
            }
          }

          Text {
            textFormat: Text.PlainText
            anchors.fill: passwordInput
            text: root.submitting ? "" : (root.hasError ? root.failureMessage : root.placeholderText)
            visible: passwordInput.text.length === 0 && !root.submitting
            color: root.hasError ? "#ffb4b4" : Qt.rgba(1, 1, 1, 0.72)
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
              onClicked: {
                var submitted = root.passwordText
                root.passwordTextEdited("")
                if (submitted.length > 0) root.beginSubmit(submitted)
              }
            }
          }

          Text {
            id: fingerprintIcon
            objectName: "fingerprintIndicator"
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            visible: root.fingerprintConfigured && passwordInput.text.length === 0 && !root.submitting
            text: "󰈷"
            color: Qt.rgba(1, 1, 1, 0.72)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 17
          }

          // Smooth custom macOS-style ring spinner during 0.5s submit
          Canvas {
            id: ringSpinner
            anchors.centerIn: parent
            width: 24
            height: 24
            visible: root.submitting
            property real angleOffset: 0

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

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.hasError && passwordInput.text.length > 0
        text: root.failureMessage
        color: "#ffb4b4"
        font.family: "Inter, JetBrainsMono Nerd Font, sans-serif"
        font.pixelSize: 12
      }
    }
  }
}
