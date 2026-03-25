#!/bin/bash

command_exists () {
    type "$1" &> /dev/null ;
}

java_version_check () {
    if command_exists java; then
        java_ver=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}' | cut -d'.' -f1)
        if [ "$java_ver" = "17" ]; then
            return 0
        fi
    fi
    return 1
}

echo "Starting Java 17 installation script..."

# 1. Check if Java 17 is already installed
echo "Checking for Java 17..."
if java_version_check; then
    echo "Java 17 is already installed."
    java -version
    echo "Java 17 installation script finished."
    exit 0
fi

echo "Java 17 not found or different version detected. Installing Java 17..."

# Detect OS distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS distribution. Assuming Ubuntu/Debian..."
    OS="ubuntu"
fi

echo "Detected OS: $OS"

# 2. Install Java 17 based on distribution
case $OS in
    ubuntu|debian)
        echo "Installing Java 17 on Ubuntu/Debian..."
        
        # Update package list
        sudo apt-get update
        
        # Method 1: Try OpenJDK 17 from default repositories
        echo "Attempting to install OpenJDK 17 from default repositories..."
        sudo apt-get install -y openjdk-17-jdk
        
        if [ $? -eq 0 ] && java_version_check; then
            echo "Java 17 installed successfully from default repositories."
        else
            echo "Default repository installation failed. Trying alternative method..."
            
            # Method 2: Add OpenJDK PPA and install (for older Ubuntu versions)
            echo "Adding OpenJDK PPA and installing Java 17..."
            sudo apt-get install -y software-properties-common
            sudo add-apt-repository ppa:openjdk-r/ppa -y
            sudo apt-get update
            sudo apt-get install -y openjdk-17-jdk
            
            if [ $? -eq 0 ] && java_version_check; then
                echo "Java 17 installed successfully from PPA."
            else
                echo "Error: Failed to install Java 17 via apt methods."
                exit 1
            fi
        fi
        
        # Set JAVA_HOME
        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
        echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> ~/.bashrc
        ;;
        
    centos|rhel|fedora)
        echo "Installing Java 17 on CentOS/RHEL/Fedora..."
        
        if command_exists dnf; then
            # Fedora/newer RHEL/CentOS
            echo "Using dnf package manager..."
            sudo dnf update -y
            sudo dnf install -y java-17-openjdk-devel
        elif command_exists yum; then
            # Older CentOS/RHEL
            echo "Using yum package manager..."
            sudo yum update -y
            sudo yum install -y java-17-openjdk-devel
        else
            echo "Error: Neither dnf nor yum package manager found."
            exit 1
        fi
        
        if [ $? -eq 0 ] && java_version_check; then
            echo "Java 17 installed successfully."
        else
            echo "Error: Failed to install Java 17."
            exit 1
        fi
        
        # Set JAVA_HOME for RHEL-based systems
        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
        echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk" >> ~/.bashrc
        ;;
        
    alpine)
        echo "Installing Java 17 on Alpine Linux..."
        sudo apk update
        sudo apk add openjdk17-jdk
        
        if [ $? -eq 0 ] && java_version_check; then
            echo "Java 17 installed successfully on Alpine."
        else
            echo "Error: Failed to install Java 17 on Alpine."
            exit 1
        fi
        
        # Set JAVA_HOME for Alpine
        export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
        echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk" >> ~/.bashrc
        ;;
        
    *)
        echo "Unsupported OS: $OS"
        echo "Please install Java 17 manually for your distribution."
        exit 1
        ;;
esac

# 3. Verify installation
echo "Verifying Java 17 installation..."
if java_version_check; then
    echo "Java 17 installation verified successfully!"
    java -version
    echo "JAVA_HOME: $JAVA_HOME"
    
    # Also install javac if not present (development tools)
    if ! command_exists javac; then
        echo "Warning: javac (Java compiler) not found. You may need JDK instead of JRE."
    else
        echo "Java compiler (javac) is available."
        javac -version
    fi
else
    echo "Error: Java 17 installation verification failed."
    echo "Current Java version:"
    java -version 2>&1 || echo "Java not found in PATH"
    exit 1
fi

# 4. Set Java 17 as default (for systems with multiple Java versions)
echo "Setting Java 17 as default..."
if command_exists update-alternatives; then
    # Ubuntu/Debian systems
    java_path=$(which java)
    if [ -n "$java_path" ]; then
        sudo update-alternatives --install /usr/bin/java java $java_path 1
        sudo update-alternatives --set java $java_path
        echo "Java 17 set as default using update-alternatives."
    fi
elif command_exists alternatives; then
    # RHEL/CentOS systems
    java_path=$(which java)
    if [ -n "$java_path" ]; then
        sudo alternatives --install /usr/bin/java java $java_path 1
        sudo alternatives --set java $java_path
        echo "Java 17 set as default using alternatives."
    fi
fi

echo "Java 17 installation script finished successfully!"
echo ""
echo "To use Java 17 in new shell sessions, either:"
echo "1. Source your bashrc: source ~/.bashrc"
echo "2. Or start a new shell session"
echo ""
echo "Current Java version:"
java -version