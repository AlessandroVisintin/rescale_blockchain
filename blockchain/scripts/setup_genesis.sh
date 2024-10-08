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
mkdir -p "$(dirname "$ROOTPATH/$GENESIS_SETUP_LOG_FILE")"
# Log output to a file and also display on console
exec > >(tee -i "$ROOTPATH/$GENESIS_SETUP_LOG_FILE") 2>&1

# Check if at least one node name is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <node_name1> <node_name2> ... <node_nameN>"
    exit 1
fi

qbft_path="$ROOTPATH/$BLOCKCHAIN_CONFIGS/qbftConfigFile.json"
if [ ! -f "qbft_path" ]; then
    echo "QBFT config file not found at $BLOCKCHAIN_CONFIGS"
    exit 1
fi

# Read addresses for the given node names
declare -a node_addresses
for NODE_NAME in "$@"; do
    address_path="$ROOTPATH/$BLOCKCHAIN_NODES/$NODE_NAME/besu.address"
    if [ -f "$address_path" ]; then
        node_address=$(cat "$address_path" | tr -d '\n')
        if [ -z "$node_address" ]; then
            echo "$address_path is empty"
            exit 1
        fi
        node_addresses+=("$NODE_ADDRESS")
    else
        echo "Address not found at $BLOCKCHAIN_NODES/$NODE_NAME"
        exit 1
    fi
done

# Generate extra data JSON structure for RLP encoding
addresses_format=$(printf '",\n    "%s"' "${node_addresses[@]}")
cat <<EOF > "$ROOTPATH/$BLOCKCHAIN_CONFIGS/validators.json"
{
  "validators": [${addresses_format:3}],
  "vote": [],
  "round": 0,
  "proposerSeal": ""
}
EOF

#[
#  "0x4592c8e45706cc08b8f44b11e43cba0cfc5892cb",
#  "0x06e23768a0f59cf365e18c2e0c89e151bcdedc70",
#  "0xc5327f96ee02d7bcbc1bf1236b8c15148971e1de",
#  "0xab5e7f4061c605820d3744227eed91ff8e2c8908"
#]