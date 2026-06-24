#!/bin/bash
set -euo pipefail

BOOTSTRAPPER_ROOT="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"

source "$BOOTSTRAPPER_ROOT/core/_logging.sh"
source "$BOOTSTRAPPER_ROOT/core/_platform.sh"
source "$BOOTSTRAPPER_ROOT/core/_utils.sh"

source "$BOOTSTRAPPER_ROOT/core/init.sh" "$@"
