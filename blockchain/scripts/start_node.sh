#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if the required argument (node name) is provided
if [ "$#" -lt 1 ]; then
    echo -e "Usage: $0 <node_name> [<bootnode1> <bootnode2> ...]"
    exit 1
fi

# Node name is the first argument
NODE_NAME="$1"
shift

# The remaining arguments are bootnodes (optional)
BOOTNODES="$@"
BOOTNODE_LIST=""
if [ ${#BOOTNODES[@]} -gt 0 ]; then
    BOOTNODE_LIST=$(IFS=','; echo "${BOOTNODES[*]}")
fi

# Load environment variables from the .env file
SCRIPTPATH="$(realpath "$(dirname "$0")")"
ROOTPATH="$(dirname "$(dirname "${SCRIPTPATH}")")"
if [ -f "$ROOTPATH/.env" ]; then
    echo -e "Loading environment variables from .env"
    . "$ROOTPATH/.env"
else
    echo -e "$ROOTPATH/.env not found"
    exit 1
fi

# Check if the node directory exists
node_path="$ROOTPATH/$BLOCKCHAIN_NODES/$NODE_NAME"
if [ ! -d "$node_path" ]; then
    echo -e "$NODE_NAME not found in $BLOCKCHAIN_NODES"
    exit 1
fi

DOCKER_CMD="docker run --rm \
    -v \"$node_path:/node\" \
    -v \"$ROOTPATH/$BLOCKCHAIN_CONFIGS:/configs\" \
    -w /besu \
    -p \"$BESU_P2P_PORT:$BESU_P2P_PORT\" \
    -p \"$BESU_RPC_PORT:$BESU_RPC_PORT\" \
    --name \"$NODE_NAME\" \
    hyperledger/besu:$BESU_VERSION \
    --min-gas-price=0 \
    --data-path=/node \
    --genesis-file=/configs/genesis.json \
    --p2p-port=\"$BESU_P2P_PORT\" \
    --rpc-http-enabled \
    --rpc-http-host=0.0.0.0 \
    --rpc-http-api=ETH,NET,QBFT \
    --host-allowlist=\"*\" \
    --rpc-http-cors-origins=\"all\" \
    --rpc-http-port=\"$BESU_RPC_PORT\""

if [ -n "$BOOTNODE_LIST" ]; then
    DOCKER_CMD="$DOCKER_CMD --bootnodes=\"$BOOTNODE_LIST\""
fi

# Append log redirection and run in the background
DOCKER_CMD="$DOCKER_CMD > \"$node_path/run.log\" 2>&1 &"

echo -e "Starting $NODE_NAME"
eval $DOCKER_CMD

while [ ! -f "$node_path/besu.networks" ]; do
    sleep 0.5
done
echo -e "$NODE_NAME started successfully"
