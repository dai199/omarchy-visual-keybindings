# Input layers

Visual Keybindings splits keyboard handling into three layers so Omarchy
defaults, machine quirks, and user policy can change independently.

## 1. Physical identity

`KeyboardModel.js` and `scripts/key_identity.py` decide *which key was
pressed*. They prefer scan codes, then Qt key values, then shifted text.

| Source | Example | Handling |
|--------|---------|----------|
| Any XKB layout | Shift+3 arrives as `#` | Map digit-row scan codes and shifted symbols back to `1`–`0` |
| Omarchy `kb_options` | Shift release reported as CapsLock | Clear Shift only while Shift is already held |
| Some Apple/JP + IME setups | Alt reported as Shift | Prefer modifier scan codes over Qt key names |

Hyprland/Omarchy workspace binds use X11 keycodes `code:10`–`code:19` for
the number row so the same chords work on US and JIS. The overlay uses the
same identity.

## 2. Compositor capture

Exclusive layer-shell focus plus `ShortcutInhibitor` is not enough for
Omarchy number chords. Hyprland still consumes `SUPER + code:12` before
the overlay sees `3`.

While the overlay is open the plugin enters a Hyprland submap so those
binds do not fire. `scripts/set-submap pause` defines the submap unless
the user already owns it, then enters it. `reset` leaves it.

## 3. User policy

Shipped defaults live in `compositor.json`. Optional overrides:

```json
{
  "hyprland": {
    "submap": "visual-keybindings",
    "autoDefine": true,
    "closeKeys": "SUPER + SHIFT + K"
  }
}
```

Put that file at `~/.config/omarchy/extensions/dai199.visual-keybindings.json`.
Set `autoDefine` to `false` if `hypr/submap.lua` (or your own submap of the
same name) is already in `~/.config/hypr/bindings.lua`. The plugin then
only dispatches into the submap you built.

The same override file can replace the Create/Edit chips. A `presets`
array replaces the shipped list from `presets.json`; omit it to keep the
defaults.

```json
{
  "presets": [
    {
      "id": "terminal",
      "label": "Terminal",
      "description": "Terminal",
      "command": "omarchy-launch-terminal"
    }
  ]
}
```
