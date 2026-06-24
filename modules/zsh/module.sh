#!/bin/bash
set -euo pipefail

log_info "Running zsh module..."

ensure_packages_installed "zsh" "curl" "git"

try_run "Set default shell to zsh" chsh -s "$(which zsh)"

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
sed -i 's/^plugins=(/plugins=(zsh-syntax-highlighting /' ~/.zshrc

# Install zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed -i 's/^plugins=(/plugins=(zsh-autosuggestions /' ~/.zshrc

# Install starship
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init '$(get_current_shell)')"' >> "$(get_shell_profile)"

# Add bootstrapper to PATH
BIN_DIR="$HOME/.local/bin"

# Add to PATH
add_to_path "$BIN_DIR" zsh

log_info "Configuring /etc/zshenv..."
sudo touch /etc/zshenv
grep -qxF 'ZDOTDIR=$HOME' /etc/zshenv || echo 'ZDOTDIR=$HOME' | sudo tee -a /etc/zshenv > /dev/null

if ! grep -qxF 'LANG=en_US.UTF-8' /etc/default/locale 2>/dev/null; then
  log_info "Generating en_US.UTF-8 locale..."
  sudo locale-gen en_US.UTF-8
  sudo update-locale LANG=en_US.UTF-8
fi

log_success "zsh module completed successfully!"