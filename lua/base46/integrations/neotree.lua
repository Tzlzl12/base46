local theme = require("base46.utils").get_theme_tb "base_16"
local colors = require("base46.utils").get_theme_tb "base_30"

return {
  -- Directory and file icons
  NeoTreeDirectoryIcon = { fg = colors.folder_bg },
  NeoTreeDirectoryName = { fg = colors.blue },
  NeoTreeRootName = { fg = colors.blue, bold = true },
  -- NeoTreeFileName = { fg = colors.white },
  -- NeoTreeFileIcon = { fg = colors.light_grey },

  -- Git status
  NeoTreeGitAdded = { fg = colors.green },
  NeoTreeGitConflict = { fg = colors.red },
  NeoTreeGitDeleted = { fg = colors.red },
  NeoTreeGitIgnored = { fg = colors.grey_fg },
  NeoTreeGitModified = { fg = colors.yellow },
  NeoTreeGitUnstaged = { fg = colors.orange },
  NeoTreeGitUntracked = { fg = colors.purple },
  NeoTreeGitStaged = { fg = colors.green },

  -- Indent markers
  NeoTreeIndentMarker = { fg = colors.grey_fg2 },

  -- Expand/collapse arrows
  NeoTreeExpander = { fg = colors.grey_fg },

  -- Floating window border
  NeoTreeFloatBorder = { fg = colors.blue },
  NeoTreeFloatTitle = { fg = colors.blue, bold = true },

  -- Title bar
  NeoTreeTitleBar = { fg = colors.black, bg = colors.blue, bold = true },

  -- Symbol highlights
  NeoTreeSymbolicLinkTarget = { fg = colors.cyan },

  -- Modified flag
  NeoTreeModified = { fg = colors.yellow },

  -- Hidden items
  NeoTreeHiddenByName = { fg = colors.grey_fg },
}
