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
  property string editorMode: "create"
  property string editorDescription: ""
  property string editorCommand: ""
  property string saveError: ""
  property string saveNotice: ""
  property bool descriptionLocked: false
  property string generatedDescription: ""
  property bool removeConfirm: false
  property bool rainbowForced: false
  property bool rainbowBurst: false
  readonly property bool rainbowPlay: rainbowForced || rainbowBurst
  property real rainbowHue: 0

  property var pinnedModifiers: KeyboardModel.emptyModifiers()
  property var heldModifiers: KeyboardModel.emptyModifiers()
  property var selectedModifiers: []

  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property color scrim: Color.menu.scrim
  property color selectedBackground: Color.menu.selectedBackground
  property color selectedText: Color.menu.selectedText
  readonly property var menuBorderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  property var borderSpec: rainbowPlay ? rainbowFrameSpec(rainbowHue) : menuBorderSpec
  readonly property int cornerRadius: Style.cornerRadius
  readonly property int unit: Math.max(38, Math.min(58, Math.floor((panel.width - Style.space(100)) / 15.5)))
  readonly property int keyGap: Math.max(3, Style.space(4))
  readonly property int headerHeight: Style.space(42)
  readonly property int keyboardHeight: unit * 6 + keyGap * 5
  readonly property int actionHeight: Style.space(30)
  readonly property int detailHeight: 1 + Style.spacing.sm * 3 + Style.space(22) + Style.space(44) + actionHeight
  readonly property int cardWidth: Math.min(panel.width - Style.gapsOut * 2, unit * 15.5 + Style.space(56))
  readonly property int cardHeight: Math.min(
    panel.height - Style.gapsOut * 2,
    headerHeight + keyboardHeight + detailHeight + Style.spacing.md * 2 + Style.spacing.panelPadding * 2
  )

  function pluginPath(name) {
    var directory = manifest && manifest.__sourceDir ? String(manifest.__sourceDir) : ""
    return directory.replace(/\/$/, "") + "/" + name
  }

  function activeModifiers() {
    return KeyboardModel.activeModifierNames(pinnedModifiers, heldModifiers)
  }

  function modifierActive(name) {
    return pinnedModifiers[name] === true || heldModifiers[name] === true
  }

  function clearModifiers() {
    pinnedModifiers = KeyboardModel.emptyModifiers()
    heldModifiers = KeyboardModel.emptyModifiers()
    selectedModifiers = []
    selectedKey = ""
    removeConfirm = false
  }

  function resetView() {
    clearModifiers()
    saveNotice = ""
    reload()
  }

  function toggleModifier(name) {
    pinnedModifiers = KeyboardModel.copyModifiers(pinnedModifiers, name, !pinnedModifiers[name])
    selectedModifiers = []
    selectedKey = ""
    removeConfirm = false
  }

  function setHeldModifier(name, value) {
    if (heldModifiers[name] === value) return
    heldModifiers = KeyboardModel.copyModifiers(heldModifiers, name, value)
  }

  function modifierNameFromEvent(event) {
    return KeyboardModel.modifierFromScanCode(event.nativeScanCode) || KeyboardModel.modifierFromQtKey(event.key)
  }

  function updatePhysicalModifier(event, pressed) {
    var name = modifierNameFromEvent(event)
    if (name) {
      setHeldModifier(name, pressed)
      return
    }
    if (!pressed && heldModifiers.SHIFT === true && KeyboardModel.isCapsLockKey(event.key))
      setHeldModifier("SHIFT", false)
  }

  function keyIdFromEvent(event) {
    return KeyboardModel.keyIdFromScanCode(event.nativeScanCode)
      || KeyboardModel.keyIdFromQtKey(event.key)
      || KeyboardModel.keyIdFromText(event.text)
  }

  function matchesFor(keyId) {
    return KeyboardModel.bindingsFor(bindings, keyId, activeModifiers())
  }

  function selectedBindings() {
    return selectedKey ? KeyboardModel.bindingsFor(bindings, selectedKey, selectedModifiers) : []
  }

  function selectedIsDisabled() {
    return KeyboardModel.disabledOnly(selectedBindings())
  }

  function toggleRainbow() {
    if (rainbowPlay) {
      rainbowForced = false
      rainbowBurst = false
      rainbowBurstTimer.stop()
      return
    }
    rainbowForced = true
  }

  function startRainbowSurprise() {
    rainbowForced = false
    rainbowBurst = Math.random() < 0.1
    if (rainbowBurst) rainbowBurstTimer.restart()
    else rainbowBurstTimer.stop()
  }

  function rainbowColor(offset) {
    var hue = ((rainbowHue + offset) % 360) / 360
    if (hue < 0) hue += 1
    return Qt.hsla(hue, 0.78, 0.58, 1)
  }

  function rainbowFrameSpec(hue) {
    var colors = []
    for (var i = 0; i < 6; i++) colors.push(rainbowColor(i * 60))
    colors.push(colors[0])
    return {
      color: colors[0],
      widths: menuBorderSpec.widths,
      gradient: { colors: colors, angle: hue, enabled: true }
    }
  }

  function canCreateShortcut() {
    if (!selectedKey || removeConfirm) return false
    return selectedBindings().length === 0 || selectedIsDisabled()
  }

  function selectedShortcut() {
    return selectedModifiers.concat([selectedKey]).join(" + ")
  }

  function beginEditor(mode) {
    var matches = selectedBindings()
    if (!selectedKey) return
    if (mode === "edit") {
      if (!matches.length) return
      editorMode = "edit"
      editorDescription = matches[0].description || ""
      editorCommand = matches[0].command || ""
    } else {
      if (matches.length && !KeyboardModel.disabledOnly(matches)) return
      editorMode = "create"
      editorDescription = ""
      editorCommand = ""
    }
    generatedDescription = KeyboardModel.descriptionFromCommand(editorCommand)
    descriptionLocked = editorDescription.trim() !== "" && editorDescription !== generatedDescription
    saveError = ""
    removeConfirm = false
    editorOpen = true
    Qt.callLater(function() { commandInput.forceActiveFocus() })
  }

  function fillDescriptionFromCommand() {
    var next = KeyboardModel.descriptionFromCommand(editorCommand)
    generatedDescription = next
    if (descriptionLocked) return
    if (editorDescription === next) return
    editorDescription = next
    descriptionInput.text = next
  }

  function noteDescriptionEdited() {
    descriptionLocked = editorDescription.trim() !== "" && editorDescription !== generatedDescription
    if (!descriptionLocked && editorDescription !== generatedDescription)
      fillDescriptionFromCommand()
  }

  function activateKey(keyData, fromKeyboard) {
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
    removeConfirm = false
    if (fromKeyboard && selectedBindings().length === 0) beginEditor("create")
    else keyCatcher.forceActiveFocus()
  }

  function restoreBinding() {
    if (!selectedIsDisabled() || saveProcess.running) return
    var args = bindingArgs()
    args.push("--restore")
    saveError = ""
    saveNotice = ""
    saveProcess.command = args
    saveProcess.running = true
  }

  function closeEditor() {
    editorOpen = false
    saveError = ""
    descriptionLocked = false
    generatedDescription = ""
    selectedModifiers = []
    selectedKey = ""
    heldModifiers = KeyboardModel.emptyModifiers()
    removeConfirm = false
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function bindingArgs() {
    var args = [pluginPath("scripts/add-binding")]
    var modifiers = selectedModifiers
    for (var i = 0; i < modifiers.length; i++) args.push("--modifier", modifiers[i])
    args.push("--key", selectedKey)
    return args
  }

  function saveBinding() {
    if (!editorDescription.trim() || !editorCommand.trim() || saveProcess.running) return
    var args = bindingArgs()
    if (editorMode === "edit") {
      args.push("--replace")
      var matches = selectedBindings()
      if (matches.length) args.push("--previous", matches[0].description || "")
    }
    args.push("--description", editorDescription.trim())
    args.push("--command", editorCommand.trim())
    saveError = ""
    saveProcess.command = args
    saveProcess.running = true
  }

  function removeBinding() {
    if (!removeConfirm || !selectedKey || !selectedBindings().length || saveProcess.running) return
    var args = bindingArgs()
    args.push("--remove")
    args.push("--previous", selectedBindings()[0].description || "")
    saveError = ""
    saveNotice = ""
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

  function setCompositorSubmap(name) {
    submapProcess.running = false
    submapProcess.command = [pluginPath("scripts/set-submap"), name]
    submapProcess.running = true
  }

  function open(payloadJson) {
    clearModifiers()
    editorOpen = false
    saveNotice = ""
    opened = true
    startRainbowSurprise()
    setCompositorSubmap("pause")
    reload()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }

  function close() {
    setCompositorSubmap("reset")
    clearModifiers()
    opened = false
  }

  function dismiss() {
    setCompositorSubmap("reset")
    clearModifiers()
    opened = false
    if (shell && typeof shell.hide === "function") shell.hide(manifest.id)
  }

  function toggle() {
    if (opened) dismiss()
    else open("{}")
  }

  NumberAnimation {
    id: rainbowSpin
    target: root
    property: "rainbowHue"
    from: 0
    to: 360
    duration: 9000
    loops: Animation.Infinite
    running: root.opened && root.rainbowPlay
  }

  Timer {
    id: rainbowBurstTimer
    interval: 6000
    repeat: false
    onTriggered: root.rainbowBurst = false
  }

  Process {
    id: submapProcess
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
        root.heldModifiers = KeyboardModel.emptyModifiers()
        root.removeConfirm = false
        var prefix = "Saved "
        if (result.action === "replaced") prefix = "Updated "
        if (result.action === "removed") prefix = "Removed "
        if (result.action === "restored") prefix = "Restored "
        root.saveNotice = prefix + result.shortcut
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
    onVisibleChanged: root.setCompositorSubmap(visible ? "pause" : "reset")

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
          root.heldModifiers = KeyboardModel.emptyModifiers()

        Keys.priority: Keys.BeforeItem
        Keys.onPressed: function(event) {
          if (event.key === Qt.Key_Escape) {
            if (root.removeConfirm) root.removeConfirm = false
            else root.dismiss()
            event.accepted = true
            return
          }
          var keyId = root.keyIdFromEvent(event)
          if (!keyId) root.updatePhysicalModifier(event, true)
          if (keyId && !event.isAutoRepeat) root.activateKey({ id: keyId, modifier: false }, true)
          event.accepted = true
        }
        Keys.onReleased: function(event) {
          root.updatePhysicalModifier(event, false)
          event.accepted = true
        }
      }

      Column {
        id: cardBody
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
            width: parent.width - clearButton.width - parent.spacing
            Text {
              text: "Visual Keybindings"
              color: root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.heading
              font.bold: true
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleRainbow()
              }
            }
            Text {
              text: root.rainbowForced ? "Hold or click a modifier to lock it · rainbow on" : "Hold or click a modifier to lock it"
              color: root.foreground
              opacity: 0.58
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }
          }

          Rectangle {
            id: clearButton
            width: Style.space(78)
            height: Style.space(32)
            radius: root.cornerRadius
            color: clearMouse.containsMouse ? root.selectedBackground : "transparent"
            border.color: root.border
            border.width: 1
            Text {
              anchors.centerIn: parent
              text: bindingProcess.running ? "Loading…" : "Clear"
              color: clearMouse.containsMouse ? root.selectedText : root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
            }
            MouseArea {
              id: clearMouse
              anchors.fill: parent
              acceptedButtons: Qt.AllButtons
              preventStealing: true
              enabled: !bindingProcess.running
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onPressed: function(mouse) { mouse.accepted = true }
              onClicked: function(mouse) {
                mouse.accepted = true
                root.resetView()
                keyCatcher.forceActiveFocus()
              }
            }
          }
        }

        Item {
          width: parent.width
          height: root.keyboardHeight

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
                    readonly property bool used: {
                      for (var i = 0; i < keyBindings.length; i++) {
                        if (keyBindings[i].origin !== "disabled") return true
                      }
                      return false
                    }
                    readonly property bool disabled: !used && KeyboardModel.disabledOnly(keyBindings)
                    readonly property bool activeModifier: modelData.modifier === true && root.modifierActive(modelData.id)
                    readonly property bool selected: modelData.modifier !== true && root.selectedKey === modelData.id
                    width: root.unit * modelData.width + root.keyGap * (modelData.width - 1)
                    height: root.unit
                    radius: Math.max(5, root.cornerRadius * 0.7)
                    visible: !modelData.gap
                    color: {
                      if (activeModifier) return Util.alpha(root.selectedBackground, 0.2)
                      if (selected || used) return root.selectedBackground
                      if (keyHover.hovered) return Util.alpha(root.selectedBackground, 0.12)
                      return "transparent"
                    }
                    border.color: used || disabled || activeModifier || selected ? root.selectedBackground : root.border
                    border.width: used || disabled || activeModifier || selected ? 2 : 1
                    opacity: modelData.gap ? 0 : 1

                    Text {
                      anchors.centerIn: parent
                      text: parent.modelData.label
                      color: parent.selected || parent.used ? root.selectedText : root.foreground
                      font.family: Style.font.menuFamily
                      font.pixelSize: Style.font.body
                    }

                    TapHandler {
                      enabled: !keyCap.modelData.gap
                      acceptedButtons: Qt.LeftButton
                      onTapped: root.activateKey(keyCap.modelData)
                    }
                    HoverHandler {
                      id: keyHover
                      enabled: !keyCap.modelData.gap
                      cursorShape: Qt.PointingHandCursor
                    }
                  }
                }
              }
            }
          }
        }

        Column {
          width: parent.width
          height: root.detailHeight
          spacing: Style.spacing.sm

          Rectangle {
            width: parent.width
            height: 1
            color: root.border
            opacity: 0.7
          }

          Text {
            width: parent.width
            height: Style.space(22)
            verticalAlignment: Text.AlignVCenter
            color: root.loadError ? Color.urgent : root.foreground
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
            font.bold: true
            elide: Text.ElideRight
            text: {
              if (root.loadError) return root.loadError
              if (root.saveNotice) return root.saveNotice
              if (!root.selectedKey) return root.activeModifiers().length ? root.activeModifiers().join(" + ") : "No modifiers"
              return root.selectedShortcut()
            }
          }

          Text {
            width: parent.width
            height: Style.space(44)
            color: root.foreground
            opacity: 0.7
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: {
              if (root.loadError) return "Check that Omarchy Shell and Hyprland are running, then use Clear."
              if (root.saveNotice) return "The shortcut is active and the keyboard has been refreshed."
              if (root.saveError) return root.saveError
              if (root.removeConfirm) return "Remove " + root.selectedShortcut() + "?"
              if (!root.selectedKey) return "Filled keys are in use. A thick empty outline is an unbound Omarchy default."
              var matches = root.selectedBindings()
              if (!matches.length) return "Available — no configured shortcut uses this combination."
              if (root.selectedIsDisabled()) {
                var was = matches[0].description ? " — was " + matches[0].description : ""
                return "Disabled default" + was + "."
              }
              var descriptions = []
              for (var i = 0; i < matches.length; i++) {
                var label = KeyboardModel.originLabel(matches[i].origin)
                var line = matches[i].description || "Configured shortcut"
                if (label) line = label + " — " + line
                if (matches[i].command) line += " · " + matches[i].command
                descriptions.push(line)
              }
              return descriptions.join("  •  ")
            }
          }

          Row {
            spacing: Style.spacing.sm
            width: parent.width
            height: root.actionHeight
              Rectangle {
                visible: (!root.selectedKey || root.selectedBindings().length === 0 || root.selectedIsDisabled()) && !root.removeConfirm
                width: Style.space(128)
                height: Style.space(30)
                radius: root.cornerRadius
                opacity: root.canCreateShortcut() ? 1 : 0.4
                color: root.canCreateShortcut() && createMouse.containsMouse ? root.selectedBackground : "transparent"
                border.color: root.canCreateShortcut() ? root.selectedBackground : root.border
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: "Create shortcut"
                  color: root.canCreateShortcut() && createMouse.containsMouse ? root.selectedText : root.foreground
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.body
                }
                MouseArea {
                  id: createMouse
                  anchors.fill: parent
                  enabled: root.canCreateShortcut()
                  hoverEnabled: root.canCreateShortcut()
                  cursorShape: root.canCreateShortcut() ? Qt.PointingHandCursor : Qt.ArrowCursor
                  onClicked: root.beginEditor("create")
                }
              }
              Rectangle {
                visible: root.selectedIsDisabled() && !root.removeConfirm
                width: Style.space(88)
                height: Style.space(30)
                radius: root.cornerRadius
                color: restoreMouse.containsMouse ? root.selectedBackground : "transparent"
                border.color: root.selectedBackground
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: saveProcess.running ? "Restoring…" : "Restore"
                  color: restoreMouse.containsMouse ? root.selectedText : root.foreground
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.body
                }
                MouseArea {
                  id: restoreMouse
                  anchors.fill: parent
                  enabled: !saveProcess.running
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.restoreBinding()
                }
              }
              Rectangle {
                visible: root.selectedBindings().length > 0 && !root.selectedIsDisabled() && !root.removeConfirm
                width: Style.space(72)
                height: Style.space(30)
                radius: root.cornerRadius
                color: editMouse.containsMouse ? root.selectedBackground : "transparent"
                border.color: root.selectedBackground
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: "Edit"
                  color: editMouse.containsMouse ? root.selectedText : root.foreground
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.body
                }
                MouseArea {
                  id: editMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.beginEditor("edit")
                }
              }
              Rectangle {
                visible: root.removeConfirm
                width: Style.space(88)
                height: Style.space(30)
                radius: root.cornerRadius
                color: cancelRemoveMouse.containsMouse ? root.selectedBackground : "transparent"
                border.color: root.border
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: "Cancel"
                  color: cancelRemoveMouse.containsMouse ? root.selectedText : root.foreground
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.body
                }
                MouseArea {
                  id: cancelRemoveMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.removeConfirm = false
                }
              }
              Rectangle {
                visible: root.selectedBindings().length > 0 && !root.selectedIsDisabled()
                width: root.removeConfirm ? Style.space(110) : Style.space(88)
                height: Style.space(30)
                radius: root.cornerRadius
                color: removeMouse.containsMouse ? root.selectedBackground : "transparent"
                border.color: root.removeConfirm ? root.selectedBackground : root.border
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: saveProcess.running && root.removeConfirm ? "Removing…" : (root.removeConfirm ? "Confirm" : "Remove")
                  color: removeMouse.containsMouse ? root.selectedText : root.foreground
                  font.family: Style.font.menuFamily
                  font.pixelSize: Style.font.body
                }
                MouseArea {
                  id: removeMouse
                  anchors.fill: parent
                  enabled: !saveProcess.running
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root.removeConfirm) root.removeBinding()
                    else root.removeConfirm = true
                  }
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
            text: (root.editorMode === "edit" ? "Edit " : "Create ") + root.selectedShortcut()
            color: root.foreground
            font.family: Style.font.menuFamily
            font.pixelSize: Style.font.heading
            font.bold: true
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
            Text {
              anchors.fill: parent
              anchors.margins: Style.spacing.sm
              visible: commandInput.text.length === 0
              text: "omarchy-launch-terminal"
              color: root.foreground
              opacity: 0.35
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
            }
            TextInput {
              id: commandInput
              anchors.fill: parent
              anchors.margins: Style.spacing.sm
              verticalAlignment: TextInput.AlignVCenter
              clip: true
              color: root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              text: root.editorCommand
              onTextChanged: {
                root.editorCommand = text
                root.fillDescriptionFromCommand()
              }
              KeyNavigation.tab: descriptionInput
              Keys.onEscapePressed: function(event) {
                root.closeEditor()
                event.accepted = true
              }
            }
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
            Text {
              anchors.fill: parent
              anchors.margins: Style.spacing.sm
              visible: descriptionInput.text.length === 0
              text: "Filled from the command"
              color: root.foreground
              opacity: 0.35
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              verticalAlignment: Text.AlignVCenter
              elide: Text.ElideRight
            }
            TextInput {
              id: descriptionInput
              anchors.fill: parent
              anchors.margins: Style.spacing.sm
              verticalAlignment: TextInput.AlignVCenter
              clip: true
              color: root.foreground
              font.family: Style.font.menuFamily
              font.pixelSize: Style.font.body
              text: root.editorDescription
              onTextChanged: {
                root.editorDescription = text
                root.noteDescriptionEdited()
              }
              KeyNavigation.tab: commandInput
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
              text: KeyboardModel.bindPreview(root.selectedShortcut(), root.editorDescription, root.editorCommand)
            }
          }
          Text {
            width: parent.width
            visible: root.saveError !== ""
            text: root.saveError
            color: Color.urgent
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
