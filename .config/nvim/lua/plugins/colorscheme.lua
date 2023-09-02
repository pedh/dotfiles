return {
  -- add zenburn
  {
    "phha/zenburn.nvim",
    lazy = true,
    init = function(_)
      local c = require("zenburn.palette")
      local hl = require("zenburn.highlights")
      local alpha_hl = {
        AlphaButtons = c.Function,
        AlphaFooter = c.Comment,
        AlphaHeader = c.Comment,
        AlphaHeaderLabel = c.Label,
        AlphaShortcut = c.Number,
      }
      table.insert(hl, alpha_hl)
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
