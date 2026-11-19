import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.cpu-load"

  property int usage: 0
  property real prevTotal: -1
  property real prevIdle: -1

  function refresh() {
    if (!proc.running) proc.running = true
  }

  function parse(output) {
    var lines = String(output || "").split("\n")
    if (lines.length === 0) return
    var m = lines[0].trim().match(/^cpu\s+(.+)$/)
    if (!m) return
    var parts = m[1].trim().split(/\s+/)
    if (parts.length < 4) return

    var total = 0
    for (var i = 0; i < parts.length; i++) total += Number(parts[i])
    var idle = Number(parts[3]) + (parts.length > 4 ? Number(parts[4]) : 0)

    if (prevTotal >= 0 && total > prevTotal) {
      var deltaTotal = total - prevTotal
      var deltaIdle = idle - prevIdle
      usage = Math.max(0, Math.min(100, Math.round((1 - (deltaIdle / deltaTotal)) * 100)))
    }

    prevTotal = total
    prevIdle = idle
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    command: ["cat", "/proc/stat"]
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
    active: root.usage >= 70
    activeColor: root.usage >= 90 ? Color.urgent : Color.accent
    text: "󰻠 " + root.usage + "%"
    tooltipText: "CPU load: " + root.usage + "% (click for btop)"
    onPressed: function() {
      if (root.bar) root.bar.run("omarchy-launch-or-focus-tui --app-id=btop-float btop")
    }
  }
}
