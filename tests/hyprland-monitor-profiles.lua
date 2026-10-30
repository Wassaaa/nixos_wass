local profiles = dofile("modules/home/features/desktop/hyprland/config/monitor-profiles.lua")
local originalGetenv, originalOpen = os.getenv, io.open
local saved, active, connected, windows, bindings, bindingOptions, notifications, rules, moves, failMove
local primary = { id = 1, name = "DP-2" }
local secondary = { id = 2, name = "HDMI-A-1" }
local mapping = { [1] = {}, [2] = {} }
for i = 1, 10 do
  mapping[1][i], mapping[2][i] = tostring(i), tostring(i + 10)
end
package.loaded["plugins.split-monitor-workspaces.lua.globals"] = { monitor_workspace_map = mapping }

os.getenv = function(name)
  if name == "XDG_RUNTIME_DIR" then return "/runtime" end
  if name == "HYPRLAND_INSTANCE_SIGNATURE" then return "session" end
  return originalGetenv(name)
end
io.open = function(path, mode)
  assert(path == "/runtime/hypr/session/monitor-profile")
  if mode == "r" then
    if not saved then return nil, "missing", 2 end
    return { read = function() return saved end, close = function() return true end }
  end
  assert(mode == "w")
  return {
    write = function(_, value) saved = value; return true end,
    close = function() return true end,
  }
end

local configs = {
  { name = "Both", monitors = {
    { output = "DP-2", disabled = false, position = "0x0" },
    { output = "HDMI-A-1", disabled = false, position = "2560x240" },
  } },
  { name = "Second", mergeTo = "HDMI-A-1", monitors = {
    { output = "DP-2", disabled = true },
    { output = "HDMI-A-1", disabled = false, position = "0x0" },
  } },
}

rawset(_G, "hl", {
  notification = { create = function(value) notifications[#notifications + 1] = value end },
  monitor = function(value) rules[#rules + 1] = value end,
  get_monitors = function(options) return options and connected or active end,
  get_windows = function() return windows end,
  bind = function(key, callback, options) bindings[key], bindingOptions[key] = callback, options end,
  dsp = { window = {
    move = function(value) return value end,
    pseudo = function() return "pseudo" end,
  } },
  dispatch = function(value)
    if failMove then return { ok = false, error = "move failed" } end
    moves[#moves + 1] = value
    return { ok = true }
  end,
})

local function reset()
  saved, active, connected, windows = nil, { primary, secondary }, { primary, secondary }, {}
  bindings, bindingOptions, notifications, rules, moves, failMove = {}, {}, {}, {}, {}, false
end
local function switch() bindings["SUPER + P"]() end
local function workspace(name, monitor, special)
  return { name = name, monitor = monitor, special = special or false }
end

reset()
windows = {
  { mapped = true, workspace = workspace("2", primary) },
  { mapped = true, workspace = workspace("12", secondary) },
  { mapped = true, workspace = workspace("special:notes", primary, true) },
}
profiles.setup(configs)
assert(#rules == 2 and bindings["SUPER + P"])
assert(bindingOptions["SUPER + P"].description == "Cycle monitor profiles")
switch()
assert(saved == "Second" and #moves == 1 and moves[1].workspace == "12")
assert(rules[3].output == "HDMI-A-1" and rules[3].position == "0x0")
assert(rules[4].output == "DP-2" and rules[4].disabled)
assert(notifications[#notifications].text:match("Second"))

active = { secondary }
profiles.setup(configs)
assert(rules[#rules - 1].output == "HDMI-A-1" and rules[#rules].disabled)
switch()
assert(saved == "Both" and #moves == 1)
assert(rules[#rules - 1].output == "DP-2" and not rules[#rules - 1].disabled)
assert(rules[#rules].position == "2560x240")

reset()
profiles.setup(configs)
connected = { primary }
switch()
assert(saved == nil and #rules == 2 and notifications[#notifications].text:match("not connected"))

reset()
local third = { name = "Available third", monitors = configs[1].monitors }
local missing = { name = "Missing", monitors = { { output = "missing", disabled = false } } }
profiles.setup({ configs[1], missing, third })
switch()
assert(saved == "Available third" and notifications[#notifications].text:match("Available third"))

reset()
local other = { id = 3, name = "OTHER" }
active = { primary, secondary, other }
windows = { { mapped = true, workspace = workspace("custom", other) } }
profiles.setup(configs)
switch()
assert(saved == "Second" and #moves == 0)

reset()
profiles.setup(configs)
windows = { { mapped = true, workspace = workspace("custom", primary) } }
switch()
assert(saved == nil and #moves == 0 and notifications[#notifications].text:match("unmapped workspace"))

reset()
profiles.setup(configs)
windows = { { mapped = true, workspace = workspace("1", primary) } }
failMove = true
switch()
assert(saved == nil and #rules == 2 and notifications[#notifications].text:match("move failed"))

reset()
profiles.setup(configs)
active = { primary }
switch()
assert(saved == nil and notifications[#notifications].text:match("target must already be active"))

reset()
profiles.setup({ configs[1] })
assert(bindings["SUPER + P"] == "pseudo" and #rules == 2)
assert(bindingOptions["SUPER + P"].description == "Toggle pseudo-tile")

local pluginGlobals = { monitor_priorities = {} }
package.loaded["plugins.split-monitor-workspaces.lua.globals"] = pluginGlobals
package.loaded["plugins.split-monitor-workspaces"] = {
  setup = function(config) assert(config.monitor_priority == monitorProfilePriority) end,
  get_amount_of_workspaces = function() return 10 end,
  workspace = function() return function() end end,
  move_to_workspace_silent = function() return function() end end,
}
monitorProfilePriority = { "DP-2", "HDMI-A-1" }
hl.dsp.workspace = { toggle_special = function() return function() end end }
dofile("modules/home/features/desktop/hyprland/config/binds/workspaces.lua")
assert(pluginGlobals.monitor_priorities["DP-2"].value == 0)
assert(pluginGlobals.monitor_priorities["HDMI-A-1"].value == 1)
assert(pluginGlobals.monitor_priorities["DP-2"].from_config)

os.getenv, io.open = originalGetenv, originalOpen
print("Hyprland monitor profile tests passed")
