local M = {}
local g = vim.g

local function tbval_index(tb, val)
  for i, v in ipairs(tb) do
    if v == val then
      return i
    end
  end
end

local integrations = {
  -- "blankline",
  -- "blink",
  -- "cmp",
  "defaults",
  -- "devicons",
  -- "git",
  -- "lsp",
  -- "mason",
  -- "nvcheatsheet",
  -- "nvimtree",
  -- "statusline",
  -- "syntax",
  -- "treesitter",
  -- "tbline",
  -- "telescope",
  -- "whichkey",
}

local function get_integrations()
  local config = require "base46.config"
  local opts = config.get_options()
  local result = vim.deepcopy(integrations)

  for _, value in ipairs(opts.integrations) do
    table.insert(result, value)
  end

  for _, value in ipairs(opts.excluded or {}) do
    local val_i = tbval_index(result, value)
    if val_i then
      table.remove(result, val_i)
    end
  end

  return result
end

M.setup = function(user_opts)
  require("base46.config").setup(user_opts)
end

M.get_theme_tb = function(type)
  local config = require "base46.config"
  local opts = config.get_options()
  local name = opts.theme
  vim.notify("Theme: " .. name)
  local present1, default_theme = pcall(require, "base46.themes." .. name)
  local present2, user_theme = pcall(require, "themes." .. name)

  if present1 then
    return default_theme[type]
  elseif present2 then
    return user_theme[type]
  else
    vim.notify("No such theme: " .. name)
  end
end

M.merge_tb = function(...)
  return vim.tbl_deep_extend("force", ...)
end

local lighten = require("base46.colors").change_hex_lightness
local mixcolors = require("base46.colors").mix

M.turn_str_to_color = function(tb)
  local colors = vim.tbl_extend("force", M.get_theme_tb "base_30", M.get_theme_tb "base_16")
  local copy = vim.deepcopy(tb)

  for _, hlgroups in pairs(copy) do
    for opt, val in pairs(hlgroups) do
      local valtype = type(val)

      if opt == "fg" or opt == "bg" or opt == "sp" then
        if valtype == "string" and val:sub(1, 1) ~= "#" and val ~= "none" and val ~= "NONE" then
          hlgroups[opt] = colors[val]
        elseif valtype == "table" then
          hlgroups[opt] = #val == 2 and lighten(colors[val[1]], val[2])
            or mixcolors(colors[val[1]], colors[val[2]], val[3])
        end
      end
    end
  end

  return copy
end

M.extend_default_hl = function(highlights, integration_name)
  local config = require "base46.config"
  local opts = config.get_options()
  local polish_hl = M.get_theme_tb "polish_hl"

  if polish_hl and polish_hl[integration_name] then
    highlights = M.merge_tb(highlights, polish_hl[integration_name])
  end

  if opts.transparency then
    local glassy = require "base46.glassy"

    for key, value in pairs(glassy) do
      if highlights[key] then
        highlights[key] = M.merge_tb(highlights[key], value)
      end
    end
  end

  local hl_override = opts.hl_override
  local overriden_hl = M.turn_str_to_color(hl_override)

  for key, value in pairs(overriden_hl) do
    if highlights[key] then
      highlights[key] = M.merge_tb(highlights[key], value)
    end
  end

  return highlights
end

M.get_integration = function(name)
  local highlights = require("base46.integrations." .. name)
  return M.extend_default_hl(highlights, name)
end

M.tb_2str = function(tb)
  local result = ""

  for hlgroupName, v in pairs(tb) do
    local hlname = "'" .. hlgroupName .. "',"
    local hlopts = ""

    for optName, optVal in pairs(v) do
      local valueInStr = ((type(optVal)) == "boolean" or type(optVal) == "number") and tostring(optVal)
        or '"' .. optVal .. '"'
      hlopts = hlopts .. optName .. "=" .. valueInStr .. ","
    end

    result = result .. "vim.api.nvim_set_hl(0," .. hlname .. "{" .. hlopts .. "})"
  end

  return result
end

M.str_to_cache = function(filename, str)
  local cache_path = vim.g.base46_cache
  local lines = "return string.dump(function()" .. str .. "end, true)"
  local file = io.open(cache_path .. filename, "wb")

  if file then
    file:write(loadstring(lines)())
    file:close()
  end
end

M.compile = function()
  local cache_path = vim.g.base46_cache
  if not vim.uv.fs_stat(cache_path) then
    vim.fn.mkdir(cache_path, "p")
  end

  M.str_to_cache("term", require "base46.term")
  M.str_to_cache("colors", require "base46.color_vars")

  local ints = get_integrations()
  for _, name in ipairs(ints) do
    local hl_str = M.tb_2str(M.get_integration(name))

    if name == "defaults" then
      hl_str = "vim.o.tgc=true vim.o.bg='" .. M.get_theme_tb "type" .. "' " .. hl_str
    end

    M.str_to_cache(name, hl_str)
  end
end

M.load_all_highlights = function()
  require("plenary.reload").reload_module "base46"
  M.compile()

  local ints = get_integrations()
  for _, name in ipairs(ints) do
    dofile(vim.g.base46_cache .. name)
  end

  pcall(function()
    require("ibl").update()
  end)

  vim.api.nvim_exec_autocmds("User", { pattern = "NvThemeReload" })
end

M.override_theme = function(default_theme, theme_name)
  local config = require "base46.config"
  local opts = config.get_options()
  local changed_themes = opts.changed_themes
  return M.merge_tb(default_theme, changed_themes.all or {}, changed_themes[theme_name] or {})
end

M.toggle_theme = function()
  local config = require "base46.config"
  local opts = config.get_options()
  local themes = opts.theme_toggle

  if opts.theme ~= themes[1] and opts.theme ~= themes[2] then
    vim.notify "Set your current theme to one of those mentioned in the theme_toggle table"
    return
  end

  g.icon_toggled = not g.icon_toggled
  g.toggle_theme_icon = g.icon_toggled and "  " or "  "

  opts.theme = (themes[1] == opts.theme and themes[2]) or themes[1]
  config.options = opts

  M.load_all_highlights()
end

M.toggle_transparency = function()
  local config = require "base46.config"
  local opts = config.get_options()
  opts.transparency = not opts.transparency
  config.options = opts
  M.load_all_highlights()
end

local fn = vim.fn

M.list_themes = function()
  local plugin_path = debug.getinfo(M.list_themes, "S").source:sub(2):match "^(.*)/init%.lua$"
  local default_themes = fn.readdir(plugin_path .. "/themes/")
  local custom_themes = vim.uv.fs_stat(fn.stdpath "config" .. "/lua/themes")

  if custom_themes and custom_themes.type == "directory" then
    local themes_tb = fn.readdir(fn.stdpath "config" .. "/lua/themes")
    for _, value in ipairs(themes_tb) do
      table.insert(default_themes, value)
    end
  end

  for index, theme in ipairs(default_themes) do
    default_themes[index] = theme:match "(.+)%..+"
  end

  return default_themes
end

return M
