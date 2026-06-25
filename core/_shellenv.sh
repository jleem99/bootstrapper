#!/bin/bash
# _shellenv.sh — generates the bootstrapper() shell-function wrapper text.
#
# The wrapper is the core of Option-1: instead of a binary that runs as a
# subprocess (and loses its env changes on exit), bootstrapper is a shell
# *function* that runs the binary but then sources the env-delta file the
# binary wrote, propagating PATH/exports/aliases back to the current shell.
#
# Single source of truth: print_shellenv is the only place the function text
# lives. init.sh writes it into profiles; install.sh/install.fish eval it for
# the current session. Updates are automatic because `bootstrapper update` calls
# `bootstrapper init`, which re-runs print_shellenv.

# Print the bootstrapper() wrapper function suitable for eval / profile embed.
# Usage: print_shellenv [bash|zsh|fish]
print_shellenv() {
  local shell="${1:-$(get_current_shell)}"
  case "$shell" in
    bash|zsh)
      # BOOTSTRAPPER_SESSION_SHELL must be the literal shell name here, not
      # a variable reference, so each shell gets the right syntax in the env file.
      cat <<SHELL_EOF
# >>> bootstrapper >>>
bootstrapper() {
  case ":\$PATH:" in *":\$HOME/.local/bin:"*) ;; *) export PATH="\$HOME/.local/bin:\$PATH" ;; esac
  local __bs_env __bs_status
  __bs_env="\$(command mktemp "\${TMPDIR:-/tmp}/bootstrapper-env.XXXXXX")" \\
    || { command bootstrapper "\$@"; return \$?; }
  BOOTSTRAPPER_SESSION_ENV="\$__bs_env" BOOTSTRAPPER_SESSION_SHELL=$shell \\
    command bootstrapper "\$@"
  __bs_status=\$?
  [ -s "\$__bs_env" ] && . "\$__bs_env"
  command rm -f "\$__bs_env"
  return \$__bs_status
}
# <<< bootstrapper <<<
SHELL_EOF
      ;;
    fish)
      cat <<'FISH_EOF'
# >>> bootstrapper >>>
function bootstrapper
    if not contains "$HOME/.local/bin" $PATH
        set -gx PATH "$HOME/.local/bin" $PATH
    end
    set -l __bs_env (command mktemp "/tmp/bootstrapper-env.XXXXXX")
    or begin; command bootstrapper $argv; return $status; end
    BOOTSTRAPPER_SESSION_ENV=$__bs_env BOOTSTRAPPER_SESSION_SHELL=fish \
        command bootstrapper $argv
    set -l __bs_status $status
    test -s "$__bs_env"; and source "$__bs_env"
    command rm -f "$__bs_env"
    return $__bs_status
end
# <<< bootstrapper <<<
FISH_EOF
      ;;
    *)
      log_warning "print_shellenv: unsupported shell '$shell' — skipping function block"
      ;;
  esac
}

export -f print_shellenv
