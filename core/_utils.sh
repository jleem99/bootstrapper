#!/bin/bash
set -euo pipefail

get_current_shell() {
  echo "$(basename "$SHELL")"
}

# Function to get shell profile file
get_shell_profile() {
  local shell="${1:-$(get_current_shell)}"
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
  local bin_dir="$1"
  local shell="${2:-$(get_current_shell)}"
  local profile="${3:-$(get_shell_profile "$shell")}"

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

# Prompt the user with a yes/no question.
# Usage: prompt_yes_no "Question?" [default]
#   default: "y" (default yes, Y/n) or "n" (default no, y/N). Defaults to "y".
# Returns 0 for yes, 1 for no.
prompt_yes_no() {
  local question="$1"
  local default="${2:-y}"
  local prompt

  if [[ "$default" == "y" ]]; then
    prompt="[Y/n]"
  else
    prompt="[y/N]"
  fi

  while true; do
    read -r -p "$question $prompt " answer
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *) echo "Please answer yes or no." ;;
    esac
  done
}

# Returns the absolute directory of the calling script — useful for referencing
# files bundled alongside a module script.
# Usage: cp "$(module_dir)/foo.conf" ~/.foo.conf
module_dir() {
  dirname "$(realpath "${BASH_SOURCE[1]}")"
}

# Run a command non-fatally. On failure, logs a warning and continues.
# Usage: try_run "Description" cmd [args...]
try_run() {
  local description="$1"; shift
  if ! "$@"; then
    log_warning "$description failed — skipping (non-fatal)"
  fi
}

export -f get_current_shell
export -f get_shell_profile
export -f add_to_path
export -f prompt_yes_no
export -f try_run
export -f module_dir