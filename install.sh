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
else
  echo -e "${BLUE}Cloning repository...${NC}"
  git clone https://github.com/jleem99/bootstrapper.git "$INSTALL_DIR"

  # Initialize bootstrapper
  echo -e "${BLUE}Initializing bootstrapper...${NC}"
  bash "$INSTALL_DIR/bootstrapper" init
fi

# _logging.sh and _utils.sh (incl. prompt_yes_no) are available here:
# update.sh sources them; fresh-install path can source them from the clone.
source "$INSTALL_DIR/core/_logging.sh"
source "$INSTALL_DIR/core/_utils.sh"

if prompt_yes_no "Restart shell now to apply changes?" "y"; then
  exec $SHELL -l
fi