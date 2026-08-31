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
  property bool editorOpen: false
  property string editorDescription: ""
  property string editorCommand: ""
  property string saveError: ""
  property string saveNotice: ""

  property var pinnedModifiers: ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
  property var heldModifiers: ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
  property var selectedModifiers: []

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
    unit * 6 + keyGap * 5 + Style.space(190)
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
    selectedModifiers = []
    selectedKey = ""
  }

  function toggleModifier(name) {
    var next = {}
    for (var i = 0; i < KeyboardModel.modifierOrder.length; i++) {
      var modifierName = KeyboardModel.modifierOrder[i]
      next[modifierName] = modifierName === name ? !pinnedModifiers[modifierName] : pinnedModifiers[modifierName]
    }
    pinnedModifiers = next
    selectedModifiers = []
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
    // Keep selectedKey. Releasing Super after Super+B would otherwise
    // wipe the detail panel before the user can read it.
  }

  function modifierNameFromScanCode(scanCode) {
    // Qt Wayland often reports X11 keycodes (evdev + 8). Accept both.
    var names = ({
      29: "CTRL", 37: "CTRL", 97: "CTRL", 105: "CTRL",
      42: "SHIFT", 50: "SHIFT", 54: "SHIFT", 62: "SHIFT",
      56: "ALT", 64: "ALT", 100: "ALT", 108: "ALT",
      125: "SUPER", 133: "SUPER", 126: "SUPER", 134: "SUPER"
    })
    return names[scanCode] || ""
  }

  function modifierNameFromKey(key) {
    if (key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R)
      return "SUPER"
    if (key === Qt.Key_Shift)
      return "SHIFT"
    if (key === Qt.Key_Control)
      return "CTRL"
    if (key === Qt.Key_Alt || key === Qt.Key_AltGr)
      return "ALT"
    return ""
  }

  function modifierNameFromEvent(event) {
    return modifierNameFromScanCode(event.nativeScanCode) || modifierNameFromKey(event.key)
  }

  function updatePhysicalModifier(event, pressed) {
    var name = modifierNameFromEvent(event)
    if (name) {
      setHeldModifier(name, pressed)
      return
    }
    if (!pressed && heldModifiers.SHIFT === true && event.key === Qt.Key_CapsLock)
      // Some XKB keymaps report a Shift release as CapsLock. Only apply this
      // compatibility path while Shift is known to be held.
      setHeldModifier("SHIFT", false)
  }

  function keyIdFromEvent(event) {
    if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z)
      return String.fromCharCode(event.key)
    if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9)
      return String.fromCharCode(event.key)

    var specialKeys = ({})
    specialKeys[Qt.Key_Space] = "SPACE"
    specialKeys[Qt.Key_Return] = "RETURN"
    specialKeys[Qt.Key_Enter] = "RETURN"
    specialKeys[Qt.Key_Tab] = "TAB"
    specialKeys[Qt.Key_Backspace] = "BACKSPACE"
    specialKeys[Qt.Key_QuoteLeft] = "GRAVE"
    specialKeys[Qt.Key_Minus] = "MINUS"
    specialKeys[Qt.Key_Equal] = "EQUAL"
    specialKeys[Qt.Key_BracketLeft] = "BRACKETLEFT"
    specialKeys[Qt.Key_BracketRight] = "BRACKETRIGHT"
    specialKeys[Qt.Key_Backslash] = "BACKSLASH"
    specialKeys[Qt.Key_Semicolon] = "SEMICOLON"
    specialKeys[Qt.Key_Apostrophe] = "APOSTROPHE"
    specialKeys[Qt.Key_Comma] = "COMMA"
    specialKeys[Qt.Key_Period] = "PERIOD"
    specialKeys[Qt.Key_Slash] = "SLASH"
    if (event.key >= Qt.Key_F1 && event.key <= Qt.Key_F12)
      return "F" + String(event.key - Qt.Key_F1 + 1)
    return specialKeys[event.key] || ""
  }

  function matchesFor(keyId) {
    return KeyboardModel.bindingsFor(bindings, keyId, activeModifiers())
  }

  function selectedBindings() {
    return selectedKey ? KeyboardModel.bindingsFor(bindings, selectedKey, selectedModifiers) : []
  }

  function selectedShortcut() {
    return selectedModifiers.concat([selectedKey]).join(" + ")
  }

  function beginEditor() {
    if (!selectedKey || selectedBindings().length) return
    editorDescription = ""
    editorCommand = ""
    saveError = ""
    editorOpen = true
    Qt.callLater(function() { descriptionInput.forceActiveFocus() })
  }

  function activateKey(keyData) {
    if (keyData.modifier === true) {
      toggleModifier(keyData.id)
      keyCatcher.forceActiveFocus()
      return
    }

    // Snapshot the chord for the editor and detail panel. Do not pin
    // physical holds into click-locks, or those keys stay highlighted
    // after the editor closes and the real keys have been released.
    selectedModifiers = activeModifiers()
    selectedKey = keyData.id
    if (selectedBindings().length === 0) beginEditor()
    else keyCatcher.forceActiveFocus()
  }

  function closeEditor() {
    editorOpen = false
    saveError = ""
    selectedModifiers = []
    selectedKey = ""
    heldModifiers = ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function saveBinding() {
    if (!editorDescription.trim() || !editorCommand.trim() || saveProcess.running) return
    var args = [pluginPath("scripts/add-binding")]
    var modifiers = selectedModifiers
    for (var i = 0; i < modifiers.length; i++) args.push("--modifier", modifiers[i])
    args.push("--key", selectedKey)
    args.push("--description", editorDescription.trim())
    args.push("--command", editorCommand.trim())
    saveError = ""
    saveProcess.command = args
    saveProcess.running = true
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
    editorOpen = false
    saveNotice = ""
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

  Process {
    id: saveProcess
    stdout: StdioCollector { id: saveOutput; waitForEnd: true }
    stderr: StdioCollector { id: saveErrorOutput; waitForEnd: true }
    onExited: function(exitCode) {
      var result = ({})
      try { result = JSON.parse(String(saveOutput.text || "{}")) } catch (error) {}
      if (exitCode === 0 && result.ok) {
        root.editorOpen = false
        root.selectedModifiers = []
        root.selectedKey = ""
        root.heldModifiers = ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
        root.saveNotice = "Saved " + result.shortcut
        root.reload()
        Qt.callLater(function() { keyCatcher.forceActiveFocus() })
      } else {
        root.saveError = result.error || String(saveErrorOutput.text || "Unable to save the shortcut.").trim()
      }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "visual-keybindings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    ShortcutInhibitor {
      window: panel
      enabled: panel.visible
    }

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
        focus: !root.editorOpen
        enabled: !root.editorOpen
        onActiveFocusChanged: if (!activeFocus)
          root.heldModifiers = ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            root.dismiss()
            event.accepted = true
            return
          }
          var keyId = root.keyIdFromEvent(event)
          if (!keyId) root.updatePhysicalModifier(event, true)
          if (keyId && !event.isAutoRepeat) root.activateKey({ id: keyId, modifier: false })
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
              text: "Visual Keybindings"
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
                    id: keyCap
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
                      font.pixelSize: Style.font.body
                    }

                    TapHandler {
                      enabled: !keyCap.modelData.gap
                      acceptedButtons: Qt.LeftButton
                      onTapped: root.activateKey(keyCap.modelData)
                    }
                    HoverHandler {
                      enabled: !keyCap.modelData.gap
                      cursorShape: Qt.PointingHandCursor
                    }
                  }
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: Style.space(110)
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
                if (root.saveNotice) return root.saveNotice
                if (!root.selectedKey) return root.activeModifiers().length ? root.activeModifiers().join(" + ") : "No modifiers"
                return root.selectedShortcut()
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
                if (root.saveNotice) return "The shortcut is active and the keyboard has been refreshed."
                if (!root.selectedKey) return "Select a key to inspect its shortcut. Highlighted keys are already in use."
                var matches = root.selectedBindings()
                if (!matches.length) return "Available — no configured shortcut uses this combination."
                var descriptions = []
                for (var i = 0; i < matches.length; i++) descriptions.push(matches[i].description)
                return descriptions.join("  •  ")
              }
            }

            Rectangle {
              visible: root.selectedKey !== "" && root.selectedBindings().length === 0
              width: Style.space(128)
              height: Style.space(30)
              radius: root.cornerRadius
              color: createMouse.containsMouse ? root.selectedBackground : "transparent"
              border.color: root.selectedBackground
              border.width: 1
              Text {
                anchors.centerIn: parent
                text: "Create shortcut"
                color: createMouse.containsMouse ? root.selectedText : root.foreground
                font.family: Style.font.menuFamily
                font.pixelSize: Style.font.body
              }
              MouseArea {
                id: createMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.beginEditor()
              }
            }
          }
        }
      }

      Rectangle {
        id: editor
        anchors.fill: parent
        anchors.margins: Style.spacing.panelPadding
        z: 20
        visible: root.editorOpen
        radius: root.cornerRadius
        color: root.background
        border.color: root.border
        border.width: 1

        MouseArea { anchors.fill: parent; onPressed: function(mouse) { mouse.accepted = true } }

        Shortcut {
          sequence: "Escape"
          enabled: root.editorOpen
          onActivated: root.closeEditor()
        }

        Column {
          anchors.fill: parent
          anchors.margins: Style.spacing.panelPadding
          spacing: Style.spacing.md

          Text {
            text: "Create " + root.selectedShortcut()
            color: root.foreground
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.heading
            font.bold: true
          }
          Text {
            text: "Description"
            color: root.foreground
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
          }
          Rectangle {
            width: parent.width
            height: Style.space(42)
            radius: root.cornerRadius
            color: "transparent"
            border.color: descriptionInput.activeFocus ? root.selectedBackground : root.border
            border.width: 1
            TextInput {
              id: descriptionInput
              anchors.fill: parent
              anchors.margins: Style.spacing.sm
              color: root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              text: root.editorDescription
              onTextChanged: root.editorDescription = text
              KeyNavigation.tab: commandInput
              Keys.onEscapePressed: function(event) {
                root.closeEditor()
                event.accepted = true
              }
            }
          }
          Text {
            text: "Command"
            color: root.foreground
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
          }
          Rectangle {
            width: parent.width
            height: Style.space(42)
            radius: root.cornerRadius
            color: "transparent"
            border.color: commandInput.activeFocus ? root.selectedBackground : root.border
            border.width: 1
            TextInput {
              id: commandInput
              anchors.fill: parent
              anchors.margins: Style.spacing.sm
              color: root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              text: root.editorCommand
              onTextChanged: root.editorCommand = text
              KeyNavigation.tab: descriptionInput
              Keys.onEscapePressed: function(event) {
                root.closeEditor()
                event.accepted = true
              }
            }
          }
          Text {
            text: "Preview"
            color: root.foreground
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
          }
          Rectangle {
            width: parent.width
            height: Style.space(64)
            radius: root.cornerRadius
            color: "transparent"
            border.color: root.border
            border.width: 1
            Text {
              anchors.fill: parent
              anchors.margins: Style.spacing.sm
              color: root.foreground
              opacity: 0.75
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WrapAnywhere
              text: "o.bind(\"" + root.selectedShortcut() + "\", \"" + root.editorDescription + "\", \"" + root.editorCommand + "\")"
            }
          }
          Text {
            width: parent.width
            visible: root.saveError !== ""
            text: root.saveError
            color: "#e06c75"
            wrapMode: Text.Wrap
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
          }
          Item { width: 1; height: Style.spacing.sm }
          Row {
            spacing: Style.spacing.md
            Rectangle {
              width: Style.space(90); height: Style.space(36); radius: root.cornerRadius
              color: cancelMouse.containsMouse ? root.selectedBackground : "transparent"
              border.color: root.border; border.width: 1
              Text { anchors.centerIn: parent; text: "Cancel"; color: cancelMouse.containsMouse ? root.selectedText : root.foreground; font.family: Style.font.menuFamily }
              MouseArea { id: cancelMouse; anchors.fill: parent; hoverEnabled: root.editorOpen; cursorShape: Qt.PointingHandCursor; onClicked: root.closeEditor() }
            }
            Rectangle {
              width: Style.space(110); height: Style.space(36); radius: root.cornerRadius
              opacity: root.editorDescription.trim() && root.editorCommand.trim() ? 1 : 0.45
              color: saveMouse.containsMouse ? root.selectedBackground : "transparent"
              border.color: root.selectedBackground; border.width: 1
              Text { anchors.centerIn: parent; text: saveProcess.running ? "Saving…" : "Save"; color: saveMouse.containsMouse ? root.selectedText : root.foreground; font.family: Style.font.menuFamily }
              MouseArea { id: saveMouse; anchors.fill: parent; enabled: root.editorOpen && root.editorDescription.trim() !== "" && root.editorCommand.trim() !== "" && !saveProcess.running; hoverEnabled: root.editorOpen; cursorShape: Qt.PointingHandCursor; onClicked: root.saveBinding() }
            }
          }
        }
      }
    }
  }
}
