local M = {}
local g = vim.g
local utils = require "base46.utils"

function M.setup(user_opts)
  require("base46.config").setup(user_opts)
end

function M.compile()
  local base_cache_path = vim.g.base46_cache
  local themes = utils.list_themes()

  for _, theme_name in ipairs(themes) do
    -- Create per-theme cache directory
    local theme_cache_path = base_cache_path .. theme_name .. "/"
    if not vim.uv.fs_stat(theme_cache_path) then
      vim.fn.mkdir(theme_cache_path, "p")
    end

    -- Generate term file for this theme
    local term_str = utils.generate_term_str(theme_name)
    utils.str_to_cache(theme_cache_path .. "term", term_str)

    -- Generate colors file for this theme
    local colors_str = utils.generate_colors_str(theme_name)
    utils.str_to_cache(theme_cache_path .. "colors", colors_str)

    -- Generate integration files for this theme
    local ints = utils.get_integrations()
    for _, name in ipairs(ints) do
      local highlights = require("base46.integrations." .. name)
      highlights = utils.extend_default_hl_by_theme(highlights, name, theme_name)
      local hl_str = utils.tb_2str(highlights)

      if name == "defaults" then
        hl_str = "vim.o.tgc=true vim.o.bg='" .. utils.get_theme_tb_by_name(theme_name, "type") .. "' " .. hl_str
      end

      utils.str_to_cache(theme_cache_path .. name, hl_str)
    end
  end
end

function M.load_all_highlights()
  require("plenary.reload").reload_module "base46"
  -- M.compile()

  local config = require "base46.config"
  local opts = config.get_options()
  local theme_cache_path = vim.g.base46_cache .. opts.theme .. "/"

  local ints = utils.get_integrations()
  for _, name in ipairs(ints) do
    dofile(theme_cache_path .. name)
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
