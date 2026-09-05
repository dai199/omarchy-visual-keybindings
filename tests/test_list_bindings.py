import importlib.machinery
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOADER = importlib.machinery.SourceFileLoader(
    "list_bindings", str(ROOT / "scripts" / "list-bindings")
)
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class ParseBindingsTest(unittest.TestCase):
    def test_parses_shortcuts_and_normalizes_modifier_order(self):
        source = (ROOT / "tests" / "fixtures" / "keybindings.txt").read_text()
        bindings = MODULE.parse_bindings(source)

        self.assertEqual(len(bindings), 8)
        self.assertEqual(bindings[0]["key"], "RETURN")
        self.assertEqual(bindings[1]["shortcut"], "SUPER + SHIFT + F")
        self.assertEqual(bindings[2]["modifiers"], ["SHIFT", "ALT"])
        self.assertEqual(bindings[3]["description"], "Omarchy menu")
        self.assertEqual(bindings[5]["shortcut"], "SUPER + SHIFT + 3")
        self.assertEqual(bindings[5]["key"], "3")
        self.assertEqual(bindings[6]["shortcut"], "SUPER + 3")
        self.assertEqual(bindings[6]["key"], "3")

    def test_ignores_rows_without_a_key(self):
        self.assertEqual(MODULE.parse_bindings("SUPER → Modifier only"), [])


if __name__ == "__main__":
    unittest.main()
