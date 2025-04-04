#!/bin/bash
set -eu

log_info "Setting up VNC server with full GNOME desktop environment for Debian..."

# Check if systemd is available
if ! command -v systemctl &> /dev/null; then
  log_error "Systemd is required for this module. Please use a system with systemd."
  exit 1
fi

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
    gnome-settings-daemon \
    gnome-keyring \
    gnome-user-share

# Add enhanced GL support and fix missing libraries
sudo apt-get install -y \
    mesa-utils \
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

# Audio and system components
sudo apt-get install -y \
    pulseaudio

# Create system-wide VNC config directory
VNC_CONFIG_DIR="/etc/vnc"
sudo mkdir -p "$VNC_CONFIG_DIR"

# Create a xstartup file for GNOME with software rendering
sudo tee "$VNC_CONFIG_DIR/xstartup" > /dev/null << 'EOF'
#!/bin/bash

# Standard session cleanup
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

# Set up NVIDIA OpenGL environment
export LD_LIBRARY_PATH=/usr/lib/nvidia:/usr/lib/x86_64-linux-gnu:/usr/lib:$LD_LIBRARY_PATH
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export LIBGL_ALWAYS_INDIRECT=0  # Disable indirect rendering

# Set GNOME environment variables
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
export XDG_CURRENT_DESKTOP=GNOME
export XDG_RUNTIME_DIR=/run/user/$(id -u)
mkdir -p $XDG_RUNTIME_DIR && chmod 0700 $XDG_RUNTIME_DIR

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
sudo chmod +x "$VNC_CONFIG_DIR/xstartup"

# Setup VNC password
if [ -t 0 ]; then
    read -s -p "Enter your VNC password: " VNC_PASSWORD
    echo
else
    VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -base64 12)}"
    log_info "Generated VNC password: $VNC_PASSWORD"
fi
echo "$VNC_PASSWORD" | vncpasswd -f | sudo tee "$VNC_CONFIG_DIR/passwd" > /dev/null
chmod 600 "$VNC_CONFIG_DIR/passwd"

# Create systemd service file
sudo tee /etc/systemd/system/vncserver@.service > /dev/null << EOF
[Unit]
Description=Remote desktop service (VNC)
After=network.target
Requires=dbus.service
After=dbus.service

[Service]
Type=forking
User=root
Group=root
WorkingDirectory=/root
ExecStartPre=-/bin/sh -c '/usr/bin/vncserver -kill :1 > /dev/null 2>&1 || true'
ExecStart=/usr/bin/vncserver :1 -geometry 1920x1080 -depth 24 -localhost no -rfbauth /etc/vnc/passwd -rfbport 5901 -SecurityTypes VncAuth
ExecStop=/usr/bin/vncserver -kill :1
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Clean up any existing sessions and files
sudo rm -f /tmp/.X11-unix/X1 /tmp/.X1-lock

# Kill any existing VNC servers
sudo vncserver -kill :1 >/dev/null 2>&1 || true

# Check available GNOME sessions
log_info "Available GNOME sessions:"
find /usr/share/gnome-session/sessions/ -name "*.session" | while read -r session; do
  echo "  - $(basename "$session" .session)"
done

# Define VNC port for the log message
VNC_PORT=5901

# Install the service properly
log_info "Setting up VNC systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service
sudo systemctl restart vncserver@1.service

log_info "VNC service enabled and started successfully."
log_info "To start VNC: sudo systemctl start vncserver@1.service"
log_info "To stop VNC:  sudo systemctl stop vncserver@1.service"

# Get the IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')
log_info "VNC server started!"
log_info "Connect to $IP_ADDRESS:$VNC_PORT using a VNC client" 
