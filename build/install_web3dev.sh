#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Move to root folder
ROOTPATH="$(realpath "$(dirname "$0")")"
while [ "$ROOTPATH" != "/" ] && [ ! -f "$ROOTPATH/.env" ]; do ROOTPATH="$(dirname "$ROOTPATH")"; done
[ "$ROOTPATH" = "/" ] && { echo "ROOTPATH is root directory. Exiting."; exit 1; }
cd "$ROOTPATH"
# Import env variables
[ -f "$ROOTPATH/.env" ] && { echo "Loading environment variables from .env"; . "$ROOTPATH/.env"; }


echo "Installing Node.js and Web3 in $(pwd).."

echo "Adding Ethereum repository"
sudo add-apt-repository -y ppa:ethereum/ethereum

if [ "$(find /var/lib/apt/lists/* -mtime -1 2>/dev/null | wc -l)" -eq 0 ]; then
  echo "Updating package index"
  sudo apt-get update -y
fi

echo "Upgrading system packages"
sudo apt-get upgrade -y

echo "Installing Node.js.."
sudo apt-get install -y nodejs

echo "Installing npm..."
sudo apt-get install -y npm

cd "$LEDGER" # changing directory to ledger

echo "Installing npm modules"
sudo npm install web3 solc dotenv

echo "Web3 dev installation completed successfully"
exit 0
