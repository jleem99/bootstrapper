#!/bin/bash
set -euo pipefail

TPM_DIR="$HOME/.tmux/plugins/tpm"
TMUX_CONF="$HOME/.tmux.conf"

ensure_packages_installed tmux git

log_info "Installing TPM (Tmux Plugin Manager)..."
if [[ -d "$TPM_DIR" ]]; then
  log_info "TPM already present, pulling latest..."
  git -C "$TPM_DIR" pull --ff-only
else
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi

log_info "Writing $TMUX_CONF..."
if [[ -f "$TMUX_CONF" ]]; then
  cp "$TMUX_CONF" "${TMUX_CONF}.bak"
  log_info "Existing config backed up to ${TMUX_CONF}.bak"
fi

cat > "$TMUX_CONF" << 'TMUXCONF'
#--- TMUX Plugin Manager
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
#--- End TMUX Plugin Manager

# remote clipboard
set -g set-clipboard on
set -s allow-passthrough on

set-option -g mouse on
set-option -g status-keys vi
set-window-option -g mode-keys vi
set-option -g default-shell /bin/zsh

set -g @plugin 'nhdaly/tmux-better-mouse-mode'
set -g @scroll-speed-num-lines-per-scroll 1

set-option -ga terminal-overrides ',xterm-256color:Tc'
set -sa terminal-features '*:RGB'
set -sa terminal-overrides '*:Smulx=\E[4::%p1%dm'
set -g default-terminal "screen-256color"
set -as terminal-overrides ",xterm*:RGB"
set -sg escape-time 10

##
## Theme
##

set -g @plugin 'wfxr/tmux-power'
set -g @plugin 'wfxr/tmux-net-speed'

set -g @tmux_power_show_upload_speed false
set -g @tmux_power_show_download_speed true

set -g @tmux_power_date_icon           ' '
set -g @tmux_power_time_icon           ' '
set -g @tmux_power_user_icon           ' '
set -g @tmux_power_session_icon        ' '
set -g @tmux_power_right_arrow_icon    '󰇚'
set -g @tmux_power_left_arrow_icon     '󰇚'
set -g @tmux_power_upload_speed_icon   '󰕒'
set -g @tmux_power_download_speed_icon '󰇚'

set -g @tmux_power_date_format '%b %e '

setw -g automatic-rename-format '#{pane_current_command}'

# Status Line 0: Window list spanning full terminal width (centered)
set -g status-format[0] '#[bg=default align=centre list=on]#[list=left-marker]…#[list=right-marker]…#[list=on]#{W:#[range=window|#{window_index}]#{E:window-status-format}#[norange] ,#[range=window|#{window_index}]#{E:window-status-current-format}#[norange] }'

# Status Line 1: powerline segments (session, net-speed, date/time) from tmux-power
set -g 'status-format[1]' '#[bg=default align=left range=left #{E:status-left-style}]#[push-default]#{T;=/#{status-left-length}:status-left}#[pop-default]#[norange default]#[align=right range=right #{E:status-right-style}]#[push-default]#{T;=/#{status-right-length}:status-right}#[pop-default]#[norange default]'

# Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
run '~/.tmux/plugins/tpm/tpm'

# Overrides AFTER TPM — tmux-power resets these on load
set -g status 2
set -g status-style 'bg=default'
set -g status-bg default
set -g status-fg default
set -g window-status-style 'fg=#ffb86c,bg=default,none'

# Fix powerline arrow backgrounds (tmux-power hardcodes #262626 as bar bg)
run-shell 'tmux set -g status-left "$(tmux show -gv status-left | sed "s/bg=#262626/bg=default/g")"'
run-shell 'tmux set -g status-right "$(tmux show -gv status-right | sed "s/bg=#262626/bg=default/g")"'

# Pill-shaped window tabs
set -g window-status-format         '#[fg=#3a3a3a,bg=default]#[fg=#ffb86c,bg=#3a3a3a] #W#F #[fg=#3a3a3a,bg=default]'
set -g window-status-current-format '#[fg=#ffb86c,bg=default]#[fg=#262626,bg=#ffb86c,bold] #W#F #[fg=#ffb86c,bg=default,nobold]'

bind-key -n M-h previous-window
bind-key -n M-l next-window
bind-key -n C-M-h swap-window -t -1\; select-window -t -1
bind-key -n C-M-l swap-window -t +1\; select-window -t +1
TMUXCONF

log_info "Installing TPM plugins headlessly..."
"$TPM_DIR/scripts/install_plugins.sh" || log_info "Plugin install complete (non-zero exit is normal outside a tmux session)"

log_success "Tmux configured with TPM and all plugins installed."

if [[ -n "${TMUX:-}" ]]; then
  if prompt_yes_no "Apply config to the current tmux session now?"; then
    tmux source "$TMUX_CONF"
    log_success "Config reloaded."
  fi
else
  log_info "Not inside a tmux session — run 'tmux source ~/.tmux.conf' after starting tmux."
fi
