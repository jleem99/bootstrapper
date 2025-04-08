#!/bin/bash
set -euo pipefail

# Source required utilities
source "$BOOTSTRAPPER_ROOT/core/_logging.sh"
source "$BOOTSTRAPPER_ROOT/core/_utils.sh"

# Function to perform the update
perform_update() {
  # Installation directory 
  INSTALL_DIR="$HOME/.local/share/bootstrapper"
  
  # Check if installation is a git repository
  if [[ ! -d "$BOOTSTRAPPER_ROOT/.git" ]]; then
    log_error "Not installed via git. Please reinstall using the official method:"
    log_info "curl -fsSL https://bootstrapper.jleem.com/install.sh | bash"
    return 1
  fi
  
  log_info "Updating bootstrapper..."
  
  # Save current directory
  CURRENT_DIR=$(pwd)
  
  # Navigate to installation directory
  cd "$BOOTSTRAPPER_ROOT"
  
  # Save any local changes
  log_info "Saving any local changes..."
  git stash -q || true
  
  # Fetch and update
  log_info "Fetching latest version..."
  git fetch origin -q || { log_error "Failed to fetch updates"; cd "$CURRENT_DIR"; return 1; }
  
  # Check for available updates
  LOCAL_REV=$(git rev-parse HEAD)
  REMOTE_REV=$(git rev-parse origin/main)
  
  if [[ "$LOCAL_REV" == "$REMOTE_REV" ]]; then
    log_success "Bootstrapper is already at the latest version!"
    cd "$CURRENT_DIR"
    return 0
  fi
  
  # Apply updates
  log_info "Applying updates..."
  git checkout origin/main -q || { log_error "Failed to apply updates"; cd "$CURRENT_DIR"; return 1; }
  
  # Run init script to ensure symlinks, etc. are updated
  log_info "Reinitializing bootstrapper..."
  "$BOOTSTRAPPER_ROOT/init.sh" || { log_error "Failed to reinitialize bootstrapper"; cd "$CURRENT_DIR"; return 1; }
  
  # Return to original directory
  cd "$CURRENT_DIR"
  
  # Display update success message
  log_success "Bootstrapper updated successfully!"
  "$BOOTSTRAPPER_ROOT/bootstrapper" version
  
  return 0
}

# Execute the update
perform_update 