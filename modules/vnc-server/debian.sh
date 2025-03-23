#!/bin/bash
set -eu

log_info "Setting up VNC server for Debian/Ubuntu..."


# Install TigerVNC server and essential desktop components
sudo apt-get update
DEBIAN_FRONTEND=noninteractive sudo apt-get install -y tigervnc-standalone-server tigervnc-common xfce4 xfce4-goodies

# Create VNC config directory
VNC_CONFIG_DIR="$HOME/.vnc"
mkdir -p "$VNC_CONFIG_DIR"

# Create a xstartup file
cat > "$VNC_CONFIG_DIR/xstartup" << 'EOF'
#!/bin/sh
xrdb $HOME/.Xresources

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

dbus-launch startxfce4 &
EOF

# Make the xstartup file executable
chmod +x "$VNC_CONFIG_DIR/xstartup"

# Setup VNC password
log_info "Note: Password will be used to connect to the VNC server"
read -p "Enter your VNC password: " VNC_PASSWORD
echo "$VNC_PASSWORD" | vncpasswd

# Create systemd service for VNC (if systemd is available)
if command -v systemctl &> /dev/null; then
  log_info "Setting up VNC as a systemd service..."
  
  # Create service file
  cat > /tmp/vncserver@.service << 'EOF'
[Unit]
Description=Remote desktop service (VNC)
After=network.target

[Service]
Type=forking
User=%u
Group=%u
WorkingDirectory=%h

ExecStartPre=/bin/sh -c '/usr/bin/vncserver -kill :%i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24
ExecStop=/usr/bin/vncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF

  # Install the service
  sudo cp /tmp/vncserver@.service /etc/systemd/system/
  sudo systemctl daemon-reload
  sudo systemctl enable vncserver@1.service
  
  log_info "VNC service enabled. Start with: sudo systemctl start vncserver@1.service"
  log_info "Stop with: sudo systemctl stop vncserver@1.service"
else
  # Create a simple start script if systemd is not available
  cat > ~/start-vnc.sh << 'EOF'
#!/bin/bash
vncserver :1 -geometry 1920x1080 -depth 24
EOF
  chmod +x ~/start-vnc.sh
  
  log_info "VNC server setup completed. Start with: ~/start-vnc.sh"
  log_info "Stop with: vncserver -kill :1"
fi

# Start VNC server
log_info "Starting VNC server..."
if command -v systemctl &> /dev/null; then
  sudo systemctl start vncserver@1.service
else
  ~/start-vnc.sh
fi

# Get the IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')
log_info "VNC server started!"
log_info "Connect to $IP_ADDRESS:5901 using a VNC client" 
