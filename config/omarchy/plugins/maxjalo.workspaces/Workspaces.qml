import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(2)
  readonly property real circleSize: Math.min(root.barSize - 2, 22)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(3)
    rowSpacing: root.vertical ? Style.space(3) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: wsSlot
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        implicitWidth: root.vertical ? root.barSize : root.circleSize
        implicitHeight: root.vertical ? root.circleSize : root.barSize

        Rectangle {
          anchors.centerIn: parent
          width: root.circleSize
          height: root.circleSize
          radius: root.circleSize / 2
          color: wsSlot.focused
            ? Util.alpha(Color.accent, 0.30)
            : (wsBtn.tooltipHovered ? Util.alpha(root.bar ? root.bar.barForeground : Color.foreground, 0.14) : "transparent")
          border.width: wsSlot.focused ? 1.2 : 0
          border.color: Util.alpha(Color.accent, 0.80)

          Behavior on color { ColorAnimation { duration: 160 } }
        }

        WidgetButton {
          id: wsBtn
          anchors.centerIn: parent
          bar: root.bar
          text: wsSlot.modelData === 10 ? "0" : String(wsSlot.modelData)
          active: wsSlot.focused
          activeColor: root.bar ? root.bar.barForeground : Color.foreground
          opacity: wsSlot.focused ? 1.0 : (wsSlot.occupied ? 0.92 : 0.40)
          horizontalMargin: 0
          verticalPadding: 0
          fixedWidth: root.circleSize
          fixedHeight: root.circleSize
          tooltipText: "Workspace " + wsSlot.modelData
          onPressed: function() { root.focusWorkspace(wsSlot.modelData) }
        }

        Rectangle {
          visible: !wsSlot.focused && wsSlot.occupied
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          width: 4
          height: 2
          radius: 1
          color: Util.alpha(Color.accent, 0.85)
        }
      }
    }
  }
}
