#!/bin/bash
set -euo pipefail

# Script to install Trivy - a comprehensive vulnerability scanner.

# --- Configuration ---
INSTALL_DIR="/usr/local/bin" # Default installation directory for the binary
# For local user installation: INSTALL_DIR="$HOME/.local/bin"
# Ensure this directory is in your PATH for user install if you change it.

# --- Functions ---

# Function to display error messages and exit
error_exit() {
    echo -e "\e[31mERROR: $1\e[0m" >&2
    exit 1
}

# Function to display informational messages
info_msg() {
    echo -e "\e[34mINFO: $1\e[0m"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect OS
detect_os() {
    OS=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian) OS="Debian_Ubuntu";;
            centos|rhel|fedora) OS="RedHat_CentOS";;
            *) ;;
        esac
    elif [ "$(uname -s)" == "Darwin" ]; then
        OS="macOS"
    fi

    if [[ -z "$OS" ]]; then
        error_exit "Unsupported operating system. This script supports Debian/Ubuntu, RedHat/CentOS, and macOS."
    fi
    info_msg "Detected OS: $OS"
}

# Function to install Trivy using package managers
install_with_package_manager() {
    case "$OS" in
        "Debian_Ubuntu")
            info_msg "Attempting to install Trivy using APT..."
            sudo apt-get update || error_exit "Failed to update APT packages."
            sudo apt-get install -y wget apt-transport-https gnupg lsb-release || error_exit "Failed to install APT prerequisites."
            
            # Add GPG key
            wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null || error_exit "Failed to add Trivy GPG key."
            
            # Add Trivy repository
            echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list || error_exit "Failed to add Trivy repository."
            
            sudo apt-get update || error_exit "Failed to update APT packages after adding Trivy repo."
            sudo apt-get install -y trivy || error_exit "Failed to install Trivy via APT."
            ;;
        "RedHat_CentOS")
            info_msg "Attempting to install Trivy using YUM/DNF..."
            sudo yum install -y yum-utils || sudo dnf install -y yum-utils || error_exit "Failed to install yum-utils."
            
            # Use 'rpm' command to get releasever correctly for older systems if 'lsb_release' not available
            RELEASEVER=$(rpm -E %{rhel} || rpm -E %{fedora} || echo "8") # Fallback to 8 if detection fails
            info_msg "Detected RHEL/CentOS release version: $RELEASEVER"
            
            sudo yum-config-manager --add-repo https://aquasecurity.github.io/trivy-repo/rpm/releases/${RELEASEVER}/x86_64/ || error_exit "Failed to add Trivy RPM repository."
            sudo rpm --import https://aquasecurity.github.io/trivy-repo/rpm/public.key || error_exit "Failed to import Trivy GPG key."
            sudo yum -y update || sudo dnf -y update || error_exit "Failed to update packages."
            sudo yum -y install trivy || sudo dnf -y install trivy || error_exit "Failed to install Trivy via YUM/DNF."
            ;;
        "macOS")
            info_msg "Attempting to install Trivy using Homebrew..."
            if ! command_exists "brew"; then
                info_msg "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error_exit "Failed to install Homebrew."
            fi
            brew install trivy || error_exit "Failed to install Trivy via Homebrew."
            ;;
        *)
            error_exit "Unsupported OS for package manager installation: $OS"
            ;;
    esac
}

# Function to install Trivy using the official install script (fallback)
install_with_official_script() {
    info_msg "Falling back to official install script for Trivy..."
    if ! command_exists "curl"; then
        error_exit "Curl is required for this installation method but not found."
    fi
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b "$INSTALL_DIR" || error_exit "Failed to install Trivy using official script."
}

# --- Main Script Logic ---

# Set strict mode for the script
set -euo pipefail

info_msg "Starting Trivy installation..."

# 1. Detect OS
detect_os

# 2. Try to install with OS-specific package manager
if install_with_package_manager; then
    info_msg "Trivy installed successfully using package manager."
else
    # 3. If package manager fails or not supported, use the official script
    info_msg "Package manager installation failed or not applicable. Attempting fallback method."
    install_with_official_script
fi

# 4. Verification
info_msg "Verifying Trivy installation..."
if command_exists "trivy"; then
    echo -e "\e[32mTrivy installed successfully!\e[0m"
    echo "Trivy version:"
    trivy --version
else
    error_exit "Trivy command not found after installation. Something went wrong."
fi

info_msg "Trivy installation complete."