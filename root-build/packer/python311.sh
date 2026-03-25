#!/bin/bash

# Robust Packer provisioner script to install Python 3.11 on Ubuntu 22.04
# This script should be run as part of your Packer build process

set -e  # Exit on any error

echo "=== Starting Python 3.11 Installation ==="
echo "OS Information:"
lsb_release -a

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to verify Python installation
verify_python() {
    local python_cmd="$1"
    if command_exists "$python_cmd"; then
        echo "$python_cmd is available: $($python_cmd --version)"
        return 0
    else
        echo "ERROR: $python_cmd is not available"
        return 1
    fi
}

# Update system packages
echo "=== Updating system packages ==="
sudo apt-get update
sudo apt-get upgrade -y

# Install prerequisites
echo "=== Installing prerequisites ==="
sudo apt-get install -y \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    curl \
    wget \
    build-essential \
    libssl-dev \
    libffi-dev

# Add deadsnakes PPA for Python 3.11
echo "=== Adding deadsnakes PPA ==="
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get update

# Install Python 3.11 and related packages
# Note: python3.11-pip is not available in deadsnakes PPA for Ubuntu 22.04
echo "=== Installing Python 3.11 ==="
sudo apt-get install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3.11-distutils

# Verify Python 3.11 installation
verify_python "python3.11"

# Install pip for Python 3.11 using multiple methods
echo "=== Installing pip for Python 3.11 ==="

# Method 1: Try ensurepip first (preferred method)
if sudo python3.11 -m ensurepip --upgrade 2>/dev/null; then
    echo "pip installed successfully using ensurepip"
else
    echo "ensurepip failed or not available, trying get-pip.py method"
    
    # Method 2: Use get-pip.py as fallback
    if curl -sS https://bootstrap.pypa.io/get-pip.py | sudo python3.11; then
        echo "pip installed successfully using get-pip.py"
    else
        echo "ERROR: Failed to install pip for Python 3.11"
        exit 1
    fi
fi

# Verify pip installation
echo "=== Verifying pip installation ==="
if python3.11 -m pip --version; then
    echo "pip verification successful"
else
    echo "ERROR: pip verification failed"
    exit 1
fi

# Upgrade pip to latest version
echo "=== Upgrading pip ==="
sudo python3.11 -m pip install --upgrade pip

# Create symlinks for easier access (optional)
echo "=== Creating convenient symlinks ==="
sudo ln -sf /usr/bin/python3.11 /usr/local/bin/python3.11
sudo ln -sf /usr/bin/python3.11 /usr/local/bin/py311

# Install common build tools and dependencies that are often needed
echo "=== Installing common Python build dependencies ==="
sudo apt-get install -y \
    python3.11-tk \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev

# Install some common Python packages globally that are often needed in CI/CD
echo "=== Installing common global Python packages ==="
sudo python3.11 -m pip install --upgrade setuptools wheel

# Optional: Install virtualenv globally for convenience
echo "=== Installing virtualenv ==="
sudo python3.11 -m pip install virtualenv

# Test virtual environment creation
echo "=== Testing virtual environment creation ==="
python3.11 -m venv /tmp/test-venv
source /tmp/test-venv/bin/activate
python --version
pip --version
deactivate
rm -rf /tmp/test-venv
echo "Virtual environment test successful"

# Clean up
echo "=== Cleaning up ==="
sudo apt-get autoremove -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
sudo apt-get autoclean
sudo rm -rf /var/lib/apt/lists/*

# Re-enable needrestart for future operations
unset NEEDRESTART_SUSPEND

# Final verification and information
echo "=== Installation Summary ==="
echo "Available Python versions:"
ls -la /usr/bin/python* | grep -E 'python[0-9]'
echo ""
echo "Python 3.11 location: $(which python3.11)"
echo "Python 3.11 version: $(python3.11 --version)"
echo "Python 3.11 pip version: $(python3.11 -m pip --version)"
echo ""
echo "Python 3.11 site-packages location:"
python3.11 -c "import site; print(site.getsitepackages())"

# Verify all components are working
echo "=== Final verification ==="
python3.11 -c "import sys; print(f'Python executable: {sys.executable}')"
python3.11 -c "import pip; print(f'pip version: {pip.__version__}')"

echo "=== Python 3.11 installation completed successfully ==="