#!/bin/bash
set -euo pipefail

log_info "Installing basic packages..."

# Run platform-specific implementation
module_run_platform "basic-packages"

# Configure tmux
log_info "Configuring tmux..."
echo 'setw -g mouse on' >> ~/.tmux.conf

# Setup neovim
log_info "Setting up neovim..."

if [ ! -d ~/.config/nvim ]; then
  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git

  cat <<EOF > ~/.config/nvim/lua/config/keymaps.lua
-- Map <CR> to ciw in normal mode
vim.keymap.set('n', '<CR>', 'ciw', { noremap = true, silent = true, desc = "Change inner word" })

-- Map ; to : in normal and visual modes
vim.keymap.set({ 'n', 'v' }, ';', ':', { noremap = true, silent = false, desc = "Map ; to :" })

-- Map %% in command-line mode to expand('%:p:h').'/'
vim.keymap.set('c', '%%', "<C-R>=expand('%:p:h').'/'<CR>", { noremap = true, silent = true, desc = "Expand current file path in command-line mode" })
EOF
fi

log_success "Basic packages installed successfully!" 