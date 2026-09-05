import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "set-submap"


class SetSubmapTest(unittest.TestCase):
    def test_rejects_unknown_submap_names(self):
        result = subprocess.run(
            [str(SCRIPT), "not-a-submap"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("unsupported submap", result.stderr)

    def test_registers_the_submap_itself(self):
        source = SCRIPT.read_text(encoding="utf-8")
        self.assertIn("hl.define_submap", source)
        self.assertIn("code:10-19", source)


if __name__ == "__main__":
    unittest.main()
