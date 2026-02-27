local M = {}
local g = vim.g
local utils = require "base46.utils"

function M.setup(user_opts)
  require("base46.config").setup(user_opts)
end

function M.compile()
  local cache_path = vim.g.base46_cache
  if not vim.uv.fs_stat(cache_path) then
    vim.fn.mkdir(cache_path, "p")
  end

  utils.str_to_cache("term", require "base46.term")
  utils.str_to_cache("colors", require "base46.color_vars")

  local ints = utils.get_integrations()
  for _, name in ipairs(ints) do
    local highlights = require("base46.integrations." .. name)
    highlights = utils.extend_default_hl(highlights, name)
    local hl_str = utils.tb_2str(highlights)

    if name == "defaults" then
      hl_str = "vim.o.tgc=true vim.o.bg='" .. utils.get_theme_tb "type" .. "' " .. hl_str
    end

    utils.str_to_cache(name, hl_str)
  end
end

function M.load_all_highlights()
  require("plenary.reload").reload_module "base46"
  M.compile()

  local ints = utils.get_integrations()
  for _, name in ipairs(ints) do
    dofile(vim.g.base46_cache .. name)
  end

  pcall(function()
    require("ibl").update()
  end)

  vim.api.nvim_exec_autocmds("User", { pattern = "NvThemeReload" })
end

function M.toggle_theme()
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

function M.toggle_transparency()
  local config = require "base46.config"
  local opts = config.get_options()
  opts.transparency = not opts.transparency
  config.options = opts
  M.load_all_highlights()
end

return M