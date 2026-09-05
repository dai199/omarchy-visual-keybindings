import importlib.machinery
import importlib.util
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"


def load_module(name: str, path: Path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


IDENTITY = load_module("key_identity", SCRIPTS / "key_identity.py")


class KeyIdentityTest(unittest.TestCase):
    def test_shift_3_is_the_digit_three(self):
        self.assertEqual(IDENTITY.key_id_from_scan_code(12), "3")
        self.assertEqual(IDENTITY.key_id_from_text("#"), "3")
        self.assertEqual(IDENTITY.key_id_from_x11_code(12), "3")

    def test_digit_row_x11_codes_map_to_1_through_0(self):
        self.assertEqual(
            [IDENTITY.key_id_from_x11_code(code) for code in range(10, 20)],
            [str(digit) if digit else "0" for digit in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]],
        )

    def test_super_scan_codes(self):
        self.assertEqual(IDENTITY.modifier_from_scan_code(133), "SUPER")
        self.assertEqual(IDENTITY.modifier_from_scan_code(125), "SUPER")

    def test_keyboard_model_js_keeps_the_python_tables(self):
        source = (ROOT / "KeyboardModel.js").read_text(encoding="utf-8")
        for code, key in IDENTITY.SCAN_CODE_TO_KEY_ID.items():
            self.assertRegex(source, rf"\b{code}: \"{re.escape(key)}\"")
        for code, name in IDENTITY.SCAN_CODE_TO_MODIFIER.items():
            self.assertRegex(source, rf"\b{code}: \"{re.escape(name)}\"")
        self.assertIn('"#": "3"', source)
        self.assertIn("0x23: \"3\"", source)


if __name__ == "__main__":
    unittest.main()
