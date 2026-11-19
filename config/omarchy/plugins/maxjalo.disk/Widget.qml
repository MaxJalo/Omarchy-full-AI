import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.disk"

  property string percentage: "--"
  property string used: "--"
  property string total: "--"

  function refresh() {
    if (!proc.running) proc.running = true
  }

  function parse(output) {
    var lines = String(output || "").trim().split("\n")
    if (lines.length < 2) return
    var row = lines[1].trim().split(/\s+/)
    if (row.length < 6) return

    total = row[1]
    used = row[2]
    percentage = String(row[4]).replace("%", "")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    command: ["df", "-h", "/"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
    }
  }

  Timer {
    interval: 30000
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
    active: Number(root.percentage) >= 85
    activeColor: Number(root.percentage) >= 95 ? Color.urgent : Color.accent
    text: "󰋊 " + root.percentage + "%"
    tooltipText: "Root /: " + root.used + " / " + root.total + " (" + root.percentage + "%)"
  }
}
