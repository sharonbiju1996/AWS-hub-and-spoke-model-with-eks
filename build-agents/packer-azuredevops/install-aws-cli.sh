#!/bin/bash
set -euo pipefail

# --- Configuration ---
# AWS CLI v2 Installation Script (Simplified for Build Agents)
# Optimized for Azure DevOps and other CI/CD environments

INSTALL_PATH="/usr/local/bin" # Default installation directory. Requires sudo.

# --- Script Start ---
echo "--- AWS CLI v2 Installation Script (Build Agent Version) ---"
echo "Installation Path: $INSTALL_PATH"

# 1. Detect OS and Architecture
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_TYPE=$(uname -m)

case "$OS_TYPE" in
    linux)
        AWS_OS="linux"
        ;;
    darwin)
        AWS_OS="macos"
        ;;
    *)
        echo "Error: Unsupported OS type: $OS_TYPE"
        exit 1
        ;;
esac

case "$ARCH_TYPE" in
    x86_64)
        AWS_ARCH="x86_64"
        ;;
    aarch64|arm64)
        AWS_ARCH="aarch64"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH_TYPE"
        exit 1
        ;;
esac

echo "Detected: $OS_TYPE ($AWS_ARCH)"

# 2. Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# 3. Linux Installation
if [ "$AWS_OS" = "linux" ]; then
    # Set download URL
    if [ "$AWS_ARCH" = "x86_64" ]; then
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    else
        AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
    fi
    
    # Download AWS CLI
    echo "Downloading AWS CLI from: $AWS_CLI_URL"
    curl -fsSL -o "$TEMP_DIR/awscliv2.zip" "$AWS_CLI_URL" || {
        echo "Error: Failed to download AWS CLI"
        exit 1
    }
    
    # Verify it's a ZIP file
    if ! file "$TEMP_DIR/awscliv2.zip" | grep -q "Zip"; then
        echo "Error: Downloaded file is not a valid ZIP archive"
        exit 1
    fi
    
    # Extract
    echo "Extracting AWS CLI..."
    unzip -q "$TEMP_DIR/awscliv2.zip" -d "$TEMP_DIR" || {
        echo "Error: Failed to extract AWS CLI"
        exit 1
    }
    
    # Install/Update
    echo "Installing AWS CLI..."
    if [ -d "/usr/local/aws-cli" ]; then
        # Update existing installation
        sudo "$TEMP_DIR/aws/install" --update \
            --install-dir "/usr/local/aws-cli" \
            --bin-dir "$INSTALL_PATH" || {
            echo "Error: Failed to update AWS CLI"
            exit 1
        }
    else
        # Fresh installation
        sudo "$TEMP_DIR/aws/install" \
            --install-dir "/usr/local/aws-cli" \
            --bin-dir "$INSTALL_PATH" || {
            echo "Error: Failed to install AWS CLI"
            exit 1
        }
    fi

# 4. macOS Installation
elif [ "$AWS_OS" = "macos" ]; then
    # Download installer
    echo "Downloading AWS CLI installer..."
    curl -fsSL -o "$TEMP_DIR/AWSCLIV2.pkg" \
        "https://awscli.amazonaws.com/AWSCLIV2.pkg" || {
        echo "Error: Failed to download AWS CLI installer"
        exit 1
    }
    
    # Silent installation
    echo "Installing AWS CLI..."
    sudo installer -pkg "$TEMP_DIR/AWSCLIV2.pkg" -target / || {
        echo "Error: Failed to install AWS CLI"
        exit 1
    }
fi

# 5. Verify installation
echo "Verifying installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version)
    echo "SUCCESS: $AWS_VERSION"
    echo "Location: $(which aws)"
else
    echo "Error: AWS CLI not found in PATH"
    exit 1
fi

echo "--- Installation Complete ---"