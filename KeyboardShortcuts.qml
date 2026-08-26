import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.Commons
import qs.Ui
import "KeyboardModel.js" as KeyboardModel

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property var bindings: []
  property string loadError: ""
  property string selectedKey: ""

  property var pinnedModifiers: ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
  property var heldModifiers: ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  readonly property int cornerRadius: Style.cornerRadius
  readonly property int unit: Math.max(38, Math.min(58, Math.floor((panel.width - Style.space(100)) / 15.5)))
  readonly property int keyGap: Math.max(3, Style.space(4))
  readonly property int cardWidth: Math.min(panel.width - Style.gapsOut * 2, unit * 15.5 + Style.space(56))
  readonly property int cardHeight: Math.min(
    panel.height - Style.gapsOut * 2,
    unit * 6 + keyGap * 5 + Style.space(150)
  )

  function pluginPath(name) {
    var directory = manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
    return directory.replace(/\/$/, "") + "/" + name
  }

  function activeModifiers() {
    var active = []
    for (var i = 0; i < KeyboardModel.modifierOrder.length; i++) {
      var name = KeyboardModel.modifierOrder[i]
      if (pinnedModifiers[name] || heldModifiers[name]) active.push(name)
    }
    return active
  }

  function modifierActive(name) {
    return pinnedModifiers[name] === true || heldModifiers[name] === true
  }

  function clearModifiers() {
    pinnedModifiers = ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
    heldModifiers = ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
    selectedKey = ""
  }

  function toggleModifier(name) {
    var next = {}
    for (var i = 0; i < KeyboardModel.modifierOrder.length; i++) {
      var modifierName = KeyboardModel.modifierOrder[i]
      next[modifierName] = modifierName === name ? !pinnedModifiers[modifierName] : pinnedModifiers[modifierName]
    }
    pinnedModifiers = next
    selectedKey = ""
  }

  function setHeldModifier(name, value) {
    if (heldModifiers[name] === value) return
    var next = {}
    for (var i = 0; i < KeyboardModel.modifierOrder.length; i++) {
      var modifierName = KeyboardModel.modifierOrder[i]
      next[modifierName] = modifierName === name ? value : heldModifiers[modifierName]
    }
    heldModifiers = next
    selectedKey = ""
  }

  function updatePhysicalModifier(event, pressed) {
    if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R)
      setHeldModifier("SUPER", pressed)
    else if (event.key === Qt.Key_Shift)
      setHeldModifier("SHIFT", pressed)
    else if (!pressed && heldModifiers.SHIFT === true && event.key === Qt.Key_CapsLock)
      // Some XKB keymaps report a Shift release as CapsLock. Only apply this
      // compatibility path while Shift is known to be held.
      setHeldModifier("SHIFT", false)
    else if (event.key === Qt.Key_Control)
      setHeldModifier("CTRL", pressed)
    else if (event.key === Qt.Key_Alt)
      setHeldModifier("ALT", pressed)
  }

  function matchesFor(keyId) {
    return KeyboardModel.bindingsFor(bindings, keyId, activeModifiers())
  }

  function selectedBindings() {
    return selectedKey ? matchesFor(selectedKey) : []
  }

  function parseBindings(raw) {
    try {
      var parsed = JSON.parse(raw || "[]")
      if (!Array.isArray(parsed)) {
        loadError = parsed.error || "The binding provider returned invalid data."
        bindings = []
        return
      }
      bindings = parsed
      loadError = ""
    } catch (error) {
      bindings = []
      loadError = "Could not parse the configured shortcuts."
    }
  }

  function reload() {
    if (bindingProcess.running) return
    loadError = ""
    bindingProcess.command = [pluginPath("scripts/list-bindings")]
    bindingProcess.running = true
  }

  function open(payloadJson) {
    clearModifiers()
    opened = true
    reload()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    clearModifiers()
    opened = false
  }

  function dismiss() {
    clearModifiers()
    opened = false
    if (shell && typeof shell.hide === "function") shell.hide(manifest.id)
  }

  function toggle() {
    if (opened) dismiss()
    else open("{}")
  }

  Process {
    id: bindingProcess
    stdout: StdioCollector {
      id: bindingOutput
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: bindingError
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode === 0) root.parseBindings(bindingOutput.text)
      else root.loadError = String(bindingError.text || "Unable to load configured shortcuts.").trim()
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "keyboard-shortcuts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
      preventStealing: true
      onPressed: function(mouse) { mouse.accepted = true }
      onClicked: root.dismiss()
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      anchors.centerIn: parent
      radius: root.cornerRadius
      color: root.background
      borderSpec: root.borderSpec
      padding: Style.spacing.panelPadding
      clip: true

      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        preventStealing: true
        onPressed: function(mouse) { mouse.accepted = true }
        onClicked: function(mouse) { mouse.accepted = true }
      }

      Item {
        id: keyCatcher
        anchors.fill: parent
        focus: true
        onActiveFocusChanged: if (!activeFocus)
          root.heldModifiers = ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.dismiss()
            event.accepted = true
            return
          }
          root.updatePhysicalModifier(event, true)
          event.accepted = true
        }
        Keys.onReleased: function(event) {
          root.updatePhysicalModifier(event, false)
          event.accepted = true
        }
      }

      Column {
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        spacing: Style.spacing.md

        Row {
          width: parent.width
          height: Style.space(42)
          spacing: Style.spacing.sm

          Column {
            width: parent.width - clearButton.width - refreshButton.width - parent.spacing * 2
            Text {
              text: "Keyboard shortcuts"
              color: root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.heading
              font.bold: true
            }
            Text {
              text: "Hold a physical modifier, or click one to lock and click again to unlock"
              color: root.foreground
              opacity: 0.58
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }
          }

          Rectangle {
            id: clearButton
            width: Style.space(64)
            height: Style.space(32)
            radius: root.cornerRadius
            color: clearMouse.containsMouse ? root.selectedBackground : "transparent"
            border.color: root.border
            border.width: 1
            Text {
              anchors.centerIn: parent
              text: "Clear"
              color: clearMouse.containsMouse ? root.selectedText : root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }
            MouseArea {
              id: clearMouse
              anchors.fill: parent
              acceptedButtons: Qt.AllButtons
              preventStealing: true
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onPressed: function(mouse) { mouse.accepted = true }
              onClicked: function(mouse) {
                mouse.accepted = true
                root.clearModifiers()
                keyCatcher.forceActiveFocus()
              }
            }
          }

          Rectangle {
            id: refreshButton
            width: Style.space(78)
            height: Style.space(32)
            radius: root.cornerRadius
            color: refreshMouse.containsMouse ? root.selectedBackground : "transparent"
            border.color: root.border
            border.width: 1
            Text {
              anchors.centerIn: parent
              text: bindingProcess.running ? "Loading…" : "Refresh"
              color: refreshMouse.containsMouse ? root.selectedText : root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }
            MouseArea {
              id: refreshMouse
              anchors.fill: parent
              acceptedButtons: Qt.AllButtons
              preventStealing: true
              enabled: !bindingProcess.running
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onPressed: function(mouse) { mouse.accepted = true }
              onClicked: function(mouse) {
                mouse.accepted = true
                root.reload()
              }
            }
          }
        }

        Item {
          width: parent.width
          height: root.unit * 6 + root.keyGap * 5

          Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.keyGap

            Repeater {
              model: KeyboardModel.rows
              delegate: Row {
                required property var modelData
                spacing: root.keyGap
                Repeater {
                  model: parent.modelData
                  delegate: Rectangle {
                    required property var modelData
                    readonly property var keyBindings: modelData.gap ? [] : root.matchesFor(modelData.id)
                    readonly property bool used: keyBindings.length > 0
                    readonly property bool activeModifier: modelData.modifier === true && root.modifierActive(modelData.id)
                    readonly property bool selected: modelData.modifier !== true && root.selectedKey === modelData.id
                    width: root.unit * modelData.width + root.keyGap * (modelData.width - 1)
                    height: root.unit
                    radius: Math.max(5, root.cornerRadius * 0.7)
                    visible: !modelData.gap
                    color: activeModifier || selected || used ? root.selectedBackground : "transparent"
                    border.color: used || activeModifier ? root.selectedBackground : root.border
                    border.width: used || activeModifier ? 2 : 1
                    opacity: modelData.gap ? 0 : 1

                    Text {
                      anchors.centerIn: parent
                      text: parent.modelData.label
                      color: parent.activeModifier || parent.selected || parent.used ? root.selectedText : root.foreground
                      font.family: Style.font.menuFamily
                      font.pixelSize: parent.modelData.label.length > 5 ? Style.font.small : Style.font.body
                    }

                    MouseArea {
                      anchors.fill: parent
                      acceptedButtons: Qt.AllButtons
                      preventStealing: true
                      enabled: !parent.modelData.gap
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onPressed: function(mouse) { mouse.accepted = true }
                      onClicked: function(mouse) {
                        mouse.accepted = true
                        if (parent.modelData.modifier) root.toggleModifier(parent.modelData.id)
                        else root.selectedKey = parent.modelData.id
                        keyCatcher.forceActiveFocus()
                      }
                    }
                  }
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: Style.space(72)
          radius: root.cornerRadius
          color: "transparent"
          border.color: root.border
          border.width: 1

          Column {
            anchors.fill: parent
            anchors.margins: Style.spacing.md
            spacing: Style.spacing.sm

            Text {
              width: parent.width
              color: root.loadError ? "#e06c75" : root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              font.bold: true
              text: {
                if (root.loadError) return root.loadError
                if (!root.selectedKey) return root.activeModifiers().length ? root.activeModifiers().join(" + ") : "No modifiers"
                var prefix = root.activeModifiers()
                return prefix.concat([root.selectedKey]).join(" + ")
              }
            }

            Text {
              width: parent.width
              color: root.foreground
              opacity: 0.7
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.Wrap
              text: {
                if (root.loadError) return "Check that Omarchy Shell and Hyprland are running, then refresh."
                if (!root.selectedKey) return "Select a key to inspect its shortcut. Highlighted keys are already in use."
                var matches = root.selectedBindings()
                if (!matches.length) return "Available — no configured shortcut uses this combination."
                var descriptions = []
                for (var i = 0; i < matches.length; i++) descriptions.push(matches[i].description)
                return descriptions.join("  •  ")
              }
            }
          }
        }
      }
    }
  }
}
