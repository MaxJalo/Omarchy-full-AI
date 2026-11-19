import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "maxjalo.btop"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    fontFamily: "JetBrainsMono Nerd Font"
    text: "󰄨"
    tooltipText: "Launch btop"
    onPressed: function() {
      if (root.bar) root.bar.run("omarchy-launch-or-focus-tui --app-id=btop-float btop")
    }
  }
}
