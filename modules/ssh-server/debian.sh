#!/bin/bash
set -euo pipefail

log_info "Setting up SSH server for Debian/Ubuntu..."

SSHD_CONFIG_FILE=/etc/ssh/sshd_config
SSHD_PORT=22
SSH_CONFIG_ROOT_DIR="$HOME/.ssh"

# Install OpenSSH server
sudo apt-get update
sudo apt-get install -y openssh-server

# Enable and start SSH service
sudo systemctl enable ssh
sudo systemctl start ssh

# Allow SSH through firewall
if command -v ufw &> /dev/null; then
  sudo ufw allow ssh
  log_info "SSH allowed through UFW firewall"
fi

# Basic SSH server hardening
log_info "Configuring SSH server for enhanced security..."

# Backup current config
sudo cp "$SSHD_CONFIG_FILE" "$SSHD_CONFIG_FILE.bak"

# Modify SSH config
sudo sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG_FILE"
sudo sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG_FILE"
sudo sed -i 's/#Port.*/Port $SSHD_PORT/' "$SSHD_CONFIG_FILE"

# Add additional security settings
cat > /tmp/ssh_config_additional << EOF
# Additional security settings
Protocol 2
MaxAuthTries 3
PubkeyAuthentication yes
IgnoreRhosts yes
HostbasedAuthentication no
PermitEmptyPasswords no
X11Forwarding no
EOF

# Append additional config
sudo bash -c 'cat /tmp/ssh_config_additional >> "$SSHD_CONFIG_FILE"'

# Create SSH config directory if it doesn't exist
sudo mkdir -p "$SSH_CONFIG_ROOT_DIR"
sudo chmod 700 "$SSH_CONFIG_ROOT_DIR"

# # Ask to create SSH key if not exists
# if [ ! -f "$SSH_CONFIG_ROOT_DIR/id_rsa" ]; then
#   log_warning "No SSH key found. Creating one..."
#   ssh-keygen -t rsa -b 4096 -f "$SSH_CONFIG_ROOT_DIR/id_rsa"
# fi

# Restart SSH service to apply changes
sudo systemctl restart ssh
