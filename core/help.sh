#!/bin/bash
set -eu

# Source platform detection if PLATFORM is not set
if [[ -z "$PLATFORM" ]]; then
  source "$BOOTSTRAPPER_ROOT/core/_platform.sh"
fi

# Source required utilities
source "$BOOTSTRAPPER_ROOT/core/_logging.sh"

# Function to display help information
show_help() {
  log_info "Bootstrapper - A cross-platform tool to streamline environment setup"
  log_info ""
  log_info "Usage:"
  log_info "  bootstrapper <command> [arguments]"
  log_info ""
  log_info "Commands:"
  log_info "  init <shell>    Initialize bootstrapper for the specified shell"
  log_info "                 Supported shells: bash, zsh, fish"
  log_info "  help            Display this help message"
  log_info "  version         Display version information"
  log_info "  <module> ...    Bootstrap one or more modules"
  log_info ""
  log_info "Examples:"
  log_info "  bootstrapper init zsh             # Initialize for Zsh shell"
  log_info "  bootstrapper basic-packages       # Install basic packages"
  log_info "  bootstrapper colmap vnc-server    # Install multiple modules"
  log_info ""
  log_info "Available modules:"
  
  # List available modules
  for module_dir in "$BOOTSTRAPPER_ROOT/modules"/*/; do
    if [[ -d "$module_dir" ]]; then
      module_name=$(basename "$module_dir")
      if [[ -f "$module_dir/module.sh" ]]; then
        # Get module description if available
        description=$(grep "^# Description:" "$module_dir/module.sh" | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "No description available")
        
        # Check if module is supported on current platform
        if [[ -f "$module_dir/$PLATFORM.sh" ]]; then
          log_success "$module_name"
          log_info "  $description"
        else
          log_warning "$module_name (not supported on current platform)"
        fi
      fi
    fi
  done
}

# Export the help function
export -f show_help

# Show help if this script is run directly or sourced with help command
if [[ "${BASH_SOURCE[0]:-}" == "${0:-}" ]] || [[ "${1:-}" == "help" ]]; then
  show_help
fi 