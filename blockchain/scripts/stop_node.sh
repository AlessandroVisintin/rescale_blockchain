#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if the required argument (node name) is provided
if [ "$#" -lt 1 ]; then
    echo -e "Usage: $0 <node_name>"
    exit 1
fi

# Node name is the first argument
NODE_NAME="$1"
# Check if the container is running
CONTAINER_ID=$(docker ps --filter "name=$NODE_NAME" --format "{{.ID}}")
if [ -z "$CONTAINER_ID" ]; then
    echo -e "$NODE_NAME not found"
    exit 1
fi

echo -e "Stopping $NODE_NAME with ID $CONTAINER_ID"
docker stop "$CONTAINER_ID"

find $(pwd) -type f -name "*.jfr" -delete