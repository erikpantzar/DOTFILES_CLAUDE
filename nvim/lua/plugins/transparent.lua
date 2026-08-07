-- Let the terminal (Warp) background/blur show through instead of nvim
-- painting its own opaque background.
return {
  "folke/tokyonight.nvim",
  opts = {
    transparent = true,
    styles = {
      sidebars = "transparent",
      floats = "transparent",
    },
  },
}
