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
    return 1
fi
# Create the logs directory if it doesn't exist
mkdir -p "$(dirname "$ROOTPATH/$DOCKER_INSTALL_LOG_FILE")"
# Log output to a file and also display on console
exec > >(tee -i "$ROOTPATH/$DOCKER_INSTALL_LOG_FILE") 2>&1

echo -e "Starting Docker installation"

if [ "$(find /var/lib/apt/lists/* -mtime -1 2>/dev/null | wc -l)" -eq 0 ]; then
    echo -e "Updating package index"
    sudo apt-get update -y
else
  echo -e "Package index already up to date"
fi

for package in ca-certificates curl gnupg lsb-release; do
  if dpkg -l | grep -qw "$package"; then
    echo -e "Package '$package' already installed"
  else
    echo -e "Installing $package"
    sudo apt-get install -y "$package" || {
        echo -e "Failed to install $package"; 
        exit 1;
    }
  fi
done

if [ -d "$(dirname "$DOCKER_GPG_KEY_PATH")" ]; then
  echo -e "Directory for Docker GPG keyring already exists"
else
  echo -e "Creating directory for Docker GPG keyring at $DOCKER_GPG_KEY_PATH"
  sudo install -m 0755 -d "$(dirname "$DOCKER_GPG_KEY_PATH")"
fi

if [ -f "$DOCKER_GPG_KEY_PATH" ]; then
  echo -e "Docker GPG key already exists"
else
  echo -e "Adding Docker's official GPG key"
  curl -fsSL "$DOCKER_REPO_URL/gpg" | sudo gpg --dearmor -o "$DOCKER_GPG_KEY_PATH" || { 
    echo -e "Failed to add Docker GPG key";
    exit 1;
  }
  sudo chmod a+r "$DOCKER_GPG_KEY_PATH"
fi

if [ -f "/etc/apt/sources.list.d/docker.list" ]; then
  echo -e "Docker repository is already configured. Skipping..."
else
  echo -e "Adding Docker repository to Apt sources..."
  echo -e \
    "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_GPG_KEY_PATH] $DOCKER_REPO_URL \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || {
      echo -e "Failed to add Docker repository";
      exit 1;
    }
fi

echo -e "Updating package index with Docker's repository"
sudo apt-get update -y

if command_exists docker; then
  echo -e "Docker is already installed"
else
  echo -e "Installing Docker Engine and components"
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
    error "Failed to install Docker Engine";
    exit 1;
  }
fi

echo -e "Testing Docker installation"
if sudo docker run hello-world | grep -q "Hello from Docker!"; then
  echo -e "Docker is installed and working correctly!"
else
  echo -e "Docker installation test failed"
  exit 1
fi

if sudo docker images | grep -q "hyperledger/besu:$BESU_VERSION"; then
  echo -e "Hyperledger Besu Docker image ($BESU_VERSION) already exists"
else
  echo -e "Pulling Hyperledger Besu Docker image"
  sudo docker pull "hyperledger/besu:$BESU_VERSION" || {
    echo -e "Failed to pull Hyperledger Besu image"; 
    exit 1;
    }
fi

echo -e "Docker installation and setup complete"
exit 0
