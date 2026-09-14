# Installation verification

Tested on 2026-09-14 with Omarchy 4.0.3-1, on the running desktop.

## Installed revision

`3d255be658c2b9f58b4a121eab86089c3968cbe4`

The existing development copy was backed up and moved out of the plugin
directory. The following command cloned the public GitHub repository,
validated it, and enabled the plugin:

```bash
omarchy plugin add https://github.com/dai199/omarchy-visual-keybindings.git --enable --yes
```

`--yes` only answers the install confirmation. The installed checkout matched
the published revision and had no tracked or untracked changes.

## Results

- Installation, manifest validation, and enabling: passed.
- Opening with the README's `omarchy-shell shell toggle` command: passed.
- Shortcut loading and on-screen Super/Alt filters: passed.
- Entering the capture submap on open and returning to `default` on close: passed.
- Creating `SUPER + ALT + Q` with `/usr/bin/true` through the UI: passed.
- Editing the test shortcut's description through the UI and reading it back: passed.
- Removing the test shortcut through the confirmation UI: passed.
- Disabling and restoring the stock `SUPER + T` binding through the UI: passed.
- Hyprland configuration validation after changes: no errors.
- Existing helper suite: 32 tests passed before installation.

UI tests used Wayland pointer input and virtual text entry, with screenshots
and helper output checked after actions. Physical keyboard chords were not
verified: virtual keyboard keycodes are not equivalent to the hardware's
keycodes. Rejected-save rollback is covered by the helper tests, not by a
deliberately invalid live configuration.

On 2026-09-15, the owner confirmed physical Super+Alt+Q selection, modifier
release after cancelling, and Shift release. Normal shortcuts after closing
were also reported as apparently working.

The restore operation left one additional trailing blank line, which was
removed during cleanup. The final `bindings.lua` matches the pre-test copy
byte for byte. The plugin's timestamped backups remain available.

## Fix verified

Omarchy Shell strips `__sourceDir` from third-party manifests. The plugin now
resolves helper paths relative to its QML file with `Qt.resolvedUrl`, including
URL decoding. The missing-helper errors seen before the fix did not recur
during the installed-version UI tests. A shell restart was needed during the
initial development check to clear the old QML instance.
