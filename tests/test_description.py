import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


EXACT = {
    "omarchy-launch-terminal": "Terminal",
    "omarchy-launch-browser": "Browser",
    "omarchy-launch-nautilus": "File manager",
    "omarchy-launch-nautilus-cwd": "File manager (cwd)",
    "omarchy-launch-editor": "Editor",
    "omarchy-capture-screenshot": "Screenshot",
    "omarchy-capture-screenrecording": "Screen recording",
    "omarchy-system-lock": "Lock screen",
    "omarchy-toggle-nightlight": "Toggle nightlight",
    "omarchy-menu": "Omarchy menu",
}

PREFIXES = (
    "omarchy-launch-",
    "omarchy-capture-",
    "omarchy-system-",
    "omarchy-toggle-",
    "omarchy-menu-",
    "omarchy-",
)


def command_program(command: str) -> str:
    for part in str(command or "").strip().split():
        if part.startswith("-"):
            continue
        if "=" in part and "/" not in part:
            continue
        return part.split("/")[-1]
    return ""


def description_from_command(command: str) -> str:
    program = command_program(command)
    if not program:
        return ""
    if program in EXACT:
        return EXACT[program]
    name = program
    for prefix in PREFIXES:
        if name.startswith(prefix):
            name = name[len(prefix) :]
            break
    return " ".join(word[:1].upper() + word[1:].lower() for word in re.split(r"[-_]+", name) if word)


class DescriptionFromCommandTest(unittest.TestCase):
    def test_known_omarchy_commands(self):
        self.assertEqual(description_from_command("omarchy-launch-terminal"), "Terminal")
        self.assertEqual(description_from_command("omarchy-launch-nautilus"), "File manager")
        self.assertEqual(description_from_command("omarchy-capture-screenshot"), "Screenshot")
        self.assertEqual(description_from_command("omarchy-system-lock"), "Lock screen")
        self.assertEqual(description_from_command("omarchy-menu toggle"), "Omarchy menu")

    def test_strips_path_flags_and_env(self):
        self.assertEqual(description_from_command("/usr/bin/omarchy-launch-terminal"), "Terminal")
        self.assertEqual(description_from_command("DISPLAY=:0 omarchy-launch-browser"), "Browser")
        self.assertEqual(description_from_command(""), "")

    def test_humanizes_unknown_omarchy_commands(self):
        self.assertEqual(description_from_command("omarchy-launch-spotify"), "Spotify")
        self.assertEqual(description_from_command("omarchy-toggle-idle"), "Idle")
        self.assertEqual(description_from_command("notify-send"), "Notify Send")

    def test_javascript_keeps_the_same_examples(self):
        source = (ROOT / "KeyboardModel.js").read_text(encoding="utf-8")
        self.assertIn("function descriptionFromCommand(", source)
        for command, label in EXACT.items():
            self.assertIn(f'"{command}": "{label}"', source)
