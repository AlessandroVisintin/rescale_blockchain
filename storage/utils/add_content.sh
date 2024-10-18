#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <content (either path or string)> [--pin]"
    exit 1
fi

PIN=false
for arg in "$@"; do
    if [ "$arg" == "--pin" ]; then
        PIN=true
        break
    fi
done

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
node_name=${ipfs_name#ipfs_}

# If input is not a file/folder path, treat it as direct content to upload
path=$1
exp="$STORAGE_NODES/$node_name/export"
if [ ! -e "$1" ]; then
    path="$exp/.tmp"
    echo "Adding $1 to $path"
    echo "$1" > "$path"
fi

# Only copy if the paths are different
srcpath=$(realpath "$(dirname "$path")")
dstpath=$(realpath "$exp")
if [ "$srcpath" != "$dstpath" ]; then
    cp -r "$path" "$STORAGE_NODES/$node_name/export"
fi
        
# add to IPFS with optional pin
sudo docker exec "$ipfs_name" ipfs add -r ${PIN:+--pin} "/export/$(basename $path)"
# remove temporary copy
sudo docker exec "$ipfs_name" rm /export/$(basename $path)