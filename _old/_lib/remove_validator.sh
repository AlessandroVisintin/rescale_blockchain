#!/bin/bash

source _lib/get_local_ip.sh
source _lib/get_rpc_port.sh

remove_validator() {
  # Check number of arguments
  if [ "$#" -ne 2 ]; then
    echo "Usage: remove_validator <validator_name> <remove_validator_id>"
    return 1
  fi

  ip=$(get_local_ip $1)
  port=$(get_rpc_port $1)
  payload="{\"jsonrpc\":\"2.0\",\"method\":\"qbft_proposeValidatorVote\",\"params\":[\"$2\",false],\"id\":1}"
  response=$(curl -s -X POST --data "$payload" "http://$ip:$port")
  echo "$response"
}