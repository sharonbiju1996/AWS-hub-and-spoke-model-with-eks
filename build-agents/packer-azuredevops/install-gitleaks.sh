#!/bin/bash
set -euo pipefail

# Script to install Gitleaks on various operating systems.

# --- Configuration ---
GITLEAKS_VERSION="8.27.2" # Specify the desired Gitleaks version
INSTALL_DIR="/usr/local/bin" # Default installation directory (needs sudo)
# For local user installation: INSTALL_DIR="$HOME/.local/bin"
# Ensure this directory is in your PATH for user install.

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

# Function to detect OS
detect_os() {
    OS=""
    case "$(uname -s)" in
        Linux*)  OS="Linux";;
        Darwin*) OS="macOS";;
        MINGW*|CYGWIN*|MSYS*) OS="Windows";; # Git Bash on Windows
        *)       error_exit "Unsupported operating system: $(uname -s)";;
    esac
    echo "Detected OS: $OS"
}

# Function to get architecture
get_architecture() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64) ARCH="x64";;
        arm64|aarch64) ARCH="arm64";;
        *) error_exit "Unsupported architecture: $ARCH";;
    esac
    echo "Detected Architecture: $ARCH"
}

# --- Main Script Logic ---

echo "Starting Gitleaks installation..."

# 1. Detect OS and Architecture
detect_os
get_architecture

# 2. Determine download URL based on OS and architecture
DOWNLOAD_URL=""
if [[ "$OS" == "Linux" ]]; then
    if [[ "$ARCH" == "x64" ]]; then
        DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
    elif [[ "$ARCH" == "arm64" ]]; then
        DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_arm64.tar.gz"
    fi
elif [[ "$OS" == "macOS" ]]; then
    if [[ "$ARCH" == "x64" ]]; then
        DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_darwin_x64.tar.gz"
    elif [[ "$ARCH" == "arm64" ]]; then
        DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_darwin_arm64.tar.gz"
    fi
elif [[ "$OS" == "Windows" ]]; then
    if [[ "$ARCH" == "x64" ]]; then
        DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_windows_x64.zip"
    else
        error_exit "Gitleaks on Windows only supports x64 architecture."
    fi
fi

if [[ -z "$DOWNLOAD_URL" ]]; then
    error_exit "Could not determine download URL for $OS ($ARCH)."
fi

echo "Downloading Gitleaks from: $DOWNLOAD_URL"

# 3. Download the archive
TEMP_DIR=$(mktemp -d -t gitleaks-install-XXXXXX) || error_exit "Failed to create temp directory"
ARCHIVE_PATH="$TEMP_DIR/gitleaks_archive"

if command_exists "curl"; then
    curl -L -o "$ARCHIVE_PATH" "$DOWNLOAD_URL" || error_exit "Failed to download Gitleaks using curl."
elif command_exists "wget"; then
    wget -O "$ARCHIVE_PATH" "$DOWNLOAD_URL" || error_exit "Failed to download Gitleaks using wget."
else
    error_exit "Neither curl nor wget found. Please install one of them."
fi

echo "Download complete. Extracting..."

# 4. Extract and install
if [[ "$OS" == "Windows" ]]; then
    # On Windows (Git Bash), we expect a .zip file
    if ! command_exists "unzip"; then
        error_exit "Unzip not found. Please install it (e.g., pacman -S unzip on Git Bash)."
    fi
    unzip -o "$ARCHIVE_PATH" -d "$TEMP_DIR" || error_exit "Failed to unzip Gitleaks archive."
    # The executable is usually just 'gitleaks.exe' inside the zip
    GITLEAKS_EXECUTABLE="$TEMP_DIR/gitleaks.exe"
else
    # On Linux/macOS, we expect a .tar.gz file
    if ! command_exists "tar"; then
        error_exit "Tar not found."
    fi
    tar -xzf "$ARCHIVE_PATH" -C "$TEMP_DIR" || error_exit "Failed to extract Gitleaks archive."
    # The executable is usually just 'gitleaks' inside the tar.gz
    GITLEAKS_EXECUTABLE="$TEMP_DIR/gitleaks"
fi

if [[ ! -f "$GITLEAKS_EXECUTABLE" ]]; then
    error_exit "Gitleaks executable not found after extraction at $GITLEAKS_EXECUTABLE."
fi

# Make executable
chmod +x "$GITLEAKS_EXECUTABLE" || error_exit "Failed to make Gitleaks executable."

# 5. Move to installation directory
echo "Installing Gitleaks to $INSTALL_DIR..."
sudo mkdir -p "$INSTALL_DIR" || error_exit "Failed to create installation directory $INSTALL_DIR. Check permissions."
sudo mv "$GITLEAKS_EXECUTABLE" "$INSTALL_DIR/gitleaks" || error_exit "Failed to move Gitleaks to $INSTALL_DIR. Check permissions."

# 6. Clean up
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR" || echo "Warning: Failed to remove temp directory $TEMP_DIR"

# 7. Verification
echo "Gitleaks installed successfully!"
if command_exists "gitleaks"; then
    echo "Gitleaks version:"
    gitleaks version
else
    echo "Verification failed: 'gitleaks' command not found in PATH."
    echo "Please ensure $INSTALL_DIR is in your system's PATH."
fi

echo "Installation complete."