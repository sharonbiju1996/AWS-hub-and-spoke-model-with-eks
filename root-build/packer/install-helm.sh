#!/bin/bash

command_exists () {
    type "$1" &> /dev/null ;
}

echo "Starting Helm installation script..."

# 1. Install Helm
echo "Checking for Helm..."
if ! command_exists helm; then
    echo "Helm not found. Installing Helm..."

    # Official Helm installation script (recommended for latest stable)
    # This script automates downloading the latest binary and placing it in /usr/local/bin
    echo "Downloading and running official get_helm.sh script..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    if [ $? -eq 0 ]; then
        echo "Helm installed successfully."
        helm version # Verify installation
    else
        echo "Error: Failed to install Helm using the official script. Attempting alternative method..."
        # Fallback to apt method (may be slightly older version)
        # Add the Helm apt repository
        curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
        sudo apt-get install apt-transport-https --yes
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
        sudo apt-get update
        sudo apt-get install -y helm

        if [ $? -eq 0 ]; then
            echo "Helm installed successfully via apt."
            helm version
        else
            echo "Error: Failed to install Helm via apt as well. Please check for network issues or repository problems."
            exit 1
        fi
    fi
else
    echo "Helm is already installed."
fi

echo "Helm installation script finished."