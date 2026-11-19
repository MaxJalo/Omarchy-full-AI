import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.ram"

  property int percentage: 0
  property string used: "--"
  property string total: "--"

  function formatGiB(kb) {
    return (kb / 1024 / 1024).toFixed(1) + "GiB"
  }

  function refresh() {
    if (!proc.running) proc.running = true
  }

  function parse(output) {
    var lines = String(output || "").split("\n")
    var totalKb = 0
    var availKb = 0

    for (var i = 0; i < lines.length; i++) {
      if (lines[i].indexOf("MemTotal:") === 0) totalKb = Number(lines[i].trim().split(/\s+/)[1])
      else if (lines[i].indexOf("MemAvailable:") === 0) availKb = Number(lines[i].trim().split(/\s+/)[1])
    }

    if (totalKb > 0) {
      var usedKb = Math.max(0, totalKb - availKb)
      percentage = Math.round((usedKb / totalKb) * 100)
      used = formatGiB(usedKb)
      total = formatGiB(totalKb)
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    command: ["cat", "/proc/meminfo"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
    }
  }

  Timer {
    interval: 3000
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
    active: root.percentage >= 75
    activeColor: root.percentage >= 90 ? Color.urgent : Color.accent
    text: "󰍛 " + root.used + "/" + root.total
    tooltipText: "RAM: " + root.percentage + "% (" + root.used + " / " + root.total + ") — click for btop"
    onPressed: function() {
      if (root.bar) root.bar.run("omarchy-launch-or-focus-tui --app-id=btop-float btop")
    }
  }
}
