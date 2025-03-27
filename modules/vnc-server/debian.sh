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

# Install full GNOME desktop for better experience
sudo apt-get install -y \
    gnome-shell-extensions \
    gnome-shell-extension-prefs \
    mutter \
    gjs \
    gnome-settings-daemon \
    gnome-keyring \
    gnome-user-share

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

# Set standard environment variables
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
export DESKTOP_SESSION=gnome-xorg
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=GNOME
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg

# Force software rendering for VNC compatibility
export LIBGL_ALWAYS_SOFTWARE=1
export XLIB_SKIP_ARGB_VISUALS=1
export MESA_GL_VERSION_OVERRIDE=3.0

# Setup dbus
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
fi

# Start autocutsel for clipboard support
autocutsel -fork -selection PRIMARY
autocutsel -fork -selection CLIPBOARD

# Start a basic window manager first in case GNOME session fails
metacity --replace &

# Try GNOME with different methods in case one fails
if command -v gnome-session >/dev/null 2>&1; then
    # Try standard GNOME session
    if [ -f /usr/share/gnome-session/sessions/gnome-xorg.session ]; then
        exec gnome-session --session=gnome-xorg
    elif [ -f /usr/share/gnome-session/sessions/gnome.session ]; then
        exec gnome-session --session=gnome
    elif [ -f /usr/share/gnome-session/sessions/gnome-classic.session ]; then
        exec gnome-session --session=gnome-classic
    else
        # Fallback to running components directly
        gnome-panel &
        gnome-settings-daemon &
        nautilus &
        exec metacity
    fi
else
    # Ultimate fallback
    xterm &
    exec metacity
fi
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

[Service]
Type=simple
ExecStartPre=-/bin/sh -c '/usr/bin/vncserver -kill :%i > /dev/null 2>&1'
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 -localhost no -rfbauth $HOME/.vnc/passwd -rfbport 590%i -SecurityTypes VncAuth -extension RANDR
ExecStop=/usr/bin/vncserver -kill :%i
Restart=on-failure
RestartSec=10

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

# Clear any existing GNOME session cache
rm -rf ~/.cache/gnome-session/
rm -rf ~/.config/session/
rm -rf ~/.config/dconf/

# Ensure VNC user directories exist with correct permissions
mkdir -p /run/user/$(id -u)/
sudo chmod 700 /run/user/$(id -u)/

# Create a gnome fallback session file
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/gnome-session-fallback.desktop << EOF
[Desktop Entry]
Type=Application
Name=GNOME Classic Fallback
Comment=This session logs you into GNOME with the traditional panel
Exec=gnome-session --session=gnome-classic
TryExec=gnome-session
NoDisplay=true
X-GNOME-AutoRestart=true
X-GNOME-Autostart-Phase=Applications
X-GNOME-Provides=windowmanager
X-GDM-BypassXsession=true
X-GNOME-WMName=Metacity
EOF

# Create .xinitrc to ensure proper X startup
cat > ~/.xinitrc << 'EOF'
#!/bin/bash
exec gnome-session --session=gnome-xorg
EOF
chmod +x ~/.xinitrc

# For journalctl logging
mkdir -p ~/.local/share/systemd/user
touch ~/.local/share/systemd/user/vncserver@.service

# Create a system-wide VNC configuration file
sudo mkdir -p /etc/tigervnc
sudo cat > /etc/tigervnc/vncserver-config-defaults << 'EOF'
session=gnome-xorg
securitytypes=vncauth
desktop=GNOME Desktop
geometry=1920x1080
localhost=0
alwaysshared=1
EOF

# Define VNC port for the log message
VNC_PORT=5901

# Install the service properly for user services
systemctl --user daemon-reload
systemctl --user enable vncserver@1.service
systemctl --user restart vncserver@1.service

# After service restart
sleep 3
if ! systemctl --user is-active --quiet vncserver@1.service; then
    log_error "Service failed to start!"
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
