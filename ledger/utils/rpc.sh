#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 -i <node_ip> [-P <port>] -m <method_name> -p <parameters> [-I <id>]"
  echo "Example: $0 -i 127.0.0.1 -P 8545 -m eth_blockNumber"
  exit 1
}


# Parse command-line arguments
while getopts ":i:P:m:p:I:" opt; do
  case $opt in
    i) NODE_IP="$OPTARG" ;;     # Node IP
    P) PORT="$OPTARG" ;;        # Optional port
    m) METHOD_NAME="$OPTARG" ;; # RPC Method
    p) PARAMETERS="$OPTARG" ;;  # Method parameters (optional)
    I) ID="$OPTARG" ;;          # Optional ID
    *) usage ;;                 # Display usage if invalid option
  esac
done

# Ensure node IP and method name are provided
if [ -z "$NODE_IP" ] || [ -z "$METHOD_NAME" ]; then
  usage
fi

# Default JSON-RPC version
JSON_RPC_VERSION="2.0"
# Use the provided port or the default one
PORT=${PORT:-"8545"}
# Use the provided ID or the default one
ID=${ID:-"1"}

# Construct the full node URL
NODE_URL="http://$NODE_IP:$PORT"

# If parameters are provided, format them, otherwise use an empty array
if [ -z "$PARAMETERS" ]; then
  PARAM_ARRAY="[]"
else
  PARAM_ARRAY="$PARAMETERS"
fi

# Construct the JSON payload
RPC_PAYLOAD=$(cat <<EOF
{
  "jsonrpc": "$JSON_RPC_VERSION",
  "method": "$METHOD_NAME",
  "params": $PARAM_ARRAY,
  "id": $ID
}
EOF
)

# Send the request to the Besu node
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" --data "$RPC_PAYLOAD" "$NODE_URL")

# Print the response
echo "Response: $RESPONSE"
