-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Map <CR> to ciw in normal mode
vim.keymap.set("n", "<CR>", "ciw", { noremap = true, silent = true, desc = "Change inner word" })

-- Map ; to : in normal and visual modes
vim.keymap.set({ "n", "v" }, ";", ":", { noremap = true, silent = false, desc = "Map ; to :" })

-- Map %% in command-line mode to expand('%:p:h').'/'
vim.keymap.set(
  "c",
  "%%",
  "<C-R>=expand('%:p:h').'/'<CR>",
  { noremap = true, silent = true, desc = "Expand current file path in command-line mode" }
)
