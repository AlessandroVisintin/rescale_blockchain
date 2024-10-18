#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

[[ -z "$1" || -z "$2" ]] && echo "Usage: $0 <node> <CID>" && exit 1


# choose random node to execute
ipfs_name="ipfs_$1"
active="$(sudo docker ps --filter "name=^$ipfs_name" --format "{{.Names}}")"
[ -z "$active" ] && echo "No active IPFS nodes" && exit 1

# unpin file
sudo docker exec "$ipfs_name" ipfs pin rm "$2" 2>/dev/null || true
# remove temporary copy
sudo docker exec "$ipfs_name" rm "/export/$2" 2>/dev/null || true