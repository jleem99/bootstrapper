#!/bin/bash
set -euo pipefail

# Source required utilities
source "$BOOTSTRAPPER_ROOT/core/_logging.sh"

# Version information
VERSION="0.1.0"
BUILD_DATE="2024-03-22"

# Display version information
log_info "Bootstrapper - Version $VERSION"
log_info "Build date: $BUILD_DATE"
log_info "Install path: $BOOTSTRAPPER_ROOT"

# Display platform information if available
if [[ -n "$PLATFORM" ]]; then
  log_info "Current platform: $PLATFORM ($PLATFORM_FAMILY)"
  log_info "Package manager: $PACKAGE_MANAGER"
fi 