local M = {}
local g = vim.g
local utils = require "base46.utils"

M.override_theme = utils.override_theme
M.list_themes = utils.list_themes

function M.setup(user_opts)
  require("base46.config").setup(user_opts)
end

function M.compile()
  local base_cache_path = vim.g.base46_cache
  local themes = utils.list_themes()
  local ints = utils.get_integrations()

  for _, theme_name in ipairs(themes) do
    -- 先设置编译主题名，再清除其他模块缓存
    utils.set_compile_theme(theme_name)

    -- 清除所有集成模块缓存，确保每个主题使用正确的颜色值
    for _, int_name in ipairs(ints) do
      package.loaded["base46.integrations." .. int_name] = nil
    end
    -- 不清除 utils 缓存，保留 compile_theme 变量
    package.loaded["base46.config"] = nil
    package.loaded["base46.themes." .. theme_name] = nil

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

  -- 编译完成后清除编译主题名
  utils.clear_compile_theme()
end

function M.load_all_highlights(theme_name)
  if not theme_name then
    theme_name = utils.get_cached_theme()
  end

  local kind = utils.get_theme_tb_by_name(theme_name, "type")
  vim.o.background = kind

  local theme_cache_path = vim.g.base46_cache .. theme_name .. "/"

  local ints = utils.get_integrations()
  for _, name in ipairs(ints) do
    -- print("load " .. theme_cache_path .. name)
    dofile(theme_cache_path .. name)
  end

  dofile(theme_cache_path .. "term")
  dofile(theme_cache_path .. "colors")

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

return M
