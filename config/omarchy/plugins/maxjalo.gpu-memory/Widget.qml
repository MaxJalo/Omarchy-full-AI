import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.gpu-memory"

  property string usedGiB: "--"
  property string totalGiB: "--"
  property bool available: true

  function toGiBText(mib) {
    return (mib / 1024).toFixed(1)
  }

  function refresh() {
    if (!proc.running) proc.running = true
  }

  function parse(output) {
    var line = String(output || "").trim().split("\n")[0]
    var parts = line.split(",")
    if (parts.length < 2) return
    var usedVal = Number(parts[0].trim())
    var totalVal = Number(parts[1].trim())
    if (isFinite(usedVal) && isFinite(totalVal)) {
      usedGiB = toGiBText(usedVal)
      totalGiB = toGiBText(totalVal)
      available = true
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    command: ["nvidia-smi", "--query-gpu=memory.used,memory.total", "--format=csv,noheader,nounits"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        root.available = false
        root.usedGiB = "--"
        root.totalGiB = "--"
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
    text: root.available ? ("󰢮 " + root.usedGiB + "/" + root.totalGiB + "GiB") : "󰢮 N/A"
    tooltipText: "NVIDIA GPU0 memory"
  }
}
