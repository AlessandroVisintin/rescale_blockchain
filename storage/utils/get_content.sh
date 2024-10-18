#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <CID>"
    exit 1
fi

# Move to root folder
ROOTPATH="$(realpath "$(dirname "$0")")"
while [ "$ROOTPATH" != "/" ] && [ ! -f "$ROOTPATH/.env" ]; do ROOTPATH="$(dirname "$ROOTPATH")"; done
[ "$ROOTPATH" = "/" ] && { echo "ROOTPATH is root directory. Exiting."; exit 1; }
cd "$ROOTPATH"
# Import env variables
[ -f "$ROOTPATH/.env" ] && { echo "Loading environment variables from .env"; . "$ROOTPATH/.env"; }

# choose random node to execute
active="$(sudo docker ps --filter "name=^ipfs_" --format "{{.Names}}")"
readarray -t nodes <<< "$(echo -e "$active")"
[[ ${#nodes[@]} -eq 0 ]] && echo "No active IPFS nodes" && exit 1
ipfs_name=${nodes[RANDOM % ${#nodes[@]}]}

# If input is not a file/folder path, treat it as direct content to upload
timeout 5s sudo docker exec "$ipfs_name" ipfs get $1 && \
    sudo docker exec "$ipfs_name" mv "$1" /export
