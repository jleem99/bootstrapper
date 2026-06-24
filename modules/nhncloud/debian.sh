#!/bin/bash
set -euo pipefail

GCSUDO_BIN="/engrid/ensh/gpubin/ctn_gcsudo"

if ! grep -qxF 'LANG=en_US.UTF-8' /etc/default/locale 2>/dev/null; then
  log_info "Generating en_US.UTF-8 locale..."
  "$GCSUDO_BIN" locale-gen en_US.UTF-8
  "$GCSUDO_BIN" update-locale LANG=en_US.UTF-8
fi

log_info "Installing sudo → gcsudo wrapper at /usr/local/bin/sudo..."
printf '#!/bin/sh\nexec "%s" "$@"\n' "$GCSUDO_BIN" | "$GCSUDO_BIN" tee /usr/local/bin/sudo > /dev/null
"$GCSUDO_BIN" chmod +x /usr/local/bin/sudo
