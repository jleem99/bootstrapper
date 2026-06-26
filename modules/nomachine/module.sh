#!/bin/bash
# Description: Install NoMachine remote desktop server (NX protocol, port 4000)
# Platforms: debian fedora rhel
set -euo pipefail

log_info "Running nomachine module..."

module_run_platform

log_success "NoMachine module completed!"
log_info "Server listens on TCP 4000 (NX protocol). Connect with a NoMachine client."
