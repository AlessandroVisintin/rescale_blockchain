#!/bin/bash

source _lib/get_local_ip.sh
source _lib/get_rpc_port.sh
source _lib/get_node_address.sh


deploy_contract() {
    # Check number of arguments
    if [ "$#" -ne 2 ]; then
        echo "Usage: deploy_contract <node_name> <contract_name>"
        return 1
    fi
    # get node details
    ip=$(get_local_ip $1)
    port=$(get_rpc_port $1)
    rpc="http://$ip:$port"
    # get node private key
    if [[ ! -f "network/$1/key" ]]; then
        echo "network/$1/key not found"
        return 1
    fi
    key=$(cat network/$1/key)
    # get contract binary
    if [[ ! -f "contracts/$2.bin" ]]; then
        echo "contracts/$2.bin not found"
        return 1
    fi
    bin=$(cat "contracts/$2.bin")
    # Deploy the contract using the Node.js script and capture the contract address
    receipt=$(node _lib/deploy_contract.js "$rpc" "$key" "0x$bin")
    # Check if the Node.js script executed successfully
    if [[ $? -ne 0 ]]; then
        echo "Contract deployment failed."
        return 1
    fi
    # Print the full receipt
    echo "Transaction Receipt:"
    echo "$receipt"
    # Extract the contract address from the receipt using jq
    contract_address=$(echo "$receipt" | jq -r '.contractAddress')
    # Check if contract address extraction was successful
    if [[ "$contract_address" == "null" || -z "$contract_address" ]]; then
        echo "Failed to extract contract address."
        return 1
    fi
    # Append contract address to a text file
    echo "$2:$contract_address" >> "contracts/addresses.txt"
    echo "Contract deployed successfully: $contract_address"
}
