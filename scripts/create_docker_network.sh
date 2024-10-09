#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
  echo "Usage: $0 <network_name> <subnet>"
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
# Create the directories if they do not exist
mkdir -p "$(dirname "$json_file")"

# Check if the JSON file exists
if [ -f "$json_file" ]; then
  # If the file exists, check if the network name is already in use
  if jq -e --arg key "$1" '.[$key] != null' "$json_file" >/dev/null; then
    echo "$1 already in use in $json_file."
    exit 1
  fi
else
  # If the JSON file does not exist, create it with an empty JSON object
  echo "{}" > "$json_file"
fi

# Create the Docker network
echo "Creating Docker network $1 : $2"
docker network create --subnet="$2" "$1"

# Check if the network was created successfully
if [ $? -eq 0 ]; then
    echo "$1 created successfully!"
else
    echo "Failed to create network '$1"
    exit 1
fi

# Create or update the JSON file with the new network details
temp_file=$(mktemp)
jq --arg key "$1" --arg value "$2" '. + {($key): $value}' "$json_file" > "$temp_file" && mv "$temp_file" "$json_file"

echo "Network details saved to $json_file"
