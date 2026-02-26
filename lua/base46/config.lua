local M = {}

M.defaults = {
  theme = "onedark",
  integrations = {},
  excluded = {},
  transparency = true,
  hl_override = {},
  changed_themes = {},
  theme_toggle = { "onedark", "chad" },
}

M.options = nil

M.setup = function(user_opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_opts or {})

  -- if not vim.g.base46_cache then
  --   vim.g.base46_cache = vim.fn.stdpath("data") .. "/base46/cache/"
  -- end
end

M.get_options = function()
  if not M.options then
    M.setup()
  end
  return M.options
end

return M
