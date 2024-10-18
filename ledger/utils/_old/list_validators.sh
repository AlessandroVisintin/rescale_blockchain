#!/bin/bash

source _lib/get_local_ip.sh
source _lib/get_rpc_port.sh

# Function to list validators
list_validators() {
    # Check if correct number of arguments is provided
    if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <node_name>"
    return 1
    fi
    ip=$(get_local_ip $1)
    port=$(get_rpc_port $1)
    payload="{\"jsonrpc\":\"2.0\",\"method\":\"qbft_getValidatorsByBlockNumber\",\"params\":[\"latest\"],\"id\":1}"
    response=$(curl -s -X POST --data "$payload" "http://$ip:$port")
    validators=$(echo "$response" | jq -r '.result[]')
    echo "$validators"
}
