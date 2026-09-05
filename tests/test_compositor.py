import importlib.machinery
import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOADER = importlib.machinery.SourceFileLoader(
    "compositor", str(ROOT / "scripts" / "compositor.py")
)
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
MODULE = importlib.util.module_from_spec(SPEC)
LOADER.exec_module(MODULE)


class CompositorConfigTest(unittest.TestCase):
    def test_pause_lua_defines_the_configured_submap(self):
        lua = MODULE.pause_lua(
            {
                "pluginId": "dai199.visual-keybindings",
                "hyprland": {
                    "submap": "custom-map",
                    "autoDefine": True,
                    "closeKeys": "SUPER + Q",
                },
            }
        )
        self.assertIn('hl.define_submap("custom-map"', lua)
        self.assertIn('hl.bind("SUPER + Q"', lua)
        self.assertIn("omarchy-shell shell hide dai199.visual-keybindings", lua)
        self.assertIn('hl.dsp.submap("custom-map")', lua)

    def test_pause_lua_skips_define_when_the_user_owns_the_submap(self):
        lua = MODULE.pause_lua(
            {
                "pluginId": "dai199.visual-keybindings",
                "hyprland": {"submap": "custom-map", "autoDefine": False},
            }
        )
        self.assertNotIn("define_submap", lua)
        self.assertIn('hl.dsp.submap("custom-map")', lua)

    def test_user_override_changes_close_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shipped = root / "compositor.json"
            shipped.write_text(
                json.dumps(
                    {
                        "pluginId": "example.plugin",
                        "hyprland": {
                            "submap": "visual-keybindings",
                            "autoDefine": True,
                            "closeKeys": "SUPER + SHIFT + K",
                        },
                    }
                ),
                encoding="utf-8",
            )
            override = root / "override.json"
            override.write_text(
                json.dumps({"hyprland": {"closeKeys": "SUPER + ESCAPE"}}),
                encoding="utf-8",
            )
            config = MODULE.load_config(shipped, override)
            lua = MODULE.pause_lua(config)
            self.assertIn('hl.bind("SUPER + ESCAPE"', lua)
            self.assertIn("hide example.plugin", lua)

    def test_rejects_unsafe_submap_names(self):
        with self.assertRaisesRegex(ValueError, "unsupported submap"):
            MODULE.pause_lua({"hyprland": {"submap": "reset"}})
        with self.assertRaisesRegex(ValueError, "unsupported submap"):
            MODULE.pause_lua({"hyprland": {"submap": 'x")'}})


if __name__ == "__main__":
    unittest.main()
