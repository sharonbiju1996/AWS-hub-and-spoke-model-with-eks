#!/bin/bash
set -euo pipefail

# Script to install Checkov on Ubuntu

# --- Configuration ---
INSTALL_METHOD="pip" # Currently only 'pip' is directly supported by this script
# INSTALL_LOCATION="global" # Set to "global" for /usr/local/bin (needs sudo) or "user" for ~/.local/bin
# For this script, we'll default to global as it covers most use cases for CI/CD or system-wide tools.

# --- Functions ---

# Function to display error messages and exit
error_exit() {
    echo -e "\e[31mERROR: $1\e[0m" >&2
    exit 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Main Script Logic ---

echo "Starting Checkov installation on Ubuntu..."

# 1. Ensure running on Ubuntu (basic check)
if ! command_exists "apt"; then
    error_exit "This script is designed for Debian/Ubuntu-based systems (apt command not found)."
fi

# 2. Update apt package list
echo "Updating apt package list..."
sudo apt update || error_exit "Failed to update apt package list."

# 3. Install Python3 and Pip if not already present
echo "Installing Python3, pip, and necessary development libraries..."
# python3-pip: for installing python packages
# python3-dev: headers for compiling Python extensions (sometimes needed by Checkov's dependencies)
# build-essential: provides gcc, make, etc. for compiling
# libffi-dev, libssl-dev: common dependencies for cryptography-related Python packages
sudo apt install -y python3-pip python3-dev build-essential libffi-dev libssl-dev || \
    error_exit "Failed to install Python3, pip, or development libraries."

# 4. Install Checkov using pip
echo "Installing Checkov via pip..."
# Install globally (requires sudo)
sudo pip3 install checkov || error_exit "Failed to install Checkov via pip."

# Optional: If you wanted to install per-user (without sudo for pip part), you'd use:
# pip3 install --user checkov
# And ensure ~/.local/bin is in your PATH. This script focuses on global for simplicity.

# 5. Verify installation
echo "Verifying Checkov installation..."
if command_exists "checkov"; then
    echo "Checkov installed successfully!"
    echo "Checkov version:"
    checkov --version
else
    error_exit "Checkov command not found after installation. Something went wrong."
fi

echo "Checkov installation complete."