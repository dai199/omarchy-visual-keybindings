"""Read and rewrite ~/.config/hypr/bindings.lua for plugin-managed changes."""

from __future__ import annotations

import re

from key_identity import normalize_shortcut

PLUGIN_ADDED = "Added by Visual Keybindings"
PLUGIN_OVERRIDE = "Overridden by Visual Keybindings"
PLUGIN_DISABLE = "Disabled by Visual Keybindings"

BIND_RE = re.compile(
    r"o\.bind\(\s*"
    r'"((?:\\.|[^"\\])*)"\s*,\s*'
    r'(?:"((?:\\.|[^"\\])*)"|nil)\s*,\s*'
    r'(?:"((?:\\.|[^"\\])*)"|\{)',
    re.S,
)
UNBIND_RE = re.compile(r'hl\.unbind\(\s*"((?:\\.|[^"\\])*)"', re.S)


def unescape_lua_string(value: str) -> str:
    return (
        value.replace("\\n", "\n")
        .replace("\\t", "\t")
        .replace("\\r", "\r")
        .replace('\\"', '"')
        .replace("\\\\", "\\")
    )


def lua_string(value: str) -> str:
    escaped = (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )
    return f'"{escaped}"'


def _last_comment(prefix: str) -> str:
    lines = [line.strip() for line in prefix.splitlines() if line.strip()]
    return lines[-1] if lines else ""


def _is_commented(text: str, pos: int) -> bool:
    line_start = text.rfind("\n", 0, pos) + 1
    return text[line_start:pos].lstrip().startswith("--")


def parse_user_bindings(text: str) -> dict[str, dict[str, object]]:
    found: dict[str, dict[str, object]] = {}
    for match in BIND_RE.finditer(text):
        if _is_commented(text, match.start()):
            continue
        shortcut = normalize_shortcut(unescape_lua_string(match.group(1)))
        if not shortcut:
            continue
        comment = _last_comment(text[: match.start()])
        plugin = comment.startswith("-- " + PLUGIN_ADDED) or comment.startswith(
            "-- " + PLUGIN_OVERRIDE
        )
        command = unescape_lua_string(match.group(3)) if match.group(3) is not None else ""
        found[shortcut] = {
            "shortcut": shortcut,
            "description": unescape_lua_string(match.group(2) or ""),
            "command": command,
            "plugin": plugin,
        }
    return found


def parse_user_unbinds(text: str) -> set[str]:
    found: set[str] = set()
    for match in UNBIND_RE.finditer(text):
        if _is_commented(text, match.start()):
            continue
        shortcut = normalize_shortcut(unescape_lua_string(match.group(1)))
        if shortcut:
            found.add(shortcut)
    return found


def origin_for(shortcut: str, user_binds: dict[str, dict[str, object]]) -> str:
    row = user_binds.get(shortcut)
    if not row:
        return "omarchy"
    return "plugin" if row.get("plugin") else "user"


def command_for(shortcut: str, user_binds: dict[str, dict[str, object]]) -> str:
    row = user_binds.get(shortcut) or {}
    return str(row.get("command") or "")


def render_bind_line(shortcut: str, description: str, command: str) -> str:
    return (
        f"o.bind({lua_string(shortcut)}, {lua_string(description)}, "
        f"{lua_string(command)})\n"
    )


def remove_managed_blocks(text: str, shortcut: str) -> str:
    escaped = re.escape(shortcut)
    pattern = re.compile(
        rf"\n-- (?:{re.escape(PLUGIN_ADDED)}|{re.escape(PLUGIN_OVERRIDE)}|"
        rf"{re.escape(PLUGIN_DISABLE)})[^\n]*\n"
        rf"(?:hl\.unbind\(\s*\"{escaped}\"\s*\)\s*\n)?"
        rf"(?:o\.bind\(\s*\"{escaped}\"[^\n]*\n)?",
    )
    return pattern.sub("\n", text)


def write_override(
    text: str,
    shortcut: str,
    description: str,
    command: str,
    previous: str,
    unbind_first: bool,
) -> str:
    cleaned = remove_managed_blocks(text, shortcut).rstrip() + "\n"
    if unbind_first:
        was = previous.strip() or "Omarchy default"
        return (
            cleaned
            + f"\n-- {PLUGIN_OVERRIDE} (was: {was})\n"
            + f"hl.unbind({lua_string(shortcut)})\n"
            + render_bind_line(shortcut, description, command)
        )
    return (
        cleaned
        + f"\n-- {PLUGIN_ADDED}\n"
        + render_bind_line(shortcut, description, command)
    )


def write_disable(text: str, shortcut: str, previous: str, plugin_only: bool) -> str:
    cleaned = remove_managed_blocks(text, shortcut).rstrip() + "\n"
    if plugin_only:
        return cleaned
    was = previous.strip() or "Omarchy default"
    return (
        cleaned
        + f"\n-- {PLUGIN_DISABLE} (was: {was})\n"
        + f"hl.unbind({lua_string(shortcut)})\n"
    )
