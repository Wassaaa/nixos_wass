local themeFile = "modules/home/features/desktop/hyprland/config/theme.lua"
local schemePath = "/test/config/hypr/scheme/current.lua"
local originalGetenv, originalOpen, originalDofile = os.getenv, io.open, dofile
local scenario, result

os.getenv = function(name)
  if name == "XDG_CONFIG_HOME" then return "/test/config" end
  return originalGetenv(name)
end

io.open = function(path, mode)
  assert(path == schemePath and mode == "r")
  if scenario == "missing" then return nil, "not found", 2 end
  if scenario == "unreadable" then return nil, "permission denied", 13 end
  return { close = function() end }
end

dofile = function(path)
  assert(path == schemePath)
  if scenario == "invalid" then return { primary = "bad" } end
  return { primary = scenario, onSurfaceVariant = "abcdef" }
end

hl = {
  config = function(config) result = config end,
}

scenario = "missing"
originalDofile(themeFile)
assert(result.general.col.active_border == "rgba(c2c1ffe6)")
assert(result.general.col.inactive_border == "rgba(c8c5d111)")

scenario = "123456"
originalDofile(themeFile)
assert(result.general.col.active_border == "rgba(123456e6)")
assert(result.general.col.inactive_border == "rgba(abcdef11)")

scenario = "654321"
originalDofile(themeFile)
assert(result.general.col.active_border == "rgba(654321e6)")

scenario = "invalid"
local ok, err = pcall(originalDofile, themeFile)
assert(not ok and err:match("invalid border colours"))

scenario = "unreadable"
ok, err = pcall(originalDofile, themeFile)
assert(not ok and err:match("permission denied"))

os.getenv, io.open, dofile = originalGetenv, originalOpen, originalDofile
print("Hyprland theme tests passed")
