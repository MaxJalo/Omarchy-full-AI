import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.cpu-temp"

  property int temperatureC: -1

  function refresh() {
    if (!proc.running) proc.running = true
  }

  function parse(output) {
    var value = Number(String(output || "").trim())
    if (isFinite(value)) temperatureC = Math.round(value)
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: proc
    command: [
      "bash", "-lc",
      "t=$(sensors -u 2>/dev/null | awk '/temp[0-9]+_input:/ {print $2}' | sort -nr | head -n1); if [ -z \"$t\" ]; then t=$(for f in /sys/class/hwmon/hwmon*/temp*_input; do [ -r \"$f\" ] || continue; v=$(cat \"$f\" 2>/dev/null); [ -n \"$v\" ] || continue; awk -v x=\"$v\" 'BEGIN{printf \"%.1f\\n\", x/1000}'; done | sort -nr | head -n1); fi; [ -n \"$t\" ] && printf \"%s\\n\" \"$t\""
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.parse(text)
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
    active: root.temperatureC >= 75
    activeColor: root.temperatureC >= 85 ? Color.urgent : Color.accent
    text: "󰏈 " + (root.temperatureC >= 0 ? (root.temperatureC + "°C") : "--°C")
    tooltipText: root.temperatureC >= 85
      ? "CPU temperature critical"
      : (root.temperatureC >= 75 ? "CPU temperature warning" : "CPU temperature")
    onPressed: function() {
      if (root.bar) root.bar.run("omarchy-launch-or-focus-tui --app-id=btop-float btop")
    }
  }
}
