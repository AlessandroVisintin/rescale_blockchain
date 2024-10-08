#!/bin/bash

source _lib/get_local_ip.sh
source _lib/get_rpc_port.sh

function get_gas_price() {
    # Check if correct number of arguments is provided
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <node_name>"
        return 1
    fi

    node_ip=$(get_local_ip $1)
    node_port=$(get_rpc_port $1)
    response=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":53}' http://$node_ip:$node_port)
    echo "$response"
}