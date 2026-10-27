local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local schemePath = configHome .. "/hypr/scheme/current.lua"
local file, message, code = io.open(schemePath, "r")
local scheme

if file then
  file:close()
  scheme = dofile(schemePath)
elseif code == 2 then
  scheme = { primary = "c2c1ff", onSurfaceVariant = "c8c5d1" }
else
  error("Cannot read Caelestia's Hyprland scheme: " .. message)
end

local function isColour(value)
  return type(value) == "string" and value:match("^%x%x%x%x%x%x$") ~= nil
end

assert(type(scheme) == "table" and isColour(scheme.primary) and isColour(scheme.onSurfaceVariant),
  "Caelestia's Hyprland scheme has invalid border colours")

hl.config({
  general = {
    col = {
      active_border = "rgba(" .. scheme.primary .. "e6)",
      inactive_border = "rgba(" .. scheme.onSurfaceVariant .. "11)",
    },
  },
})
