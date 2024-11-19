return {
  -- add zenburn
  {
    "phha/zenburn.nvim",
    lazy = true,
    init = function(_)
      local c = require("zenburn.palette")
      local hl = require("zenburn.highlights")
      local dashboard_hl = {
        SnacksDashboardHeader = c.Comment,
        SnacksDashboardFooter = c.Comment,
        SnacksDashboardDesc = c.Identifier,
        SnacksDashboardKey = c.Number,
        SnacksDashboardIcon = c.Identifier,
        SnacksDashboardShortCut = c.Function,
      }
      table.insert(hl, dashboard_hl)
    end,
  },

  -- Configure LazyVim to load zenburn
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "zenburn",
    },
  },

  --- Configure lualine theme to zenburn
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "zenburn",
      },
    },
  },
}
