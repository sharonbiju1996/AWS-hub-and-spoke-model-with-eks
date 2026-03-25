#!/bin/bash
set -euo pipefail

echo "--- Starting Azure CLI Installation Script ---"

# Check if Azure CLI is already installed
if command -v az &> /dev/null; then
    echo "Azure CLI is already installed. Version: $(az --version | head -n 1)"
    exit 0
fi

echo "Azure CLI not found. Proceeding with installation..."

# Detect Linux distribution
# Using /etc/os-release for broader compatibility
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION_ID=$VERSION_ID
else
    echo "ERROR: Cannot detect OS distribution. /etc/os-release not found."
    exit 1
fi

echo "Detected OS: $OS_ID (Version: $OS_VERSION_ID)"

case "$OS_ID" in
    ubuntu|debian)
        echo "Installing Azure CLI for Debian/Ubuntu..."
        sudo apt update -y
        sudo apt install -y ca-certificates curl apt-transport-https lsb-release gnupg

        # Add Microsoft GPG key
        sudo curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

        # Add Azure CLI repository
        AZ_REPO=$(lsb_release -cs) # Gets the codename (e.g., jammy, focal, bullseye)
        echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
            sudo tee /etc/apt/sources.list.d/azure-cli.list > /dev/null

        sudo apt update -y
        sudo apt install -y azure-cli

        echo "Azure CLI installation for Debian/Ubuntu complete."
        ;;
    rhel|centos|fedora|ol) # RedHat, CentOS, Fedora, Oracle Linux (compatible with yum/dnf)
        echo "Installing Azure CLI for RHEL/CentOS/Fedora/Oracle Linux..."

        # Add Microsoft repository
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'

        if command -v dnf &> /dev/null; then
            # Fedora, RHEL 8+, CentOS Stream 8+
            echo "Using dnf for installation..."
            sudo dnf install -y azure-cli
        elif command -v yum &> /dev/null; then
            # RHEL 7, CentOS 7
            echo "Using yum for installation..."
            sudo yum install -y azure-cli
        else
            echo "ERROR: Neither dnf nor yum found. Cannot install Azure CLI."
            exit 1
        fi

        echo "Azure CLI installation for RHEL/CentOS/Fedora/Oracle Linux complete."
        ;;
    *)
        echo "ERROR: Unsupported OS distribution: $OS_ID. Please install Azure CLI manually."
        exit 1
        ;;
esac

# Verify installation
if command -v az &> /dev/null; then
    echo "Azure CLI successfully installed. Version:"
    az --version
else
    echo "ERROR: Azure CLI installation failed. 'az' command not found."
    exit 1
fi

echo "--- Azure CLI Installation Script Finished ---"