"""Physical-key identity shared by the binding parser and tests.

Keep the tables in KeyboardModel.js in sync. Tests fail if the QML copy
drifts from this module.
"""

from __future__ import annotations

import re

MODIFIER_ORDER = ("SUPER", "SHIFT", "CTRL", "ALT")
KEY_ALIASES = {
    "ENTER": "RETURN",
    "ESC": "ESCAPE",
}
CODE_PATTERN = re.compile(r"^CODE:(\d+)$")

# X11 keycodes (evdev + 8) plus evdev KEY_1..KEY_8 for the digit row.
SCAN_CODE_TO_KEY_ID = {
    2: "1",
    3: "2",
    4: "3",
    5: "4",
    6: "5",
    7: "6",
    8: "7",
    9: "8",
    10: "1",
    11: "2",
    12: "3",
    13: "4",
    14: "5",
    15: "6",
    16: "7",
    17: "8",
    18: "9",
    19: "0",
    20: "MINUS",
    21: "EQUAL",
    22: "BACKSPACE",
    23: "TAB",
    34: "BRACKETLEFT",
    35: "BRACKETRIGHT",
    36: "RETURN",
    47: "SEMICOLON",
    48: "APOSTROPHE",
    49: "GRAVE",
    51: "BACKSLASH",
    59: "COMMA",
    60: "PERIOD",
    61: "SLASH",
    65: "SPACE",
}

SCAN_CODE_TO_MODIFIER = {
    29: "CTRL",
    37: "CTRL",
    97: "CTRL",
    105: "CTRL",
    42: "SHIFT",
    50: "SHIFT",
    54: "SHIFT",
    62: "SHIFT",
    56: "ALT",
    64: "ALT",
    100: "ALT",
    108: "ALT",
    125: "SUPER",
    133: "SUPER",
    126: "SUPER",
    134: "SUPER",
}

# Omarchy binds workspaces as SUPER + code:10..19.
X11_KEYCODE_TO_DIGIT = {
    10: "1",
    11: "2",
    12: "3",
    13: "4",
    14: "5",
    15: "6",
    16: "7",
    17: "8",
    18: "9",
    19: "0",
}

TEXT_TO_KEY_ID = {
    "!": "1",
    "@": "2",
    "#": "3",
    "$": "4",
    "%": "5",
    "^": "6",
    "&": "7",
    "*": "8",
    "(": "9",
    ")": "0",
    '"': "2",
}

# Qt::Key numeric values used by keyIdFromQtKey in KeyboardModel.js.
QT_KEY_NUMBER_SIGN = 0x23
QT_KEY_A = 0x41
QT_KEY_Z = 0x5A
QT_KEY_0 = 0x30
QT_KEY_9 = 0x39
QT_KEY_F1 = 0x01000030
QT_KEY_SHIFT = 0x01000020
QT_KEY_CONTROL = 0x01000021
QT_KEY_META = 0x01000022
QT_KEY_ALT = 0x01000023
QT_KEY_CAPSLOCK = 0x01000024


def key_id_from_scan_code(scan_code: int) -> str:
    return SCAN_CODE_TO_KEY_ID.get(scan_code, "")


def modifier_from_scan_code(scan_code: int) -> str:
    return SCAN_CODE_TO_MODIFIER.get(scan_code, "")


def key_id_from_text(text: str) -> str:
    if not text:
        return ""
    if len(text) == 1 and "0" <= text <= "9":
        return text
    return TEXT_TO_KEY_ID.get(text, "")


def key_id_from_x11_code(code: int) -> str:
    return X11_KEYCODE_TO_DIGIT.get(code, "")


def normalize_key_token(value: str) -> str:
    key = value.strip().upper()
    if key == "" or key == " ":
        return "SPACE"
    coded = CODE_PATTERN.match(key)
    if coded:
        return key_id_from_x11_code(int(coded.group(1))) or key
    return KEY_ALIASES.get(key, key)


def normalize_shortcut(text: str) -> str:
    tokens = [token.strip().upper() for token in re.split(r"[\s+]+", text) if token.strip()]
    modifiers = [modifier for modifier in MODIFIER_ORDER if modifier in tokens]
    keys = [normalize_key_token(token) for token in tokens if token not in MODIFIER_ORDER]
    if not keys:
        return ""
    return " + ".join([*modifiers, keys[-1]])
