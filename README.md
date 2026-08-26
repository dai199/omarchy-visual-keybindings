# Omarchy Keyboard Shortcuts

An interactive keyboard for exploring shortcuts configured in Omarchy and
Hyprland. Select or hold modifier keys to see which combinations are already
in use and which keys are still available.

> [!NOTE]
> This is an early, read-only preview. It does not modify your Hyprland
> configuration.

## Features

- Visual US ANSI keyboard layout
- Clickable modifier filters for Super, Shift, Ctrl, and Alt
- Physical modifier key tracking while the overlay is focused
- Used and available key states
- Shortcut descriptions on selection
- Automatic refresh whenever the overlay opens
- Theme integration with Omarchy Shell

## Requirements

- Omarchy 4.0 or newer
- Omarchy Shell
- Python 3

## Install for development

Clone or copy this repository into the Omarchy user plugin directory:

```bash
git clone <repository-url> ~/.config/omarchy/plugins/daikigames.keyboard-shortcuts
omarchy plugin validate ~/.config/omarchy/plugins/daikigames.keyboard-shortcuts
omarchy plugin enable daikigames.keyboard-shortcuts
```

Open the overlay with:

```bash
omarchy-shell shell toggle daikigames.keyboard-shortcuts
```

You can bind that command in `~/.config/hypr/bindings.lua`:

```lua
o.bind(
  "SUPER + ALT + K",
  "Visual keyboard shortcuts",
  "omarchy-shell shell toggle daikigames.keyboard-shortcuts"
)
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
- Safe shortcut creation with preview, backup, validation, and rollback

## License

MIT
