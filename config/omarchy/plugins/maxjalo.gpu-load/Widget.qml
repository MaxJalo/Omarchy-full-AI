import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.gpu-load"

  property string usage: "--"
  property bool available: true

  function refresh() {
    if (!proc.running) proc.running = true
  }

  function parse(output) {
    var line = String(output || "").trim().split("\n")[0]
    var value = Number(line)
    if (isFinite(value)) {
      usage = String(Math.round(value))
      available = true
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.available = false
        root.usage = "--"
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    fontFamily: "JetBrainsMono Nerd Font"
    active: root.available && Number(root.usage) >= 75
    activeColor: Number(root.usage) >= 92 ? Color.urgent : Color.accent
    text: "󰢮 " + (root.available ? (root.usage + "%") : "N/A")
    tooltipText: "NVIDIA GPU0 load"
    onPressed: function() {
      if (root.bar) root.bar.run("omarchy-launch-or-focus-tui --app-id=btop-float btop")
    }
  }
}
