#!/usr/bin/env fish
# Usage (fish — bootstrapper usable immediately):
#   curl -fsSL https://raw.githubusercontent.com/jleem99/bootstrapper/refs/heads/main/install.fish | source

function __bootstrapper_install
    set -l INSTALL_DIR "$HOME/.local/share/bootstrapper"
    set -l BIN_DIR "$HOME/.local/bin"
    set -l REPO "https://github.com/jleem99/bootstrapper.git"

    echo "Installing bootstrapper..."

    if test -d "$INSTALL_DIR/.git"
        echo "Updating existing installation..."
        env BOOTSTRAPPER_QUIET_HINT=1 bash "$INSTALL_DIR/bootstrapper" update
        or begin; echo "Update failed." >&2; return 1; end
    else
        echo "Cloning repository..."
        git clone "$REPO" "$INSTALL_DIR"
        or begin; echo "Clone failed." >&2; return 1; end
        echo "Initializing bootstrapper..."
        env BOOTSTRAPPER_QUIET_HINT=1 bash "$INSTALL_DIR/bootstrapper" init
        or begin; echo "Init failed." >&2; return 1; end
    end

    # Load the bootstrapper() wrapper function into the current fish session.
    # The function is what propagates PATH/exports from future module runs.
    if not contains "$BIN_DIR" $PATH
        set -gx PATH "$BIN_DIR" $PATH
    end
    if command -v bootstrapper >/dev/null 2>&1
        bootstrapper shellenv fish | source
    end

    echo "bootstrapper is ready."
    echo -n "  Run: "; set_color blue; echo "bootstrapper help"; set_color normal
end

__bootstrapper_install
functions -e __bootstrapper_install
