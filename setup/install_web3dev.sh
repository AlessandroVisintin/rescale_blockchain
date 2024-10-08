#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Locate script
SCRIPTPATH="$(realpath "$(dirname "$0")")"
ROOTPATH="$(dirname "${SCRIPTPATH}")"
# Load configurations from .env file
if [ -f "$ROOTPATH/.env" ]; then
    echo "Loading environment variables from .env"
    . "$ROOTPATH/.env"
else
    echo "$ROOTPATH/.env not found"
    exit 1
fi

# Create the logs directory if it doesn't exist
mkdir -p "$(dirname "$ROOTPATH/$WEB3_INSTALL_LOG_FILE")"
# Log output to a file and also display on console
exec > >(tee -i "$ROOTPATH/$WEB3_INSTALL_LOG_FILE") 2>&1

echo -e "Starting Node.js and Web3 installation"

# Check if the Ethereum repository is already added
if grep -q "^deb .*$ETHEREUM_REPO" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo -e "Ethereum repository is already configured"
else
    echo -e "Adding Ethereum repository"
    sudo add-apt-repository -y ppa:ethereum/ethereum || {
        echo -e "Failed to add Ethereum repository";
        exit 1;
    }
fi

# Update system package index if needed
if [ "$(find /var/lib/apt/lists/* -mtime -1 2>/dev/null | wc -l)" -eq 0 ]; then
    echo -e "Updating package index"
    sudo apt-get update -y
else
    echo -e "Package index already up to date"
fi
# Upgrade system packages
echo -e "Upgrading system packages"
sudo apt-get upgrade -y || {
    echo -e "System upgrade failed";
    exit 1;
}

# Check if Node.js is installed
if command -v node >/dev/null 2>&1; then
    echo -e "Node.js is already installed"
else
    echo -e "Installing Node.js"
    sudo apt-get install -y nodejs || {
        echo -e "Failed to install Node.js";
        exit 1;
    }
fi
# Check if npm is installed
if command -v npm >/dev/null 2>&1; then
    echo -e "npm is already installed"
else
    echo -e "Installing npm..."
    sudo apt-get install -y npm || {
        echo -e "Failed to install npm";
        exit 1;
    }
fi
# Install or verify Web3 and solc modules
if [ -d "node_modules/web3" ] && [ -d "node_modules/solc" ]; then
    echo -e "Web3 and solc modules are already installed. Skipping..."
else
    echo -e "Installing web3 and solc modules"
    sudo npm install web3 solc || {
        echo -e "Failed to install web3 and solc modules";
        exit 1;
    }
fi

echo -e "Node.js and Web3 installation completed successfully"
exit 0
