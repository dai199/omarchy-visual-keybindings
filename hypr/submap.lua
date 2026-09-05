-- Optional user-owned pause submap for Visual Keybindings.
--
-- The plugin defines this at runtime by default. Copy it into
-- ~/.config/hypr/bindings.lua only if you want to own the submap, then set
-- hyprland.autoDefine to false in:
--   ~/.config/omarchy/extensions/dai199.visual-keybindings.json

hl.define_submap("visual-keybindings", function()
  hl.bind("SUPER + SHIFT + K", function()
    hl.dispatch(hl.dsp.submap("reset"))
    hl.dispatch(hl.dsp.exec_cmd("omarchy-shell shell hide dai199.visual-keybindings"))
  end)
end)
