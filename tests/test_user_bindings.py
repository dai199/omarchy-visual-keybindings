import importlib.machinery
import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load(name: str, path: Path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


USER = load("user_bindings", ROOT / "scripts" / "user_bindings.py")
ADD = load("add_binding", ROOT / "scripts" / "add-binding")
LIST = load("list_bindings", ROOT / "scripts" / "list-bindings")


class UserBindingsTest(unittest.TestCase):
    def test_classifies_plugin_and_user_binds(self):
        text = (ROOT / "tests" / "fixtures" / "user_bindings.lua").read_text()
        binds = USER.parse_user_bindings(text)
        self.assertEqual(binds["SHIFT + ALT + 4"]["plugin"], True)
        self.assertEqual(binds["SUPER + SHIFT + K"]["plugin"], False)
        self.assertNotIn("SUPER + SPACE", binds)
        self.assertEqual(
            binds["SHIFT + ALT + 4"]["command"],
            "omarchy-capture-screenshot",
        )

    def test_override_default_appends_unbind(self):
        text = "-- defaults only\n"
        updated = USER.write_override(
            text,
            "SUPER + 3",
            "Custom workspace",
            "true",
            "Switch to workspace 3",
            True,
        )
        self.assertIn("hl.unbind(\"SUPER + 3\")", updated)
        self.assertIn("o.bind(\"SUPER + 3\", \"Custom workspace\", \"true\")", updated)
        self.assertIn("Overridden by Visual Keybindings", updated)

    def test_replace_plugin_bind_does_not_stack_blocks(self):
        text = (ROOT / "tests" / "fixtures" / "user_bindings.lua").read_text()
        updated = USER.write_override(
            text,
            "SHIFT + ALT + 4",
            "Shot",
            "true",
            "Screenshot",
            False,
        )
        self.assertEqual(updated.count("Added by Visual Keybindings"), 1)
        self.assertIn("o.bind(\"SHIFT + ALT + 4\", \"Shot\", \"true\")", updated)
        self.assertNotIn("omarchy-capture-screenshot", updated)

    def test_disable_plugin_bind_removes_block(self):
        text = (ROOT / "tests" / "fixtures" / "user_bindings.lua").read_text()
        updated = USER.write_disable(text, "SHIFT + ALT + 4", "Screenshot", True)
        self.assertNotIn("SHIFT + ALT + 4", updated)
        self.assertNotIn('hl.unbind("SHIFT + ALT + 4")', updated)

    def test_disable_omarchy_bind_appends_unbind(self):
        updated = USER.write_disable("-- cfg\n", "SUPER + 3", "Switch to workspace 3", False)
        self.assertIn("hl.unbind(\"SUPER + 3\")", updated)
        self.assertIn("Disabled by Visual Keybindings", updated)

    def test_list_bindings_marks_origins(self):
        printed = (ROOT / "tests" / "fixtures" / "keybindings.txt").read_text()
        user = (ROOT / "tests" / "fixtures" / "user_bindings.lua").read_text()
        rows = LIST.parse_bindings(printed, user)
        by_shortcut = {row["shortcut"]: row for row in rows}
        self.assertEqual(by_shortcut["SUPER + RETURN"]["origin"], "omarchy")
        self.assertEqual(by_shortcut["SHIFT + ALT + 4"]["origin"], "plugin")
        self.assertEqual(by_shortcut["SHIFT + ALT + 4"]["command"], "omarchy-capture-screenshot")
        self.assertEqual(by_shortcut["SUPER + SHIFT + S"]["origin"], "disabled")
        self.assertEqual(by_shortcut["SUPER + SHIFT + S"]["description"], "Google Maps")
        self.assertNotIn("SUPER + SHIFT + B", by_shortcut)

    def test_skips_commented_unbinds_and_restores_disable_blocks(self):
        text = (ROOT / "tests" / "fixtures" / "user_bindings.lua").read_text()
        unbinds = USER.parse_user_unbinds(text)
        self.assertIn("SUPER + SHIFT + S", unbinds)
        self.assertEqual(unbinds["SUPER + SHIFT + S"]["previous"], "Google Maps")
        self.assertNotIn("SUPER + SHIFT + B", unbinds)
        restored = USER.write_restore(text, "SUPER + SHIFT + S")
        self.assertNotIn("hl.unbind(\"SUPER + SHIFT + S\")", restored)
        self.assertIn("SHIFT + ALT + 4", restored)

    def test_replace_and_remove_use_user_file(self):
        import json
        import tempfile

        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            config = root / "bindings.lua"
            config.write_text(
                (ROOT / "tests" / "fixtures" / "user_bindings.lua").read_text(),
                encoding="utf-8",
            )
            provider = root / "provider"
            rows = [
                {"shortcut": "SHIFT + ALT + 4"},
                {"shortcut": "SUPER + 3"},
            ]
            provider.write_text(
                "#!/bin/sh\nprintf '%s\\n' '" + json.dumps(rows) + "'\n",
                encoding="utf-8",
            )
            provider.chmod(0o755)

            ADD.replace_binding(
                config,
                provider,
                "SHIFT + ALT + 4",
                "Shot",
                "true",
                "Screenshot",
                reload_config=False,
            )
            self.assertIn("o.bind(\"SHIFT + ALT + 4\", \"Shot\", \"true\")", config.read_text())

            ADD.remove_binding(
                config,
                provider,
                "SUPER + 3",
                "Switch to workspace 3",
                reload_config=False,
            )
            self.assertIn("hl.unbind(\"SUPER + 3\")", config.read_text())


if __name__ == "__main__":
    unittest.main()
