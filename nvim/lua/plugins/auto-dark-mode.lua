-- Follow macOS system appearance: light system → background=light (tokyonight-day),
-- dark system → background=dark (tokyonight). Switches live while nvim is running.
return {
  "f-person/auto-dark-mode.nvim",
  opts = {
    update_interval = 3000,
    set_dark_mode = function()
      vim.o.background = "dark"
    end,
    set_light_mode = function()
      vim.o.background = "light"
    end,
  },
}
