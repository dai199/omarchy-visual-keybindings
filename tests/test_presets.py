import json
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class PresetsTest(unittest.TestCase):
    def test_shipped_presets_are_complete_and_unique(self):
        rows = json.loads((ROOT / "presets.json").read_text(encoding="utf-8"))
        self.assertIsInstance(rows, list)
        self.assertGreaterEqual(len(rows), 8)
        ids = []
        commands = []
        for row in rows:
            self.assertTrue(row["id"].strip())
            self.assertTrue(row["label"].strip())
            self.assertTrue(row["description"].strip())
            self.assertTrue(row["command"].strip())
            ids.append(row["id"])
            commands.append(row["command"])
        self.assertEqual(len(ids), len(set(ids)))
        self.assertEqual(len(commands), len(set(commands)))

    def test_keyboard_model_keeps_preset_helpers(self):
        source = (ROOT / "KeyboardModel.js").read_text(encoding="utf-8")
        self.assertIn("function normalizePresets(", source)
        self.assertIn("function pickPresets(", source)
        self.assertIn("function matchingPreset(", source)
        self.assertRegex(source, re.compile(r"user\.presets"))
