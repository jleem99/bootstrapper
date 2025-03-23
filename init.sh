#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="$HOME/.local/share/bootstrapper"
BIN_DIR="$HOME/.local/bin"

# Function to detect current shell
detect_shell() {
  if [[ -n "$ZSH_VERSION" ]]; then
    echo "zsh"
  elif [[ -n "$BASH_VERSION" ]]; then
    echo "bash"
  elif [[ -n "$FISH_VERSION" ]]; then
    echo "fish"
  else
    echo "unknown"
  fi
}

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

# Main initialization process
echo -e "${BLUE}Initializing bootstrapper...${NC}"

# Create installation directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Make the bootstrapper executable
chmod +x "$INSTALL_DIR/bootstrapper"

# Create symlink to bootstrapper
ln -sf "$INSTALL_DIR/bootstrapper" "$BIN_DIR/bootstrapper"

# Detect current shell
CURRENT_SHELL=$(detect_shell)
if [[ "$CURRENT_SHELL" == "unknown" ]]; then
  echo -e "${RED}Could not detect current shell${NC}"
  exit 1
fi

# Get shell profile
SHELL_PROFILE=$(get_shell_profile "$CURRENT_SHELL")

# Create shell profile if it doesn't exist
if [[ ! -f "$SHELL_PROFILE" ]]; then
  touch "$SHELL_PROFILE"
fi

# Add to PATH
echo -e "${BLUE}Adding bootstrapper to PATH...${NC}"
add_to_path "$CURRENT_SHELL" "$BIN_DIR" "$SHELL_PROFILE"

# Source bootstrapper
echo -e "${BLUE}Setting up bootstrapper for $CURRENT_SHELL...${NC}"
case "$CURRENT_SHELL" in
  "bash"|"zsh")
    if ! grep -q "source \"\$HOME/.local/share/bootstrapper/bootstrapper\"" "$SHELL_PROFILE"; then
      echo "source \"\$HOME/.local/share/bootstrapper/bootstrapper\"" >> "$SHELL_PROFILE"
    fi
    ;;
  "fish")
    if ! grep -q "source \$HOME/.local/share/bootstrapper/bootstrapper" "$SHELL_PROFILE"; then
      echo "source \$HOME/.local/share/bootstrapper/bootstrapper" >> "$SHELL_PROFILE"
    fi
    ;;
esac

echo -e "\n${GREEN}Bootstrapper initialized successfully!${NC}"
echo -e "${BLUE}To start using bootstrapper immediately, run:${NC}"
echo -e "  source $SHELL_PROFILE"
echo -e "${BLUE}Or restart your terminal, then run:${NC}"
echo -e "  bootstrapper help" 