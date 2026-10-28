package.path = package.path .. ";./?.lua;./?/init.lua"
local smw = require("plugins.split-monitor-workspaces")
smw.setup({ workspace_count = 10 })
for i = 1, smw.get_amount_of_workspaces() do
  local key = tostring(i % 10)
  hl.bind("SUPER + " .. key, smw.workspace(key), { description = "Switch to workspace " .. i })
  hl.bind("SUPER + SHIFT + " .. key, smw.move_to_workspace_silent(key), { description = "Move window to workspace " .. i })
end
hl.bind("SUPER + SPACE", hl.dsp.workspace.toggle_special(), { description = "Toggle special workspace" })
hl.bind("SUPER + SHIFT + SPACE", hl.dsp.window.move({ workspace = "special" }), { description = "Move window to special workspace" })
