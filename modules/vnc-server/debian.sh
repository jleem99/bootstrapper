#!/bin/bash
set -eu

log_info "Setting up VNC server with full GNOME desktop environment for Debian..."

# Check if systemd is available
if ! command -v systemctl &> /dev/null; then
  log_error "Systemd is required for this module. Please use a system with systemd."
  exit 1
fi

# Install TigerVNC server and GNOME desktop components
sudo apt-get update

# Core VNC server components
sudo apt-get install -y \
    tigervnc-standalone-server \
    tigervnc-common \
    autocutsel \
    dbus-x11

# Core GNOME desktop environment
sudo apt-get install -y \
    gnome-shell \
    gnome-terminal \
    gnome-control-center \
    gnome-tweaks \
    gnome-themes-extra \
    gnome-backgrounds \
    gnome-software \
    gnome-session-flashback

# GNOME applications and utilities
sudo apt-get install -y \
    nautilus \
    nautilus-extension-gnome-terminal \
    gedit \
    eog \
    seahorse \
    dconf-editor \
    adwaita-icon-theme

# X server and display components
sudo apt-get install -y \
    xserver-xorg-core \
    xinit \
    xauth \
    x11-xserver-utils \
    mesa-utils \
    libgl1-mesa-dri

# Window manager and session components
sudo apt-get install -y \
    metacity

# Audio and system components
sudo apt-get install -y \
    pulseaudio \
    pulseaudio-utils

# Create VNC config directory
VNC_CONFIG_DIR="$HOME/.vnc"
mkdir -p "$VNC_CONFIG_DIR"

# Create a xstartup file for GNOME with software rendering
cat > "$VNC_CONFIG_DIR/xstartup" << 'EOF'
#!/bin/sh

# Create empty .Xresources if it doesn't exist to avoid errors
touch $HOME/.Xresources

# Clean any previous sessions
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Make sure we have a display
export DISPLAY=:1
export HOME=$HOME

# Force software rendering
export LIBGL_ALWAYS_SOFTWARE=1
export MESA_GL_VERSION_OVERRIDE=3.3
export MESA_GLSL_VERSION_OVERRIDE=330

# Set required environment variables
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
export XDG_CURRENT_DESKTOP="GNOME"

# Add to environment variables
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR
chmod 0700 $XDG_RUNTIME_DIR

# Initialize X authority
if [ ! -f $HOME/.Xauthority ]; then
    touch $HOME/.Xauthority
    chmod 600 $HOME/.Xauthority
    xauth add $DISPLAY . $(mcookie)
fi

# Kill any existing window managers
pkill -x metacity || true
pkill -x gnome-shell || true

# Start fresh D-Bus session with proper initialization
dbus-run-session -- sh -c '
    # Set up D-Bus environment
    export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
    export DBUS_SESSION_BUS_PID=$$

    # Keyring initialization
    eval $(/usr/bin/gnome-keyring-daemon --start --daemonize --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK

    # X configuration
    xrdb $HOME/.Xresources
    xsetroot -solid grey

    # VNC components
    vncconfig -iconic &
    autocutsel -fork

    # Start GNOME settings daemon
    if [ -x /usr/lib/gnome-settings-daemon/gnome-settings-daemon ]; then
        /usr/lib/gnome-settings-daemon/gnome-settings-daemon &
    fi

    # Start window manager with replace option
    metacity --replace &

    # Wait for window manager to start
    sleep 2

    # Start GNOME session
    exec gnome-session --session=gnome-flashback-metacity --disable-acceleration-check
'
EOF

# Make the xstartup file executable
chmod +x "$VNC_CONFIG_DIR/xstartup"

# Setup VNC password
if [ -t 0 ]; then
    read -s -p "Enter your VNC password: " VNC_PASSWORD
    echo
else
    VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -base64 12)}"
    log_info "Generated VNC password: $VNC_PASSWORD"
fi
echo "$VNC_PASSWORD" | vncpasswd -f > "$VNC_CONFIG_DIR/passwd"
chmod 600 "$VNC_CONFIG_DIR/passwd"

