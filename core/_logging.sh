#!/bin/bash

# Define color codes if not already defined
[[ -z "${GREEN+x}" ]] && readonly GREEN='\033[0;32m'
[[ -z "${RED+x}" ]] && readonly RED='\033[0;31m'
[[ -z "${BLUE+x}" ]] && readonly BLUE='\033[0;34m'
[[ -z "${YELLOW+x}" ]] && readonly YELLOW='\033[0;33m'
[[ -z "${NC+x}" ]] && readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "$*"
  # echo -e "${BLUE}$*${NC}"
}

log_success() {
  echo -e "${GREEN}$*${NC}"
}

log_warning() {
  echo -e "${YELLOW}$*${NC}"
}

log_error() {
  echo -e "${RED}$*${NC}"
}

log_section() {
  echo -e "\n${BLUE}====== $* ======${NC}"
}

# Export functions for use in other scripts
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_section 