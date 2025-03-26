#!/bin/bash
set -eu

log_info "Running zsh module..."

ensure_packages_installed "zsh" "curl" "git"

chsh -s $(which zsh)

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sed -i 's/^plugins=(/plugins=(zsh-syntax-highlighting /' ~/.zshrc

# Install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed -i 's/^plugins=(/plugins=(zsh-autosuggestions /' ~/.zshrc

# Add bootstrapper to PATH
BIN_DIR="$HOME/.local/bin"

# Add to PATH
add_to_path "zsh" "$BIN_DIR"

log_success "zsh module completed successfully!"