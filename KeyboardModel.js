.pragma library

var modifierOrder = ["SUPER", "SHIFT", "CTRL", "ALT"]

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
  for (var i = 0; i < bindings.length; i++) {
    var binding = bindings[i]
    if (binding.key === keyId && sameModifiers(binding.modifiers || [], modifiers)) found.push(binding)
  }
  return found
}
