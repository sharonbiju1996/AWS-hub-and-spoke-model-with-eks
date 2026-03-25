#!/bin/bash
set -euo pipefail

# --- Configuration ---
# Set the desired Terraform version here.
# You can find the latest versions on https://releases.hashicorp.com/terraform/
TERRAFORM_VERSION="1.12.2" # <--- IMPORTANT: Update to the version you need!

INSTALL_PATH="/usr/local/bin" # Default installation directory. Requires sudo.
                              # For user-specific install without sudo:
                              # INSTALL_PATH="$HOME/.local/bin" or "$HOME/bin"
                              # Ensure this path is in your user's PATH environment variable.

# --- Script Start ---
set -e # Exit immediately if a command exits with a non-zero status

echo "--- Terraform Installation Script ---"
echo "Target Terraform Version: $TERRAFORM_VERSION"
echo "Installation Path: $INSTALL_PATH"

# 1. Detect OS and Architecture
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_TYPE=$(uname -m)

case "$OS_TYPE" in
    linux)
        TERRAFORM_OS="linux"
        ;;
    darwin)
        TERRAFORM_OS="darwin"
        ;;
    *)
        echo "Error: Unsupported OS type: $OS_TYPE. This script supports Linux and macOS."
        exit 1
        ;;
esac

case "$ARCH_TYPE" in
    x86_64)
        TERRAFORM_ARCH="amd64"
        ;;
    arm64) # For Apple M1/M2/M3 or ARM-based Linux servers (e.g., AWS Graviton)
        TERRAFORM_ARCH="arm64"
        ;;
    *)
        echo "Error: Unsupported architecture: $ARCH_TYPE. This script supports x86_64 and arm64."
        exit 1
        ;;
esac

echo "Detected OS: $OS_TYPE ($TERRAFORM_OS), Architecture: $ARCH_TYPE ($TERRAFORM_ARCH)"

TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_${TERRAFORM_OS}_${TERRAFORM_ARCH}.zip"
TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP}"
SHA256SUMS_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS"

# 2. Create a temporary directory for downloads
TEMP_DIR=$(mktemp -d)
if [ ! -d "$TEMP_DIR" ]; then
    echo "Error: Failed to create temporary directory."
    exit 1
fi
echo "Using temporary directory: $TEMP_DIR"

# 3. Download Terraform zip and SHA256SUMS file
echo "Downloading Terraform from: $TERRAFORM_URL"
curl -sSL -o "${TEMP_DIR}/${TERRAFORM_ZIP}" "$TERRAFORM_URL" || { echo "Error: Failed to download Terraform zip."; rm -rf "$TEMP_DIR"; exit 1; }

echo "Downloading SHA256SUMS from: $SHA256SUMS_URL"
curl -sSL -o "${TEMP_DIR}/terraform_SHA256SUMS" "$SHA256SUMS_URL" || { echo "Error: Failed to download SHA256SUMS file."; rm -rf "$TEMP_DIR"; exit 1; }

# 4. Verify checksum for integrity and security
echo "Verifying checksum..."
pushd "$TEMP_DIR" > /dev/null # Change directory quietly
if ! grep "${TERRAFORM_ZIP}" terraform_SHA256SUMS | sha256sum --check --status; then
    echo "Error: Checksum verification failed for $TERRAFORM_ZIP. The downloaded file might be corrupted or tampered with."
    popd > /dev/null # Go back to original directory
    rm -rf "$TEMP_DIR"
    exit 1
fi
popd > /dev/null # Go back to original directory
echo "Checksum verified successfully."

# 5. Unzip Terraform binary
echo "Unzipping Terraform to $TEMP_DIR..."
unzip -q "${TEMP_DIR}/${TERRAFORM_ZIP}" -d "$TEMP_DIR" || { echo "Error: Failed to unzip Terraform."; rm -rf "$TEMP_DIR"; exit 1; }

# 6. Install Terraform by moving the binary to the target path
echo "Installing Terraform binary to $INSTALL_PATH..."
if [ ! -d "$INSTALL_PATH" ]; then
    echo "Creating installation directory: $INSTALL_PATH"
    sudo mkdir -p "$INSTALL_PATH" || { echo "Error: Failed to create $INSTALL_PATH. Check permissions or create manually."; rm -rf "$TEMP_DIR"; exit 1; }
fi

# Move the binary. Use sudo if INSTALL_PATH requires root permissions (like /usr/local/bin)
# For Azure DevOps agents, /usr/local/bin usually requires sudo.
if ! sudo mv "${TEMP_DIR}/terraform" "$INSTALL_PATH/"; then
    echo "Error: Failed to move Terraform binary to $INSTALL_PATH. Check permissions."
    rm -rf "$TEMP_DIR"
    exit 1
fi
echo "Terraform binary moved successfully."

# 7. Clean up temporary files
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
echo "Temporary files removed."

# 8. Verify installation
echo "Verifying Terraform installation..."
if command -v terraform &> /dev/null; then
    echo "Terraform installed successfully:"
    terraform version
else
    echo "Error: Terraform command not found in PATH after installation."
    echo "Please ensure $INSTALL_PATH is in your system's PATH environment variable."
    exit 1
fi

echo "--- Terraform Installation Complete ---"