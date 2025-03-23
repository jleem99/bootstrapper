#!/bin/bash
set -eu

log_info "Setting up SSH server..."

# Define supported platforms
SUPPORTED_PLATFORMS=("debian" "rhel" "fedora" "macos")

# Check if platform is supported
check_platform_supported "${SUPPORTED_PLATFORMS[@]}"

# Run platform-specific implementation
run_platform_module "ssh-server"

# Verify SSH server installation
if command -v sshd &> /dev/null; then
  log_success "SSH server installed successfully!"
  
  # Print SSH server status if possible
  case "$PLATFORM" in
    debian|ubuntu)
      systemctl status ssh | head -n 3
      ;;
    rhel|fedora|centos)
      systemctl status sshd | head -n 3
      ;;
    macos)
      echo "Use 'sudo systemsetup -getremotelogin' to check SSH status"
      ;;
  esac
else
  log_error "SSH server installation could not be verified."
  exit 1
fi

# Get the IP address
if [[ "$PLATFORM_FAMILY" == "linux" ]]; then
  IP_ADDRESS=$(hostname -I | awk '{print $1}')
elif [[ "$PLATFORM" == "macos" ]]; then
  IP_ADDRESS=$(ipconfig getifaddr en0)
fi

log_success "SSH server setup completed successfully!"
log_info "You can connect to this machine using: ssh $USER@$IP_ADDRESS"
log_info "If you created a new SSH key, add it to your remote machine using:"
log_info "ssh-copy-id $USER@<remote-ip-address>" 