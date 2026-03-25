#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

echo "--- Installing Docker CE ---"

# 2. Install packages to allow apt to use a repository over HTTPS
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. Add Docker’s official GPG key
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Update the apt package index again (after adding the Docker repo)
sudo apt-get update

# 6. Install Docker Engine, containerd, and Docker Compose (optional, but good to have)
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 7. Manage Docker as a non-root user (optional but highly recommended)
# This allows you to run docker commands without `sudo`.
# Replace YOUR_USERNAME with the actual user who will be running Packer.
YOUR_USERNAME=$(whoami) # Or manually set to 'packeruser' if applicable
echo "Adding user '$YOUR_USERNAME' to the docker group..."
sudo usermod -aG docker "$YOUR_USERNAME"

echo "--- Docker installation complete! ---"
echo "You may need to log out and log back in (or run 'newgrp docker') for the docker group changes to take effect."
echo "Verify installation with: docker run hello-world"

# Verify Docker service is running
if systemctl is-active --quiet docker; then
    echo "Docker service is running."
else
    echo "Docker service is not running. Attempting to start it..."
    sudo systemctl start docker
    sudo systemctl enable docker
    if systemctl is-active --quiet docker; then
        echo "Docker service started successfully."
    else
        echo "Failed to start Docker service. Please check logs."
    fi
fi