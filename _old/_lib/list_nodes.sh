#!/bin/bash

source _lib/get_container_ip.sh

list_nodes() {
    local node_name=$1
    local node_port=$2
    node_ip=$(get_container_ip $node_name)
    response=$(curl -s -X POST --data '{"jsonrpc":"2.0","method":"admin_peers","params":[],"id":1}' http://$node_ip:$node_port)
    id_enode_pairs=$(echo "$response" | jq -r '.result[] | "\(.id),\(.enode)"')
    echo "$id_enode_pairs"
}
