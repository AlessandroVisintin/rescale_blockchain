#!/bin/bash

source _lib/get_local_ip.sh
source _lib/get_discovery_port.sh

get_enode_address() {
    # Check if correct number of arguments is provided
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <node_name>"
        exit 1
    fi

    # Get the local IP and RPC port using the respective functions
    ip=$(get_local_ip $1)
    if [ -z "$ip" ]; then
        echo "Failed to get local IP"
        exit 1
    fi
    port=$(get_discovery_port $1)
    if [ -z "$port" ]; then
        echo "Failed to get RPC port"
        exit 1
    fi
    # Get the public key from the file
    pubkey_file="network/$1/key.pub"
    if [ ! -f "$pubkey_file" ]; then
        echo "$pubkey_file not found"
        exit 1
    fi
    pubkey=$(sed 's/^0x//' "$pubkey_file")
    # Construct the enode address
    enode_address="enode://$pubkey@$ip:$port"
    # Output the enode address
    echo "$enode_address"
}
