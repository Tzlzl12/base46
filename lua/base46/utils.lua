local M = {}
local compile_theme = nil
local current_compile_theme = nil

local function tbval_index(tb, val)
  for i, v in ipairs(tb) do
    if v == val then
      return i
    end
  end
end

local integrations = {
  "blink",
  "blink-pair",
  "codeactionmenu",
  "dap",
  "defaults",
  "flash",
  "git",
  "lsp",
  "mason",
  "notify",
  "render-markdown",
  "rainbowdelimiters",
  "semantic_tokens",
  "syntax",
  "todo",
  "treesitter",
  "trouble",
  "whichkey",
}

function M.get_integrations()
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

function M.merge_tb(...)
  return vim.tbl_deep_extend("force", ...)
end

function M.get_cached_theme()
  local theme_name = nil
  local file = vim.fn.stdpath "data" .. "/colorscheme"
  if vim.uv.fs_stat(file) then
    theme_name = vim.fn.readfile(file)[1]
  end

  if not theme_name then
    theme_name = "onedark"
  end

  return theme_name
end

function M.change_cached_theme(theme_name)
  local colorscheme_cache = vim.fs.joinpath(vim.fn.stdpath "data", "colorscheme")
  local f = io.open(colorscheme_cache, "w")
  if f then
    f:write(theme_name)
    f:close()
  end
end

function M.get_theme_tb(type, theme_name)
  local config = require "base46.config"
  if not theme_name then
    theme_name = compile_theme or M.get_cached_theme()
  end

  return M.get_theme_tb_by_name(theme_name, type)
end

function M.set_compile_theme(theme_name)
  compile_theme = theme_name
end

function M.clear_compile_theme()
  compile_theme = nil
end

function M.get_theme_tb_by_name(theme_name, type)
  local present1, default_theme = pcall(require, "base46.themes." .. theme_name)
  local present2, user_theme = pcall(require, "themes." .. theme_name)

  if present1 then
    return default_theme[type]
  elseif present2 then
    return user_theme[type]
  else
    error("No such theme: " .. theme_name)
  end
end

local lighten = require("base46.colors").change_hex_lightness
local mixcolors = require("base46.colors").mix

local function turn_str_to_color_impl(tb, colors)
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

function M.turn_str_to_color(tb)
  local colors = vim.tbl_extend("force", M.get_theme_tb "base_30", M.get_theme_tb "base_16")
  return turn_str_to_color_impl(tb, colors)
end

function M.turn_str_to_color_by_theme(tb, theme_name)
  local base30 = M.get_theme_tb_by_name(theme_name, "base_30")
  local base16 = M.get_theme_tb_by_name(theme_name, "base_16")
  if not base30 or not base16 then
    return tb
  end
  local colors = vim.tbl_extend("force", base30, base16)
  return turn_str_to_color_impl(tb, colors)
end

function M.extend_default_hl(highlights, integration_name)
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

function M.extend_default_hl_by_theme(highlights, integration_name, theme_name)
  local config = require "base46.config"
  local opts = config.get_options()
  local polish_hl = M.get_theme_tb_by_name(theme_name, "polish_hl")

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
  local overriden_hl = M.turn_str_to_color_by_theme(hl_override, theme_name)

  for key, value in pairs(overriden_hl) do
    if highlights[key] then
      highlights[key] = M.merge_tb(highlights[key], value)
    end
  end

  return highlights
end

function M.generate_term_str(theme_name)
  local base16 = M.get_theme_tb_by_name(theme_name, "base_16")
  if not base16 then
    return ""
  end

  local term_colors = {
    base16.base00,
    base16.base08,
    base16.base0B,
    base16.base0A,
    base16.base0D,
    base16.base0E,
    base16.base0C,
    base16.base05,
    base16.base03,
    base16.base08,
    base16.base0B,
    base16.base0A,
    base16.base0D,
    base16.base0E,
    base16.base0C,
    base16.base07,
  }

  local result = ""
  for i, color in ipairs(term_colors) do
    result = result .. string.format("vim.g.terminal_color_%d='%s';", i - 1, color)
  end

  return result
end

function M.generate_colors_str(theme_name)
  local base30 = M.get_theme_tb_by_name(theme_name, "base_30")
  if not base30 then
    return ""
  end

  local result = "local colors={};"
  for name, color in pairs(base30) do
    result = result .. string.format("colors['%s']='%s';", name, color)
  end
  result = result .. "return colors;"

  return result
end

function M.tb_2str(tb)
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

function M.str_to_cache(filepath, str)
  local lines = "return string.dump(function()" .. str .. "end, true)"
  local file = io.open(filepath, "wb")

  if file then
    file:write(loadstring(lines)())
    file:close()
  end
end

function M.override_theme(default_theme, theme_name)
  local config = require "base46.config"
  local opts = config.get_options()
  local changed_themes = opts.changed_themes
  return M.merge_tb(default_theme, changed_themes.all or {}, changed_themes[theme_name] or {})
end

local fn = vim.fn

function M.list_themes()
  local plugin_path = debug.getinfo(M.list_themes, "S").source:sub(2):match "^(.*)/utils%.lua$"
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
