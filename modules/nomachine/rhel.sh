#!/bin/bash
set -euo pipefail

# RHEL/CentOS use the same RPM package as Fedora.
# install_packages will automatically pick yum vs dnf via $PACKAGE_MANAGER.
source "$(dirname "${BASH_SOURCE[0]}")/fedora.sh"
