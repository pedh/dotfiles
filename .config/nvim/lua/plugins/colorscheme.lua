return {
  -- add zenburn
  {
    "phha/zenburn.nvim",
    lazy = true,
    init = function(_)
      local c = require("zenburn.palette")
      local hl = require("zenburn.highlights")
      local dashboard_hl = {
        DashboardHeader = c.Comment,
        DashboardFooter = c.Comment,
        DashboardDesc = c.Identifier,
        DashboardKey = c.Number,
        DashboardIcon = c.Identifier,
        DashboardShortCut = c.Function,
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
