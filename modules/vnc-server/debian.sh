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
    gnome-session \
    gnome-session-bin \
    gnome-shell \
    gnome-terminal \
    gnome-control-center \
    gnome-tweaks \
    gnome-themes-extra \
    gnome-backgrounds \
    gnome-software

# Install GDM for GNOME session support (but don't enable it as default display manager)
sudo apt-get install -y gdm3

# Install full GNOME desktop for better experience
sudo apt-get install -y \
    gnome-shell-extensions \
    gnome-shell-extension-prefs \
    mutter \
    gjs \
    gnome-settings-daemon \
    gnome-keyring \
    gnome-user-share

# Add basic GNOME panel for fallback if needed
sudo apt-get install -y gnome-panel

# Add enhanced GL support and fix missing libraries
sudo apt-get install -y \
    mesa-utils \
    mesa-utils-extra \
    libgl1-mesa-dri \
    libgl1-mesa-glx \
    libglx-mesa0 \
    libegl1-mesa \
    libgles2-mesa

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
    x11-xserver-utils

# Window manager and session components
sudo apt-get install -y \
    metacity

# Audio and system components
sudo apt-get install -y \
    pulseaudio \
    pulseaudio-utils

# Ensure PulseAudio socket directory exists
mkdir -p /run/user/$(id -u)/pulse

# Create VNC config directory
VNC_CONFIG_DIR="$HOME/.vnc"
mkdir -p "$VNC_CONFIG_DIR"

# Create a xstartup file for GNOME with software rendering
cat > "$VNC_CONFIG_DIR/xstartup" << 'EOF'
#!/bin/bash

# Standard session cleanup
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Ensure Xauthority file exists
touch ~/.Xauthority
chmod 600 ~/.Xauthority

# Set up NVIDIA OpenGL environment
export LIBGL_ALWAYS_INDIRECT=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia

# Set GNOME environment variables
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
export DESKTOP_SESSION=gnome
export XDG_CURRENT_DESKTOP=GNOME

# Setup dbus
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
    echo "Started dbus session: $DBUS_SESSION_BUS_ADDRESS"
fi

# Start autocutsel for clipboard support
autocutsel -fork -selection PRIMARY
autocutsel -fork -selection CLIPBOARD

# Start GNOME session
exec gnome-session --session=gnome
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
Requires=dbus.service
After=dbus.service

[Service]
Type=forking
ExecStartPre=-/bin/sh -c '/usr/bin/vncserver -kill :%i > /dev/null 2>&1 || true'
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 -localhost no -rfbauth $HOME/.vnc/passwd -rfbport 590%i -SecurityTypes VncAuth
ExecStop=/usr/bin/vncserver -kill :%i
Restart=on-failure
RestartSec=10
Environment=XDG_SESSION_TYPE=x11
Environment=DISPLAY=:1

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
sudo rm -f /tmp/.X11-unix/X1 /tmp/.X1-lock

# Kill any existing VNC servers
vncserver -kill :1 >/dev/null 2>&1 || true

# Check available GNOME sessions
log_info "Available GNOME sessions:"
find /usr/share/gnome-session/sessions/ -name "*.session" | while read -r session; do
  echo "  - $(basename "$session" .session)"
done

# Define VNC port for the log message
VNC_PORT=5901

# Install the service properly for user services
log_info "Setting up VNC systemd service..."
systemctl --user daemon-reload
systemctl --user enable vncserver@1.service
systemctl --user restart vncserver@1.service

log_info "VNC service enabled and started successfully."
log_info "To start VNC: systemctl --user start vncserver@1.service"
log_info "To stop VNC:  systemctl --user stop vncserver@1.service"

# Get the IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')
log_info "VNC server started!"
log_info "Connect to $IP_ADDRESS:$VNC_PORT using a VNC client" 
log_info "If you have issues, check the logs with: ~/view-vnc-log.sh"
log_info "Note: Make sure your cloud provider allows incoming connections on port $VNC_PORT"
