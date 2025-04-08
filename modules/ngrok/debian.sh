#!/bin/bash
set -euo pipefail

curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
  && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list \
  && sudo apt update \
  && sudo apt install ngrok

log_success "ngrok installed successfully!"

# Create 'ngrok' user
sudo useradd -r -s /bin/false ngrok

# Create ngrok directory
sudo mkdir -p /opt/ngrok
sudo chown -R ngrok:ngrok /opt/ngrok

# Read auth token from user
read -p "Enter your ngrok auth token: " NGROK_AUTH_TOKEN

# Set auth token
sudo -u ngrok ngrok config add-authtoken $NGROK_AUTH_TOKEN

log_success "ngrok auth token set successfully!"

# Create systemd service
sudo tee /etc/systemd/system/ngrok.service >/dev/null <<EOF
[Unit]
Description=ngrok service for SSH
After=network.target

[Service]
User=ngrok
Group=ngrok
ExecStart=/usr/local/bin/ngrok tcp 22 --config=/opt/ngrok/ngrok.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start ngrok service
sudo systemctl enable ngrok
sudo systemctl start ngrok
