.pragma library

// Layer 1: physical identity. See docs/input-layers.md.
// Keep tables in sync with scripts/key_identity.py.

var modifierOrder = ["SUPER", "SHIFT", "CTRL", "ALT"]

var scanCodeToKeyId = ({
  2: "1", 3: "2", 4: "3", 5: "4", 6: "5", 7: "6", 8: "7", 9: "8",
  10: "1", 11: "2", 12: "3", 13: "4", 14: "5",
  15: "6", 16: "7", 17: "8", 18: "9", 19: "0",
  20: "MINUS", 21: "EQUAL", 22: "BACKSPACE", 23: "TAB",
  34: "BRACKETLEFT", 35: "BRACKETRIGHT", 36: "RETURN",
  47: "SEMICOLON", 48: "APOSTROPHE", 49: "GRAVE",
  51: "BACKSLASH", 59: "COMMA", 60: "PERIOD", 61: "SLASH",
  65: "SPACE"
})

var scanCodeToModifier = ({
  29: "CTRL", 37: "CTRL", 97: "CTRL", 105: "CTRL",
  42: "SHIFT", 50: "SHIFT", 54: "SHIFT", 62: "SHIFT",
  56: "ALT", 64: "ALT", 100: "ALT", 108: "ALT",
  125: "SUPER", 133: "SUPER", 126: "SUPER", 134: "SUPER"
})

var textToKeyId = ({
  "!": "1", "@": "2", "#": "3", "$": "4", "%": "5",
  "^": "6", "&": "7", "*": "8", "(": "9", ")": "0",
  "\"": "2"
})

var qtKeyToKeyId = ({
  0x20: "SPACE",
  0x21: "1",
  0x23: "3",
  0x24: "4",
  0x25: "5",
  0x26: "7",
  0x27: "APOSTROPHE",
  0x28: "9",
  0x29: "0",
  0x2a: "8",
  0x2b: "EQUAL",
  0x2c: "COMMA",
  0x2d: "MINUS",
  0x2e: "PERIOD",
  0x2f: "SLASH",
  0x3a: "SEMICOLON",
  0x3b: "SEMICOLON",
  0x3c: "COMMA",
  0x3d: "EQUAL",
  0x3e: "PERIOD",
  0x3f: "SLASH",
  0x40: "2",
  0x5b: "BRACKETLEFT",
  0x5c: "BACKSLASH",
  0x5d: "BRACKETRIGHT",
  0x5e: "6",
  0x5f: "MINUS",
  0x60: "GRAVE",
  0x7b: "BRACKETLEFT",
  0x7c: "BACKSLASH",
  0x7d: "BRACKETRIGHT",
  0x7e: "GRAVE",
  0x01000000: "ESCAPE",
  0x01000001: "TAB",
  0x01000003: "BACKSPACE",
  0x01000004: "RETURN",
  0x01000005: "RETURN"
})

var rows = [
  [key("ESCAPE", "Esc"), gap(0.55), key("F1"), key("F2"), key("F3"), key("F4"), gap(0.3), key("F5"), key("F6"), key("F7"), key("F8"), gap(0.3), key("F9"), key("F10"), key("F11"), key("F12")],
  [key("GRAVE", "`"), key("1"), key("2"), key("3"), key("4"), key("5"), key("6"), key("7"), key("8"), key("9"), key("0"), key("MINUS", "-"), key("EQUAL", "="), key("BACKSPACE", "Backspace", 2)],
  [key("TAB", "Tab", 1.5), key("Q"), key("W"), key("E"), key("R"), key("T"), key("Y"), key("U"), key("I"), key("O"), key("P"), key("BRACKETLEFT", "["), key("BRACKETRIGHT", "]"), key("BACKSLASH", "\\", 1.5)],
  [key("CAPSLOCK", "Caps", 1.8), key("A"), key("S"), key("D"), key("F"), key("G"), key("H"), key("J"), key("K"), key("L"), key("SEMICOLON", ";"), key("APOSTROPHE", "'"), key("RETURN", "Enter", 2.2)],
  [modifier("SHIFT", "Shift", 2.3), key("Z"), key("X"), key("C"), key("V"), key("B"), key("N"), key("M"), key("COMMA", ","), key("PERIOD", "."), key("SLASH", "/"), modifier("SHIFT", "Shift", 2.7)],
  [modifier("CTRL", "Ctrl", 1.35), modifier("SUPER", "Super", 1.35), modifier("ALT", "Alt", 1.35), key("SPACE", "Space", 6.2), modifier("ALT", "Alt", 1.35), modifier("SUPER", "Super", 1.35), modifier("CTRL", "Ctrl", 1.35)]
]

