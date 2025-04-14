#!/bin/bash
set -euo pipefail

log_info "Running direnv module..."

install_packages "direnv"

log_success "Direnv installed successfully!"

cat <<EOF > ~/.config/direnv/direnvrc
# layout for conda environments
layout_conda() {
  local CONDA_HOME="${HOME}/miniconda3/"
  PATH_add "$CONDA_HOME"/bin

  if [ -n "$1" ]; then
    # Explicit environment name from layout command.
    local env_name="$1"
    source activate ${env_name}
  elif (grep -q name: environment.yml); then
    # Detect environment name from `environment.yml` file in `.envrc` directory
    source activate `grep name: environment.yml | sed -e 's/name: //'`
  else
    (>&2 echo No environment specified);
    exit 1;
  fi;
}
EOF

log_success "Direnv configuration added to ~/.config/direnv/direnvrc"

log_success "Direnv module completed successfully!" 