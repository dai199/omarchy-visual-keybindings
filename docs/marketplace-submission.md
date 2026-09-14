### Repository URL

https://github.com/dai199/omarchy-visual-keybindings

### Category

Productivity

### Tags

hyprland, quickshell

### Suggest a missing tag

_No response_

### Maintainer notes

Visual Keybindings is an Omarchy Shell overlay for exploring and managing
shortcuts on an interactive US ANSI keyboard. It requires Omarchy 4's
Lua-based Hyprland configuration, Omarchy Shell, and Python 3 (standard
library only). No additional package installation or root access is required.

While open, it uses hyprctl eval to define and enter a temporary input
submap. Explicit save, remove, and restore actions update the user's
bindings.lua with backups, reload validation, and rollback on rejection.
User-entered commands are stored as keybindings, not executed by the editor.
Removal instructions and configuration effects are documented in the README.

The initial version is 0.1.0, an early preview. The repository includes
32 passing helper tests, including a simulated Hyprland rejection and rollback.
The preview image shows the keyboard overview.

### Submission checklist

- [ ] The repository is public and contains installation and removal instructions.
- [ ] I have documented the plugin license and any external dependencies.
- [ ] I confirm that I own or have permission to submit this plugin and its preview assets.
- [ ] The plugin does not overwrite user configuration without explicit consent.
- [ ] I understand that approval is for listing and is not a security review.
