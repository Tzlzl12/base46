local M = {}

M.defaults = {
  theme = "chad",
  integrations = {},
  excluded = {},
  transparency = false,
  hl_override = {},
  changed_themes = {},
  theme_toggle = { "chad", "onedark" },
}

M.options = vim.deepcopy(M.defaults)

M.setup = function(user_opts)
  M.options = vim.tbl_deep_extend("force", M.options, user_opts or {})

  vim.g.base46_cache = vim.g.base46_cache
    or (vim.fn.stdpath("data") .. "/site/pack/vendor/start/base46/nvim-base46/compiled")
end

return M
