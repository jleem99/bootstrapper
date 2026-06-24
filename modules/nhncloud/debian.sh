#!/bin/bash
set -euo pipefail

GCSUDO_BIN="/engrid/ensh/gpubin/ctn_gcsudo"

if ! grep -qxF 'LANG=en_US.UTF-8' /etc/default/locale 2>/dev/null; then
  log_info "Generating en_US.UTF-8 locale..."
  "$GCSUDO_BIN" locale-gen en_US.UTF-8
  "$GCSUDO_BIN" update-locale LANG=en_US.UTF-8
fi

# Map sudo to gcsudo in user's interactive shell profiles
add_alias "sudo" "$GCSUDO_BIN"
