-- Caelestia writes the selected palette to ~/.config/hypr/scheme/current.lua.
-- This module consumes it and provides a reload-safe fallback.
local M = {}
local ok, scheme = pcall(require, "scheme.current")
if not ok or type(scheme) ~= "table" then
  scheme = {
    primary = "e06c75",
    onPrimary = "ffffff",
    surface = "1e2127",
    onSurface = "abb2bf",
    surfaceContainer = "1e2127",
    onSurfaceVariant = "abb2bf",
    outline = "5c6370",
  }
end
local function colour(value, fallback)
  if type(value) == "string" and #value > 0 then
    return "rgb(" .. value .. ")"
  end
  return fallback
end
function M.apply()
  local active = colour(scheme.primary, "rgba(88888888)")
  local inactive = colour(scheme.outline, "rgba(00000088)")
  hl.config({
    general = {
      col = { active_border = active, inactive_border = inactive },
    },
  })
end
M.apply()
return M