function key(id, label, width) {
  return { id: id, label: label || id, width: width || 1, modifier: false, gap: false }
}

function modifier(id, label, width) {
  return { id: id, label: label, width: width || 1, modifier: true, gap: false }
}

function gap(width) {
  return { id: "", label: "", width: width, modifier: false, gap: true }
}

function emptyModifiers() {
  return ({ "SUPER": false, "SHIFT": false, "CTRL": false, "ALT": false })
}

function copyModifiers(source, overrideName, overrideValue) {
  var next = {}
  for (var i = 0; i < modifierOrder.length; i++) {
    var name = modifierOrder[i]
    next[name] = name === overrideName ? overrideValue : source[name] === true
  }
  return next
}

function activeModifierNames(pinned, held) {
  var active = []
  for (var i = 0; i < modifierOrder.length; i++) {
    var name = modifierOrder[i]
    if (pinned[name] === true || held[name] === true) active.push(name)
  }
  return active
}

function sameModifiers(left, right) {
  if (left.length !== right.length) return false
  for (var i = 0; i < modifierOrder.length; i++) {
    var modifierName = modifierOrder[i]
    if ((left.indexOf(modifierName) !== -1) !== (right.indexOf(modifierName) !== -1)) return false
  }
  return true
}

function bindingsFor(bindings, keyId, modifiers) {
  var found = []
  var wanted = String(keyId)
  for (var i = 0; i < bindings.length; i++) {
    var binding = bindings[i]
    if (String(binding.key) === wanted && sameModifiers(binding.modifiers || [], modifiers)) found.push(binding)
  }
  return found
}

function modifierFromScanCode(scanCode) {
  return scanCodeToModifier[scanCode] || ""
}

function modifierFromQtKey(key) {
  if (key === 0x01000022 || key === 0x01000053 || key === 0x01000054)
    return "SUPER"
  if (key === 0x01000020)
    return "SHIFT"
  if (key === 0x01000021)
    return "CTRL"
  if (key === 0x01000023 || key === 0x01001103)
    return "ALT"
  return ""
}

function isCapsLockKey(key) {
  return key === 0x01000024
}

function keyIdFromScanCode(scanCode) {
  return scanCodeToKeyId[scanCode] || ""
}

function keyIdFromText(text) {
  if (!text) return ""
  if (text >= "0" && text <= "9") return text
  return textToKeyId[text] || ""
}

function keyIdFromQtKey(key) {
  if (key >= 0x41 && key <= 0x5a)
    return String.fromCharCode(key)
  if (key >= 0x30 && key <= 0x39)
    return String.fromCharCode(key)
  if (key >= 0x01000030 && key <= 0x0100003b)
    return "F" + String(key - 0x01000030 + 1)
  return qtKeyToKeyId[key] || ""
}

function luaString(value) {
  var text = String(value == null ? "" : value)
  return "\"" + text.replace(/\\/g, "\\\\").replace(/\"/g, "\\\"").replace(/\r/g, "\\r").replace(/\n/g, "\\n").replace(/\t/g, "\\t") + "\""
}

function bindPreview(shortcut, description, command) {
  return "o.bind(" + luaString(shortcut) + ", " + luaString(description) + ", " + luaString(command) + ")"
}

function originLabel(origin) {
  if (origin === "plugin") return "Added here"
  if (origin === "user") return "User override"
  if (origin === "omarchy") return "Omarchy default"
  return ""
}

function normalizePresets(value) {
  var source = []
  if (Array.isArray(value)) source = value
  else if (value && Array.isArray(value.presets)) source = value.presets
  var seen = {}
  var out = []
  for (var i = 0; i < source.length; i++) {
    var row = source[i] || {}
    var id = String(row.id || "").trim()
    var label = String(row.label || row.description || "").trim()
    var description = String(row.description || row.label || "").trim()
    var command = String(row.command || "").trim()
    if (!id || !label || !description || !command || seen[id]) continue
    seen[id] = true
    out.push({ id: id, label: label, description: description, command: command })
  }
  return out
}

function pickPresets(shipped, user) {
  if (user && Array.isArray(user.presets)) return normalizePresets(user.presets)
  return normalizePresets(shipped)
}

function matchingPreset(presets, command) {
  var cmd = String(command || "").trim()
  if (!cmd || !presets) return null
  for (var i = 0; i < presets.length; i++) {
    if (presets[i].command === cmd) return presets[i]
  }
  return null
}

function hasUserOrigin(matches) {
  for (var i = 0; i < matches.length; i++) {
    if (matches[i].origin === "user" || matches[i].origin === "plugin") return true
  }
  return false
}
