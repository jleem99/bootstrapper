#!/bin/bash
set -eu

log_info "Setting up VNC server with GNOME for Debian/Ubuntu (Might be non-ubuntu)..."

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
export DISPLAY=:%i
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

# Initialize D-Bus session
export $(dbus-launch)

# Start keyring daemon
eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
export SSH_AUTH_SOCK

# Start X configuration
xrdb $HOME/.Xresources
xsetroot -solid grey

# Start VNC config utility
vncconfig -iconic &

# Enable clipboard
autocutsel -fork

# Sleep to ensure window manager is up
sleep 2

# Start GNOME settings daemon
if [ -x /usr/lib/gnome-settings-daemon/gnome-settings-daemon ]; then
    /usr/lib/gnome-settings-daemon/gnome-settings-daemon &
elif [ -x /usr/libexec/gnome-settings-daemon ]; then
    /usr/libexec/gnome-settings-daemon &
fi

# Add to xstartup
export CLUTTER_BACKEND=software
export GDK_GL=disabled

# Launch GNOME fallback mode directly
exec gnome-session --session=gnome-flashback-metacity --disable-acceleration-check
EOF

# Make the xstartup file executable
chmod +x "$VNC_CONFIG_DIR/xstartup"

# Setup VNC password
if [ -t 0 ]; then
    read -s -p "Enter your VNC password: " VNC_PASSWORD
    echo
else
    VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -base64 12)}"
    log_info "Using random password in non-interactive mode"
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
WorkingDirectory=${HOME}
Environment="DISPLAY=:%i"
Environment="HOME=${HOME}"
PIDFile=${HOME}/.vnc/%H:%i.pid

ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :%i >/dev/null 2>&1 || true'
ExecStartPre=/bin/sh -c 'pkill -U \$USER -f "Xtigervnc :%i" >/dev/null 2>&1 || true'
ExecStartPre=/bin/rm -f /tmp/.X*-lock /tmp/.X11-unix/X*  # Add explicit socket cleanup
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 -rfbauth ${HOME}/.vnc/passwd -localhost no -CompressionLevel 6 -QualityLevel 8 -fg -noxstartup
ExecStop=/usr/bin/vncserver -kill :%i
ExecStopPost=/bin/sh -c 'pkill -U \$USER -f "Xtigervnc :%i" >/dev/null 2>&1'
ExecStopPost=/bin/sh -c 'rm -f /tmp/.X*-lock /tmp/.X11-unix/X*'  # Ensure socket cleanup

# Add process killing protections
KillMode=process
KillSignal=SIGINT
TimeoutStopSec=5
Restart=on-failure
RestartSec=5
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