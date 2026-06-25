#!/bin/bash
set -euo pipefail

ensure_homebrew

# neovim, ripgrep (rg), fd, git — all match brew formula names directly
install_packages "neovim" "ripgrep" "fd" "git"
