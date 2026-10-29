local M = {}

local function notify(message, error)
  hl.notification.create({
    text = "Monitor profiles: " .. message,
    duration = 5000,
    icon = error and "error" or "info",
  })
end

local function apply(profile)
  for _, monitor in ipairs(profile.monitors) do
    if not monitor.disabled then hl.monitor(monitor) end
  end
  for _, monitor in ipairs(profile.monitors) do
    if monitor.disabled then hl.monitor({ output = monitor.output, disabled = true }) end
  end
end

local function merge_windows(profile, active)
  local disabled = {}
  for _, monitor in ipairs(profile.monitors) do
    if monitor.disabled then disabled[monitor.output] = true end
  end

  local removed = {}
  for _, monitor in ipairs(active) do
    if disabled[monitor.name] then removed[#removed + 1] = monitor end
  end
  if #removed == 0 then return true end
  if not profile.mergeTo then
    return false, "This profile needs a mergeTo output before disabling an active monitor."
  end

  local mappings = require("plugins.split-monitor-workspaces.lua.globals").monitor_workspace_map
  local target
  for _, monitor in ipairs(active) do
    if monitor.name == profile.mergeTo then target = mappings[monitor.id] end
  end
  if not target then
    return false, "The merge target must already be active and have mapped workspaces."
  end

  local destinations = {}
  for _, monitor in ipairs(removed) do
    local source = mappings[monitor.id]
    if not source or #source ~= #target then
      return false, "Cannot merge monitors with missing or different workspace mappings."
    end
    for i, workspace in ipairs(source) do destinations[workspace] = target[i] end
  end

  local moves = {}
  for _, window in ipairs(hl.get_windows()) do
    local workspace = window.workspace
    if window.mapped and workspace and not workspace.special then
      local destination = destinations[workspace.name]
      if destination then
        moves[#moves + 1] = { window = window, destination = destination }
      elseif workspace.monitor and disabled[workspace.monitor.name] then
        return false, "A window is on an unmapped workspace; move it before switching."
      end
    end
  end

  for _, move in ipairs(moves) do
    local result = hl.dispatch(hl.dsp.window.move({
      window = move.window,
      workspace = move.destination,
      follow = false,
    }))
    if not result.ok then
      return false, "Could not move a window; earlier windows may have moved: " .. (result.error or "unknown error")
    end
  end
  return true
end

function M.setup(profiles)
  assert(#profiles > 0, "At least one monitor profile is required")
  if #profiles == 1 then
    apply(profiles[1])
    hl.bind("SUPER + P", hl.dsp.window.pseudo(), { description = "Toggle pseudo-tile" })
    return
  end

  local runtime = assert(os.getenv("XDG_RUNTIME_DIR"), "XDG_RUNTIME_DIR is required for monitor profiles")
  local signature = assert(os.getenv("HYPRLAND_INSTANCE_SIGNATURE"), "Hyprland instance signature is required")
  local statePath = runtime .. "/hypr/" .. signature .. "/monitor-profile"
  local selected = 1
  local state, readError, readCode = io.open(statePath, "r")
  if state then
    local saved = state:read("*l")
    state:close()
    local found = false
    for i, profile in ipairs(profiles) do
      if profile.name == saved then selected, found = i, true; break end
    end
    if not found then notify("Saved profile no longer exists; using " .. profiles[1].name, true) end
  elseif readCode ~= 2 then
    notify("Could not read the selected profile: " .. tostring(readError), true)
  end

  apply(profiles[selected])
  hl.bind("SUPER + P", function()
    local connected = {}
    for _, monitor in ipairs(hl.get_monitors({ all = true })) do connected[monitor.name] = true end
    local nextIndex, missing
    for offset = 1, #profiles - 1 do
      local candidate = (selected - 1 + offset) % #profiles + 1
      local absent
      for _, monitor in ipairs(profiles[candidate].monitors) do
        if not monitor.disabled and not connected[monitor.output] then
          absent = monitor.output
          break
        end
      end
      if not absent then nextIndex = candidate; break end
      missing = profiles[candidate].name .. ": " .. absent .. " is not connected"
    end
    if not nextIndex then
      notify("No other profile is available (" .. missing .. ").", true)
      return
    end
    local profile = profiles[nextIndex]

    local ok, err = merge_windows(profile, hl.get_monitors())
    if not ok then
      notify(err, true)
      return
    end
    local file, openError = io.open(statePath, "w")
    if not file then
      notify("Could not save the selected profile; windows may have moved: " .. tostring(openError), true)
      return
    end
    local written, writeError = file:write(profile.name, "\n")
    local closed, closeError = file:close()
    if not written or not closed then
      notify("Could not save the selected profile; windows may have moved: " .. tostring(writeError or closeError), true)
      return
    end
    selected = nextIndex
    apply(profile)
    notify(profile.name, false)
  end, { description = "Cycle monitor profiles" })
end

return M
