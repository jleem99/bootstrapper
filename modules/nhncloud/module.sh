#!/bin/bash
# Description: Configure NHN Cloud GPU instance (locale, gcsudo, bash shell)
# Platforms: debian
set -euo pipefail

log_info "Running nhncloud module..."

run_module "basic-packages"

# oh-my-bash (installed by the bash module) backs up and replaces ~/.bashrc with
# a fresh template. Run bash BEFORE the platform setup so that the locale and
# sudo profile entries written by module_run_platform survive in the final file.
run_module "bash"

# Platform setup: generate en_US.UTF-8 locale, persist LANG/LC_ALL exports, and
# map sudo to gcsudo in shell profiles. Must run AFTER the bash module.
module_run_platform

run_module "tmux"
run_module "neovim"
run_module "claude"

log_success "NHN Cloud module completed successfully!"
