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
      echo -e "${RED}Unsupported shell: $shell${NC}" >&2
      return 1
      ;;
  esac
}

# Emit a line to the session-env file when running under the bootstrapper()
# wrapper function. The wrapper sets BOOTSTRAPPER_SESSION_ENV to a temp file;
# after the binary exits, the wrapper sources that file to apply env changes
# (PATH additions, exports, aliases) to the calling interactive shell.
# $1 = bash/zsh line, $2 = fish line
_session_emit() {
  [ -n "${BOOTSTRAPPER_SESSION_ENV:-}" ] || return 0
  case "${BOOTSTRAPPER_SESSION_SHELL:-bash}" in
    fish) printf '%s\n' "$2" >> "$BOOTSTRAPPER_SESSION_ENV" ;;
    *)    printf '%s\n' "$1" >> "$BOOTSTRAPPER_SESSION_ENV" ;;
  esac
}

# NOT a wrapper around add_export: the profile line must write $PATH as a
# reference (export PATH="dir:$PATH"), not a snapshot of its current value.
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

  # Also apply to the current shell session so subsequent steps in this run can
  # use the newly added directory without requiring a new shell.
  export PATH="$bin_dir:$PATH"

  # Propagate to the calling interactive shell via the session-env bridge.
  _session_emit \
    "export PATH=\"$bin_dir:\$PATH\"" \
    "set -gx PATH \"$bin_dir\" \$PATH"
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

# Run a command or function non-fatally in a subshell.
# On failure (or if any command inside the block fails), logs a warning and continues.
# Usage: try_run "Description" cmd [args...]
try_run() {
  local description="$1"; shift
  if ! ( set -e; "$@" ); then
    log_warning "$description failed — skipping (non-fatal)"
  fi
  return 0
}

# Detect installed shells on the system by reading /etc/shells
detect_installed_shells() {
  local shells=()
  if [[ -f /etc/shells ]]; then
    while read -r line; do
      [[ "$line" =~ ^# ]] && continue
      [[ -z "$line" ]] && continue
      shells+=("$(basename "$line")")
    done < /etc/shells
  else
    # Fallback if /etc/shells is not present
    shells=(bash zsh fish)
  fi
  printf "%s\n" "${shells[@]}" | sort -u
}

# Add an alias to all supported interactive shell profiles
# Usage: add_alias "name" "command"
add_alias() {
  local name="$1"
  local cmd="$2"

  for shell in $(detect_installed_shells); do
    local profile
    profile="$(get_shell_profile "$shell" 2>/dev/null)" || continue
    [[ -f "$profile" ]] || continue
    
    # Check if the alias is already defined to avoid duplicates
    if ! grep -q "alias $name=" "$profile" && ! grep -q "alias $name " "$profile"; then
      log_info "Adding alias $name -> $cmd in $profile"
      printf '\n# Added by bootstrapper\nalias %s="%s"\n' "$name" "$cmd" >> "$profile"
    fi
  done

  alias "${name}=${cmd}"

  # Propagate to the calling interactive shell via the session-env bridge.
  _session_emit \
    "alias $name=\"$cmd\"" \
    "alias $name \"$cmd\""
}

# Add an environment variable to all supported interactive shell profiles
# Usage: add_export "NAME" "VALUE"
add_export() {
  local name="$1"
  local val="$2"

  for shell in $(detect_installed_shells); do
    local profile
    profile="$(get_shell_profile "$shell" 2>/dev/null)" || continue
    [[ -f "$profile" ]] || continue
    
    case "$shell" in
      "bash"|"zsh")
        if ! grep -q "export $name=" "$profile"; then
          log_info "Adding export $name=$val in $profile"
          printf '\n# Added by bootstrapper\nexport %s="%s"\n' "$name" "$val" >> "$profile"
        fi
        ;;
      "fish")
        if ! grep -q "set -gx $name " "$profile"; then
          log_info "Adding set -gx $name $val in $profile"
          printf '\n# Added by bootstrapper\nset -gx %s "%s"\n' "$name" "$val" >> "$profile"
        fi
        ;;
    esac
  done

  export "${name}=${val}"

  # Propagate to the calling interactive shell via the session-env bridge.
  _session_emit \
    "export $name=\"$val\"" \
    "set -gx $name \"$val\""
}

# Write content between managed marker lines in a profile.
# Strips any existing >>> bootstrapper >>> … <<< bootstrapper <<< block first,
# then appends the fresh block. Idempotent: safe to call multiple times.
# Usage: write_managed_block <profile> <content>
write_managed_block() {
  local profile="$1"
  local content="$2"
  local tmp

  # Remove existing managed block (if any) using awk for portability.
  tmp="$(awk '
    /^# >>> bootstrapper >>>/ { skip=1 }
    skip && /^# <<< bootstrapper <<</ { skip=0; next }
    !skip { print }
  ' "$profile")"

  # Write stripped content back, then append the fresh block.
  printf '%s\n' "$tmp" > "$profile"
  printf '\n%s\n' "$content" >> "$profile"
}

# Remove all bootstrapper-owned content from a shell profile.
# Strips:
#   - the >>> bootstrapper >>> … <<< bootstrapper <<< managed function block
#   - the exact ~/.local/bin PATH line bootstrapper adds (bash/zsh and fish forms)
#   - every "# Added by bootstrapper" comment and the single line following it
# Exact-match only — never broad-filters; user content is never touched.
# Usage: clean_profile <profile> [bin_dir]  (bin_dir defaults to $HOME/.local/bin)
clean_profile() {
  local profile="$1"
  local bin_dir="${2:-$HOME/.local/bin}"
  [[ -f "$profile" ]] || return 0

  # The two exact PATH lines add_to_path writes (bash/zsh form and fish form).
  local bash_path_line="export PATH=\"${bin_dir}:\$PATH\""
  local fish_path_line="set -gx PATH \"${bin_dir}\" \$PATH"

  local tmp
  tmp="$(awk \
    -v bash_line="$bash_path_line" \
    -v fish_line="$fish_path_line" \
    '
    # State: inside managed block → skip until closing marker.
    /^# >>> bootstrapper >>>/ { skip_block=1; next }
    skip_block && /^# <<< bootstrapper <<</ { skip_block=0; next }
    skip_block { next }

    # State: previous line was "# Added by bootstrapper" → skip one payload line.
    skip_next { skip_next=0; next }

    # Exact PATH lines bootstrapper adds.
    $0 == bash_line { next }
    $0 == fish_line { next }

    # Tagged comment: skip this line and flag the next one.
    /^# Added by bootstrapper$/ { skip_next=1; next }

    { print }
  ' "$profile")"

  printf '%s\n' "$tmp" > "$profile"
}

export -f _session_emit
export -f get_current_shell
export -f get_shell_profile
export -f add_to_path
export -f prompt_yes_no
export -f try_run
export -f module_dir
export -f detect_installed_shells
export -f add_alias
export -f add_export
export -f write_managed_block
export -f clean_profile