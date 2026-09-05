"""Hyprland capture policy for the overlay.

Layering:
  1. Physical identity (KeyboardModel.js / key_identity.py) maps keys.
  2. This module pauses compositor binds so those keys reach the overlay.
  3. Users may own the pause submap themselves via compositor.json overrides.

Omarchy binds workspace numbers as SUPER + code:10-19. Hyprland consumes
those chords even with exclusive layer-shell focus. A pause submap is the
portable workaround; this file defines it at runtime unless the user already
did so in ~/.config/hypr/bindings.lua.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

SUBMAP_NAME = re.compile(r"^[A-Za-z][A-Za-z0-9_-]*$")

PLUGIN_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CONFIG = PLUGIN_ROOT / "compositor.json"


def user_override_path(plugin_id: str) -> Path:
    return Path.home() / ".config" / "omarchy" / "extensions" / f"{plugin_id}.json"


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def merge_config(base: dict, override: dict) -> dict:
    merged = dict(base)
    hypr = dict(base.get("hyprland") or {})
    if isinstance(override.get("hyprland"), dict):
        hypr.update(override["hyprland"])
    for key, value in override.items():
        if key != "hyprland":
            merged[key] = value
    merged["hyprland"] = hypr
    return merged


def load_config(config_path: Path | None = None, override_path: Path | None = None) -> dict:
    shipped = load_json(config_path or DEFAULT_CONFIG)
    plugin_id = str(shipped.get("pluginId") or "dai199.visual-keybindings")
    override = override_path if override_path is not None else user_override_path(plugin_id)
    if override.exists():
        shipped = merge_config(shipped, load_json(override))
    hypr = shipped.setdefault("hyprland", {})
    hypr.setdefault("submap", "visual-keybindings")
    hypr.setdefault("autoDefine", True)
    hypr.setdefault("closeKeys", "SUPER + SHIFT + K")
    shipped["pluginId"] = str(shipped.get("pluginId") or plugin_id)
    return shipped


def lua_string(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def pause_lua(config: dict) -> str:
    hypr = config.get("hyprland") or {}
    name = str(hypr.get("submap") or "visual-keybindings")
    if not SUBMAP_NAME.match(name) or name == "reset":
        raise ValueError(f"unsupported submap: {name}")
    if not hypr.get("autoDefine", True):
        return f"hl.dispatch(hl.dsp.submap({lua_string(name)}))\n"

    close_keys = str(hypr.get("closeKeys") or "SUPER + SHIFT + K")
    plugin_id = str(config.get("pluginId") or "")
    hide = f"omarchy-shell shell hide {plugin_id}"
    return (
        f"hl.define_submap({lua_string(name)}, function()\n"
        f"  hl.bind({lua_string(close_keys)}, function()\n"
        f"    hl.dispatch(hl.dsp.submap({lua_string('reset')}))\n"
        f"    hl.dispatch(hl.dsp.exec_cmd({lua_string(hide)}))\n"
        "  end)\n"
        "end)\n"
        f"hl.dispatch(hl.dsp.submap({lua_string(name)}))\n"
    )


def reset_lua() -> str:
    return 'hl.dispatch(hl.dsp.submap("reset"))\n'


def eval_lua(source: str) -> None:
    result = subprocess.run(
        ["hyprctl", "eval", source],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        detail = (result.stderr or result.stdout or "hyprctl eval failed").strip()
        raise RuntimeError(detail)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("pause", "reset"))
    parser.add_argument("--config", type=Path)
    parser.add_argument("--override", type=Path)
    parser.add_argument("--print-lua", action="store_true")
    parser.add_argument("--no-eval", action="store_true")
    args = parser.parse_args(argv)

    config = load_config(args.config, args.override)
    source = reset_lua() if args.mode == "reset" else pause_lua(config)
    if args.print_lua:
        sys.stdout.write(source)
    if args.no_eval:
        return 0
    try:
        eval_lua(source)
    except (OSError, RuntimeError, ValueError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
