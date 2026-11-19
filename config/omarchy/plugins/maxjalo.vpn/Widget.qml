import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.vpn"

  property bool vpnConnected: false
  property bool appRunning: false

  function refresh() {
    if (!probe.running) probe.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Process {
    id: probe
    command: [
      "bash", "-c",
      "running=0; connected=0; pgrep -xi happ >/dev/null 2>&1 && running=1; ip -o link show 2>/dev/null | grep -qiE 'tun|wg|singbox|xray|utun' && connected=1; echo \"$running:$connected\""
    ]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parts = String(text || "").trim().split(":")
        root.appRunning = parts[0] === "1"
        root.vpnConnected = parts[1] === "1"
      }
    }
  }

  Timer {
    interval: 3000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    fontFamily: "JetBrainsMono Nerd Font"
    text: root.vpnConnected ? "󰒘" : "󰦞"
    active: root.vpnConnected || root.appRunning
    activeColor: root.vpnConnected ? Color.accent : (root.bar ? root.bar.barForeground : Color.foreground)
    tooltipText: root.vpnConnected
      ? "VPN активен (клик — открыть Happ)"
      : (root.appRunning ? "Happ запущен (клик — открыть окно)" : "VPN выключен (клик — запустить Happ)")
    onPressed: function() {
      if (root.bar) {
        root.bar.run("omarchy-launch-or-focus happ \"uwsm-app -- /usr/bin/happ\"")
      }
    }
  }
}
