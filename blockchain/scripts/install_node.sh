#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Locate script paths
SCRIPTPATH="$(realpath "$(dirname "$0")")"
ROOTPATH="$(dirname "$(dirname "${SCRIPTPATH}")")"
# Load configurations from .env file
if [ -f "$ROOTPATH/.env" ]; then
    echo "Loading environment variables from .env"
    . "$ROOTPATH/.env"
else
    echo "$ROOTPATH/.env not found"
    return 1
fi
# Create the logs directory if it doesn't exist
mkdir -p "$(dirname "$ROOTPATH/$NODE_INSTALL_LOG_FILE")"
# Log output to a file and also display on console
exec > >(tee -i "$ROOTPATH/$NODE_INSTALL_LOG_FILE") 2>&1

NODE_NAME=""
# Parse command-line
if [[ "$#" -eq 1 ]]; then
    NODE_NAME="$1"
fi
# Determine the node path based on user input or generate a sequential name
mkdir -p "$ROOTPATH/$BLOCKCHAIN_NODES"
if [ -z "$NODE_NAME" ]; then
    i=0
    while [ -d "$ROOTPATH/$BLOCKCHAIN_NODES/node$i" ]; do
        i=$((i+1))
    done
    NODE_NAME="node$i"
fi

echo -e "Installing $NODE_NAME"
node_path="$ROOTPATH/$BLOCKCHAIN_NODES/$NODE_NAME"
mkdir -p "$node_path"

docker run --rm \
    -v "$ROOTPATH":/besu \
    -w /besu \
    hyperledger/besu:$BESU_VERSION operator generate-blockchain-config \
    --config-file=$BLOCKCHAIN_CONFIGS/qbftConfigFile.json \
    --to="$BLOCKCHAIN_NODES/$NODE_NAME" \
    --private-key-file-name=key

hex_dir=$(find "$node_path/keys" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
if [ -z "$hex_dir" ]; then
    echo -e "No subdirectory found in $node_path/keys"
    exit 1
fi

if [ -f "$node_path/keys/$hex_dir/key" ]; then
    mv "$node_path/keys/$hex_dir/key" "$node_path/key"
    echo -e "Private key file moved to $NODE_NAME/key"
else
    echo -e "Private key file not found at $node_path/keys/$hex_dir/key"
    exit 1
fi

if [ -f "$node_path/keys/$hex_dir/key.pub" ]; then
    mv "$node_path/keys/$hex_dir/key.pub" "$node_path/key.pub"
    echo -e "Private key file moved to $NODE_NAME/key.pub"
else
    echo "Public key file not found at $node_path/keys/$hex_dir/key.pub"
    exit 1
fi

echo "Removing keys directory from $NODE_NAME"
rm -rf "$node_path/keys"

echo "Removing genesis.json from $NODE_NAME"
rm "$node_path/genesis.json"

echo -e "Removing .jfr log files"
find $(pwd) -type f -name "*.jfr" -delete

echo -e "$NODE_NAME installed successfully in $BLOCKCHAIN_NODES"
