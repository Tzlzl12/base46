local M = {}

local function tbval_index(tb, val)
  for i, v in ipairs(tb) do
    if v == val then
      return i
    end
  end
end

local integrations = {
  "flash",
  "lsp",
  "notify",
  "render-markdown",
  "trouble",
  "codeactionmenu",
  "semantic_tokens",
  "whichkey",
  "dap",
  "git",
  "mason",
  "syntax",
  "blink-pair",
  "defaults",
  "todo",
  "blink",
  "rainbowdelimiters",
  "treesitter",
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

function M.get_theme_tb(type)
  local config = require "base46.config"
  local opts = config.get_options()
  local name = opts.theme
  -- local name = vim.fn.readfile(vim.fn.stdpath "data" .. "/colorscheme")[1] or opts.theme
  local present1, default_theme = pcall(require, "base46.themes." .. name)
  local present2, user_theme = pcall(require, "themes." .. name)

  if present1 then
    return default_theme[type]
  elseif present2 then
    return user_theme[type]
  else
    error("No such theme: " .. name)
  end
end

local lighten = require("base46.colors").change_hex_lightness
local mixcolors = require("base46.colors").mix

function M.turn_str_to_color(tb)
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

function M.str_to_cache(filename, str)
  local cache_path = vim.g.base46_cache
  local lines = "return string.dump(function()" .. str .. "end, true)"
  local file = io.open(cache_path .. filename, "wb")

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

