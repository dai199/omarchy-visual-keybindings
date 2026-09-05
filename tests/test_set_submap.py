import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "set-submap"


class SetSubmapTest(unittest.TestCase):
    def test_rejects_unknown_modes(self):
        result = subprocess.run(
            [str(SCRIPT), "not-a-mode"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)

    def test_pause_prints_runtime_definition(self):
        result = subprocess.run(
            [str(SCRIPT), "pause", "--print-lua", "--no-eval"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0)
        self.assertIn("hl.define_submap", result.stdout)
        self.assertIn("visual-keybindings", result.stdout)


if __name__ == "__main__":
    unittest.main()
