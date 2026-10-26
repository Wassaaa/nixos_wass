-- Explicit palettes inspired by the pinned fufexan configuration.
local M = {}
local palettes = {
  dark = {
    active = "rgba(88888888)", inactive = "rgba(00000088)",
    text = "rgb(000000)", text_inactive = "rgba(ffffff66)",
    group_active = "rgba(ffffff66)", group_inactive = "rgba(00000066)",
  },
  light = {
    active = "rgb(000000)", inactive = "rgba(00000000)",
    text = "rgb(ffffff)", text_inactive = "rgba(00000066)",
    group_active = "rgba(00000066)", group_inactive = "rgba(ffffff66)",
  },
}
function M.apply(mode)
  local p = palettes[mode] or palettes.dark
  hl.config({
    general = { col = { active_border = p.active, inactive_border = p.inactive } },
    group = {
      col = { border_active = p.active, border_inactive = p.inactive },
      groupbar = {
        font_size = 12, font_weight_active = "bold", gradients = false,
        height = 20, indicator_height = 20, rounding = 10, rounding_power = 2.5,
        text_color = p.text, text_color_inactive = p.text_inactive, text_offset = -20,
        col = { active = p.group_active, inactive = p.group_inactive },
      },
    },
  })
end
local stateHome = os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "") .. "/.local/state")
local state = io.open(stateHome .. "/wass-desktop/theme", "r")
local mode = "dark"
if state then
  mode = state:read("*l") or mode
  state:close()
end
M.apply(mode)
return M
