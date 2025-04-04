#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="$HOME/.local/share/bootstrapper"

# Main installation process
echo -e "${BLUE}Installing bootstrapper...${NC}"

# Clone or update the repository
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo -e "${BLUE}Updating existing installation...${NC}"
  source "$INSTALL_DIR/core/update.sh"
  exit 0
else
  echo -e "${BLUE}Cloning repository...${NC}"
  git clone https://github.com/jleem99/bootstrapper.git "$INSTALL_DIR"
fi

# Initialize bootstrapper
echo -e "${BLUE}Initializing bootstrapper...${NC}"
"$INSTALL_DIR/init.sh"