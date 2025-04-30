#!/bin/bash
set -euo pipefail

is_ubuntu() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$ID" = "ubuntu" ]; then
            return 0
		fi
	fi
	return 1
}

PLATFORM_VARIANT=""

if is_ubuntu; then
    PLATFORM_VARIANT="ubuntu"
else
    PLATFORM_VARIANT="debian"
fi

# Add Docker's official GPG key:
update_package_manager
ensure_packages_installed ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL https://download.docker.com/linux/$PLATFORM_VARIANT/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$PLATFORM_VARIANT \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
update_package_manager
install_packages docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
