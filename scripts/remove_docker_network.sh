#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if the correct number of arguments is provided
if [ $# -ne 1 ]; then
  echo "Usage: $0 <network_name>"
  exit 1
fi

# Locate script paths
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

# Define the path to the JSON file
json_file="$ROOTPATH/$BLOCKCHAIN_CONFIGS/networks.json"

# Remove the Docker network
docker network rm "$1"

# Check if the network was removed successfully
if [ $? -eq 0 ]; then
    echo "Network '$1' removed successfully"
else
    echo "Failed to remove network '$1'"
fi

# Check if the JSON file exists
if [ ! -f "$json_file" ]; then
  echo "$json_file does not exist. Cannot remove network details."
  exit 1
fi

# Check if the network name is in the JSON file
if jq -e --arg key "$1" '.[$key] != null' "$json_file" >/dev/null; then
    echo "Removing Docker network $1"

    # Remove the network entry from the JSON file
    temp_file=$(mktemp)
    jq --arg key "$1" 'del(.[$key])' "$json_file" > "$temp_file" && mv "$temp_file" "$json_file"

    echo "Network entry removed from $json_file"
else
    echo "Network name '$1' not found in $json_file."
    exit 1
fi
