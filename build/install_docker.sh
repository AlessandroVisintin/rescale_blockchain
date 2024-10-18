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


echo "Installing docker images for BESU / IPFS.."

if [ "$(find /var/lib/apt/lists/* -mtime -1 2>/dev/null | wc -l)" -eq 0 ]; then
  echo "Updating package index"
  sudo apt-get update -y 
fi

echo "Installing packages.."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

[ ! -d "$(dirname "$DOCKER_GPG_KEY")" ] && { 
  echo "Creating $DOCKER_GPG_KEY_PATH";
  sudo install -m 0755 -d "$(dirname "$DOCKER_GPG_KEY_PATH")";
}

[ ! -f "$DOCKER_GPG_KEY" ] && {
  echo "Adding Docker's GPG key";
  curl -fsSL "$DOCKER_REPO_URL/gpg" | \
  sudo gpg --dearmor -o "$DOCKER_GPG_KEY" && \
  sudo chmod a+r "$DOCKER_GPG_KEY"
}

[ ! -f "/etc/apt/sources.list.d/docker.list" ] && {
  echo "Adding Docker repository to Apt sources...";
  echo "deb [arch=$(dpkg --print-architecture) signed-by=$DOCKER_GPG_KEY] \
    $DOCKER_REPO_URL $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}


echo "Updating package index with Docker's repository"
sudo apt-get update -y

echo "Installing Docker Engine and components"
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "Testing Docker installation.."
sudo docker run hello-world | \
  grep -q "Hello from Docker!" && \
  echo "Working correctly" || { echo "Test failed"; exit 1; }

echo "Pulling Hyperledger Besu Docker image.."
sudo docker pull "hyperledger/besu:$BESU_VERSION"

echo "Pulling IPFS Docker image.."
sudo docker pull "ipfs/kubo:$IPFS_VERSION"

echo -e "Docker BESU / IPFS setup completed"
exit 0
