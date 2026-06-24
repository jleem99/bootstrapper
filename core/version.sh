#!/bin/bash
set -euo pipefail

# Source required utilities
source "$BOOTSTRAPPER_ROOT/core/_logging.sh"

# Version information derived from git
VERSION="$(git -C "$BOOTSTRAPPER_ROOT" describe --tags --always --dirty 2>/dev/null || echo "unknown")"
BUILD_DATE="$(git -C "$BOOTSTRAPPER_ROOT" log -1 --format='%ci' 2>/dev/null | cut -d' ' -f1 || echo "unknown")"

# Display version information
log_info "Bootstrapper - Version $VERSION"
log_info "Build date: $BUILD_DATE"
log_info "Install path: $BOOTSTRAPPER_ROOT"

# Display platform information if available
if [[ -n "$PLATFORM" ]]; then
  log_info "Current platform: $PLATFORM ($PLATFORM_FAMILY)"
  log_info "Package manager: $PACKAGE_MANAGER"
fi 