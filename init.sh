#!/bin/bash
# Compatibility shim — old update.sh installations call this path.
# Delegates to the bootstrapper binary so PATH/init logic stays in one place.
set -euo pipefail
exec bash "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/bootstrapper" init "$@"
