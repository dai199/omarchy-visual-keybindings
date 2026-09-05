-- Required so Visual Keybindings can receive Super+number chords.
-- Omarchy binds those as X11 keycodes (code:10-19), which Hyprland otherwise
-- consumes even while the overlay has exclusive keyboard focus.
--
-- Append this to ~/.config/hypr/bindings.lua, then `hyprctl reload`.

hl.define_submap("visual-keybindings", function()
  hl.bind("SUPER + SHIFT + K", function()
    hl.dispatch(hl.dsp.submap("reset"))
    hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell hide dai199.visual-keybindings"))
  end)
end)
