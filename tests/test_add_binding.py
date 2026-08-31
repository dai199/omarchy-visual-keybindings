import importlib.machinery
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOADER = importlib.machinery.SourceFileLoader(
    "add_binding", str(ROOT / "scripts" / "add-binding")
)
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class AddBindingTest(unittest.TestCase):
    def test_normalizes_shortcut_order(self):
        self.assertEqual(
            MODULE.shortcut(["alt", "super", "shift"], "k"),
            "SUPER + SHIFT + ALT + K",
        )

    def test_renders_escaped_lua_strings(self):
        rendered = MODULE.render_binding(
            "SUPER + K", 'Open "notes"', "printf 'a\\b'"
        )
        self.assertIn(r'Open \"notes\"', rendered)
        self.assertEqual(MODULE.lua_string("a\\b"), '"a\\\\b"')

    def test_rejects_empty_fields(self):
        with self.assertRaisesRegex(MODULE.AddBindingError, "Description"):
            MODULE.render_binding("SUPER + K", " ", "command")

    def test_writes_binding_and_backup_without_reloading(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "bindings.lua"
            config.write_text("-- Existing bindings\n", encoding="utf-8")
            provider = root / "provider"
            provider.write_text("#!/bin/sh\nprintf '[]\\n'\n", encoding="utf-8")
            provider.chmod(0o755)

            backup = MODULE.add_binding(
                config,
                provider,
                "SUPER + K",
                "Open notes",
                "notes-app",
                reload_config=False,
            )

            self.assertEqual(backup.read_text(), "-- Existing bindings\n")
            self.assertIn('o.bind("SUPER + K", "Open notes", "notes-app")', config.read_text())

    def test_rejects_a_shortcut_that_became_occupied(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "bindings.lua"
            provider = root / "provider"
            rows = [{"shortcut": "SUPER + K"}]
            provider.write_text(
                "#!/bin/sh\nprintf '%s\\n' '" + json.dumps(rows) + "'\n",
                encoding="utf-8",
            )
            provider.chmod(0o755)

            with self.assertRaisesRegex(MODULE.AddBindingError, "already configured"):
                MODULE.add_binding(
                    config,
                    provider,
                    "SUPER + K",
                    "Open notes",
                    "notes-app",
                    reload_config=False,
                )


if __name__ == "__main__":
    unittest.main()