# Get current username
CURRENT_USER=$(whoami)

# Create systemd user directory
mkdir -p ~/.config/systemd/user

# Create service file in user's home 
cat > ~/.config/systemd/user/vncserver@.service << EOF
[Unit]
Description=Remote desktop service (VNC)
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=forking
WorkingDirectory=%h
Environment="DISPLAY=:%i"
Environment="HOME=%h"
Environment="XAUTHORITY=%h/.Xauthority"
Environment="XDG_RUNTIME_DIR=/run/user/%U"
Environment="DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus"
PIDFile=%h/.vnc/%H:%i.pid

# Cleanup before starting
ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :%i >/dev/null 2>&1 || true'
ExecStartPre=/bin/sh -c 'pkill -U %U -x Xtigervnc >/dev/null 2>&1 || true'
ExecStartPre=/bin/sh -c 'pkill -U %U -x metacity >/dev/null 2>&1 || true'
ExecStartPre=/bin/sh -c 'pkill -U %U -x gnome-shell >/dev/null 2>&1 || true'
ExecStartPre=/bin/sh -c 'rm -f /tmp/.X%i-lock /tmp/.X11-unix/X%i %h/.vnc/*%i* >/dev/null 2>&1 || true'

# Start VNC server
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 \
    -rfbauth %h/.vnc/passwd \
    -localhost no \
    -Log *:stderr:100

# Cleanup after stopping
ExecStop=/usr/bin/vncserver -kill :%i
ExecStopPost=/bin/sh -c 'pkill -U %U -x Xtigervnc >/dev/null 2>&1 || true'
ExecStopPost=/bin/sh -c 'pkill -U %U -x metacity >/dev/null 2>&1 || true'
ExecStopPost=/bin/sh -c 'pkill -U %U -x gnome-shell >/dev/null 2>&1 || true'
ExecStopPost=/bin/sh -c 'rm -f %h/.vnc/*%i* >/dev/null 2>&1 || true'

# Process management
KillMode=mixed
KillSignal=SIGINT
TimeoutStartSec=30
TimeoutStopSec=15
Restart=on-failure
RestartSec=10s
RemainAfterExit=no

[Install]
WantedBy=default.target
EOF

# Create a VNC log viewing helper
cat > ~/view-vnc-log.sh << 'EOF'
#!/bin/bash
LOGFILE=$(find ~/.vnc -name '*.log' -print | sort -r | head -1)
echo "Viewing most recent VNC log: $LOGFILE"
tail -f "$LOGFILE"
EOF
chmod +x ~/view-vnc-log.sh

# Verify VNC password file exists and has content
if [[ ! -s "$VNC_CONFIG_DIR/passwd" ]]; then
  log_error "VNC password file is empty or doesn't exist! Creating a default one."
  echo "vncserver" | vncpasswd -f > "$VNC_CONFIG_DIR/passwd"
  chmod 600 "$VNC_CONFIG_DIR/passwd"
fi

# Clean up any existing sessions and files
sudo chown -R $USER:$USER $HOME
sudo rm -f /tmp/.X11-unix/X1 /tmp/.X1-lock
rm -rf ~/.vnc/*.log ~/.cache/*
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

# Install the service properly for user services
systemctl --user daemon-reload
systemctl --user enable vncserver@1.service
systemctl --user restart vncserver@1.service

# After service restart
sleep 3
if ! systemctl --user is-active --quiet vncserver@1.service; then
    log_error "Service failed to start!"
    journalctl --user-unit vncserver@1.service -b --no-pager
    exit 1
fi

log_info "VNC service enabled. Start with: systemctl --user start vncserver@1.service"
log_info "Stop with: systemctl --user stop vncserver@1.service"

# Get the IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')
log_info "VNC server started!"
log_info "Connect to $IP_ADDRESS:$VNC_PORT using a VNC client"
log_info "If you have issues, check the logs with: ~/view-vnc-log.sh"
log_info "Note: Make sure your cloud provider allows incoming connections on port $VNC_PORT"
