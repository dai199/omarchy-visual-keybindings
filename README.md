# Visual Keybindings

An interactive keyboard for exploring shortcuts configured in Omarchy and
Hyprland. Select or hold modifier keys to see which combinations are already
in use and which keys are still available.

> [!NOTE]
> This is an early preview. Shortcut creation always shows a preview and
> validates Hyprland after saving, but you should still review commands before
> running them.

## Features

- Visual US ANSI keyboard layout
- Clickable modifier filters for Super, Shift, Ctrl, and Alt
- Physical modifier key tracking while the overlay is focused
- Used and available key states
- Shortcut descriptions on selection
- Shortcut creation for available key combinations
- Automatic backup, validation, and rollback when saving
- Automatic refresh whenever the overlay opens
- Theme integration with Omarchy Shell

## Requirements

- Omarchy 4.0 or newer
- Omarchy Shell
- Python 3

## Install for development

Install from GitHub:

```bash
omarchy plugin add https://github.com/dai199/omarchy-visual-keybindings.git --enable
```

Or clone into the Omarchy user plugin directory while developing:

```bash
git clone https://github.com/dai199/omarchy-visual-keybindings.git ~/.config/omarchy/plugins/dai199.visual-keybindings
omarchy plugin validate ~/.config/omarchy/plugins/dai199.visual-keybindings
omarchy plugin enable dai199.visual-keybindings
```

Open the overlay with:

```bash
omarchy-shell shell toggle dai199.visual-keybindings
```

You can bind that command in `~/.config/hypr/bindings.lua`:

```lua
o.bind(
  "SUPER + SHIFT + K",
  "Visual Keybindings",
  "omarchy-shell shell toggle dai199.visual-keybindings"
)
```

On a stock Omarchy install, `SUPER + K` already opens the text keybinding
list. `SUPER + ALT + K` and `SUPER + CTRL + K` open the Tmux and Herdr
lists, so `SUPER + SHIFT + K` is the free neighbor of those shortcuts.

Omarchy binds workspace numbers as keycodes (`SUPER + code:12` rather than
`SUPER + 3`). Hyprland consumes those chords unless an empty submap is
active while the overlay is open. Append `hypr/visual-keybindings.lua` to
`~/.config/hypr/bindings.lua`, then `hyprctl reload`.

Add a menu row in `~/.config/omarchy/extensions/omarchy-menu.jsonc` to
open the overlay from Super+Space → Learn:

```jsonc
"learn.visual-keybindings": {
  "icon": "󰌌",
  "label": "Visual Keybindings",
  "aliases": ["visual-keybindings", "visual-keyboard"],
  "description": "Interactive keyboard of configured shortcuts",
  "action": "omarchy-shell shell toggle dai199.visual-keybindings"
}
```

## Development

Validate the plugin and run the parser tests:

```bash
omarchy plugin validate .
python3 -m unittest discover -s tests -v
```

Files below `~/.config/omarchy/plugins/` are watched by Omarchy Shell and
reload automatically while developing.

## Roadmap

- JIS keyboard layout
- Search and category filters
- Distinguish Omarchy defaults from user overrides
- Conflict detection

## License

MIT
