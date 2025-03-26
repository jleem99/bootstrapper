#!/bin/bash
set -eu

# Function to get shell profile file
get_shell_profile() {
  local shell="$1"
  case "$shell" in
    "bash")
      echo "$HOME/.bashrc"
      ;;
    "zsh")
      echo "$HOME/.zshrc"
      ;;
    "fish")
      echo "$HOME/.config/fish/config.fish"
      ;;
    *)
      echo -e "${RED}Unsupported shell: $shell${NC}"
      exit 1
      ;;
  esac
}

# Function to add to PATH
add_to_path() {
  local shell="$1"
  local bin_dir="$2"
  local profile="$3"

  log_info "Adding $bin_dir to \$PATH in $profile"
  
  case "$shell" in
    "bash"|"zsh")
      if ! grep -q "export PATH=\"$bin_dir:\$PATH\"" "$profile"; then
        echo "export PATH=\"$bin_dir:\$PATH\"" >> "$profile"
      fi
      ;;
    "fish")
      if ! grep -q "set -gx PATH \"$bin_dir\" \$PATH" "$profile"; then
        echo "set -gx PATH \"$bin_dir\" \$PATH" >> "$profile"
      fi
      ;;
  esac
}

export -f get_shell_profile
export -f add_to_path