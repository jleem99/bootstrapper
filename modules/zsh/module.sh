#!/bin/bash
set -euo pipefail

log_info "Running zsh module..."

ensure_packages_installed "zsh" "curl" "git"

try_run "Set default shell to zsh" chsh -s "$(which zsh)"

# Install oh-my-zsh (non-interactively)
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
perl -pi -e 's/^plugins=\(/plugins=\(zsh-syntax-highlighting /' ~/.zshrc

# Install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
perl -pi -e 's/^plugins=\(/plugins=\(zsh-autosuggestions /' ~/.zshrc

# Install starship (setting POSIXLY_CORRECT to bypass shell compatibility check, and auto-confirming)
curl -sS https://starship.rs/install.sh | POSIXLY_CORRECT=1 sh -s -- --yes
if ! grep -q "starship init zsh" ~/.zshrc; then
  echo 'eval "$(starship init zsh)"' >> ~/.zshrc
fi

# Add bootstrapper to PATH
BIN_DIR="$HOME/.local/bin"

# Add to PATH
add_to_path "$BIN_DIR" zsh

log_success "zsh module completed successfully!"