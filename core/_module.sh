#!/bin/bash
set -euo pipefail

# Read the declared supported platforms for a module from its `# Platforms:` comment.
# Returns a space-separated list, e.g. "debian fedora rhel arch macos".
# Usage: module_supported_platforms "bash"
module_supported_platforms() {
  local module_script="$BOOTSTRAPPER_ROOT/modules/$1/module.sh"
  [[ -f "$module_script" ]] || return 1
  grep -m1 '^# Platforms:' "$module_script" | cut -d':' -f2- | xargs
}

# Return 0 if the current $PLATFORM is in the module's declared platform list.
# No `# Platforms:` line => considered unsupported.
# Usage: module_is_supported "bash"
module_is_supported() {
  local platforms
  platforms="$(module_supported_platforms "$1")" || return 1
  local p
  for p in $platforms; do
    [[ "$p" == "$PLATFORM" ]] && return 0
  done
  return 1
}

# Function to run a platform-specific module implementation.
# Sources modules/<name>/$PLATFORM.sh in the current shell.
# Usage: module_run_platform "module_name" [extra_args]
module_run_platform() {
  local module_name="$1"
  shift  # Remove module name from arguments

  # Get calling script's directory
  local caller_dir
  caller_dir="$(dirname "${BASH_SOURCE[1]}")"
  local module_dir=""

  # Determine the module directory
  if [[ "$caller_dir" == *"/modules/$module_name" ]]; then
    # Called from module/module.sh
    module_dir="$caller_dir"
  else
    # Called from somewhere else, use BOOTSTRAPPER_ROOT
    module_dir="$BOOTSTRAPPER_ROOT/modules/$module_name"
  fi

  # Construct the platform script path
  local platform_script="$module_dir/$PLATFORM.sh"

  if [[ -f "$platform_script" ]]; then
    log_info "Running platform-specific implementation for $PLATFORM..."
    # Pass any additional arguments to the platform script
    source "$platform_script" "$@"
    log_success "✅ Platform-specific implementation completed"
    return 0
  else
    log_error "No platform-specific implementation found for $PLATFORM"
    log_error "Expected file: $platform_script"
    exit 1
  fi
}

# Run another module by name (cross-module composition).
# Sources modules/<name>/module.sh in the current shell after checking support,
# so installs, PATH changes, and profile writes take effect for the caller too.
# Usage: run_module "bash"
run_module() {
  local module_name="$1"
  local module_script="$BOOTSTRAPPER_ROOT/modules/$module_name/module.sh"
  if [[ ! -f "$module_script" ]]; then
    log_error "Cannot run module '$module_name': $module_script not found"
    return 1
  fi
  if ! module_is_supported "$module_name"; then
    log_error "Module $module_name is not supported on $PLATFORM"
    log_info  "Supported platforms: $(module_supported_platforms "$module_name")"
    return 1
  fi
  log_section "Bootstrapping module: $module_name"
  source "$module_script"
}

# Export utility functions
export -f module_supported_platforms
export -f module_is_supported
export -f module_run_platform
export -f run_module
