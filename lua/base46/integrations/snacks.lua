local colors = require("base46.utils").get_theme_tb "base_30"

local highlights = {
  -- 基础：全部设为透明
  SnacksNormal = { bg = "none", fg = colors.white },
  SnacksNormalNC = { bg = "none", fg = colors.white },
  SnacksBackdrop = { bg = "none" }, -- 遮罩层透明

  -- Picker (搜索/选择器) - 保持极简透明
  SnacksPicker = { bg = "none" },
  SnacksPickerBorder = { fg = colors.blue, bg = "none" },
  SnacksPickerTitle = { fg = colors.blue, bg = "none", bold = true },
  SnacksPickerList = { bg = "none" },
  SnacksPickerMatch = { fg = colors.orange, bold = true }, -- 搜索匹配项高亮

  -- Dashboard (启动界面)
  SnacksDashboardHeader = { fg = colors.red, bg = "none" },
  SnacksDashboardFooter = { fg = colors.grey, bg = "none" },
  SnacksDashboardAction = { fg = colors.green, bg = "none" },
  SnacksDashboardKey = { fg = colors.orange, bg = "none" },

  -- Input (输入框) - 建议保留微弱的背景色以区分，或只用边框
  SnacksInput = { bg = "none", fg = colors.white },
  SnacksInputBorder = { fg = colors.green, bg = "none" },
  SnacksInputTitle = { fg = colors.green, bg = "none" },

  -- Indent (缩进线)
  SnacksIndent = { fg = colors.black2 }, -- 缩进线通常不需要背景
  SnacksIndentScope = { fg = colors.blue },

  -- Notifier (通知)
  SnacksNotifierNormal = { bg = "none", fg = colors.white },
  SnacksNotifierBorder = { fg = colors.purple, bg = "none" },
}

return highlights
