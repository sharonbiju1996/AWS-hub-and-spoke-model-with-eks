#!/bin/bash
set -euo pipefail

echo "--- Starting kubectl Installation Script ---"

KUBECTL_INSTALL_DIR="/usr/local/bin" # Common directory in PATH

# Check if kubectl is already installed
if command -v kubectl &> /dev/null; then
    echo "kubectl is already installed. Version: $(kubectl version --client --short)"
    echo "Skipping installation."
    exit 0
fi

echo "kubectl not found. Proceeding with installation..."

# Determine OS
OS=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="darwin"
else
    echo "ERROR: Unsupported operating system: $OSTYPE. This script supports Linux and macOS."
    exit 1
fi

KUBECTL_LATEST_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
KUBECTL_DOWNLOAD_URL="https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_LATEST_VERSION}/bin/${OS}/amd64/kubectl"

echo "Detected OS: ${OS}"
echo "Latest kubectl version: ${KUBECTL_LATEST_VERSION}"
echo "Download URL: ${KUBECTL_DOWNLOAD_URL}"

# For macOS, prefer Homebrew for easier management
if [ "${OS}" == "darwin" ]; then
    echo "Detected macOS. Attempting to install via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install kubectl
        if [ $? -eq 0 ]; then
            echo "kubectl installed successfully via Homebrew."
            # Verify installation
            if command -v kubectl &> /dev/null; then
                echo "Verification successful. Version:"
                kubectl version --client --short
            fi
            exit 0
        else
            echo "WARNING: Homebrew installation failed. Falling back to manual download."
        fi
    else
        echo "WARNING: Homebrew not found. Falling back to manual download."
    fi
fi

# Manual download and installation for Linux or if Homebrew failed
echo "Downloading kubectl binary..."
curl -sSL -o /tmp/kubectl "${KUBECTL_DOWNLOAD_URL}"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to download kubectl. Please check your internet connection or the URL."
    exit 1
fi
echo "Download complete. Making it executable..."
chmod +x /tmp/kubectl

echo "Moving kubectl to ${KUBECTL_INSTALL_DIR}..."
sudo mv /tmp/kubectl "${KUBECTL_INSTALL_DIR}/kubectl"
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to move kubectl to ${KUBECTL_INSTALL_DIR}. Do you have sudo permissions?"
    exit 1
fi
echo "kubectl moved to ${KUBECTL_INSTALL_DIR}."

# Verify installation
if command -v kubectl &> /dev/null; then
    echo "kubectl successfully installed. Version:"
    kubectl version --client
else
    echo "ERROR: kubectl installation failed. 'kubectl' command not found after install."
    exit 1
fi

echo "--- kubectl Installation Script Finished ---"