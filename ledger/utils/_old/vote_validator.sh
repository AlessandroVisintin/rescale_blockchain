#!/bin/bash

source _lib/get_local_ip.sh
source _lib/get_rpc_port.sh

vote_validator() {
  # Check number of arguments
  if [ "$#" -ne 2 ]; then
    echo "Usage: vote_validator <validator_name> <new_validator_id>"
    return 1
  fi

  ip=$(get_local_ip $1)
  port=$(get_rpc_port $1)
  payload="{\"jsonrpc\":\"2.0\",\"method\":\"qbft_proposeValidatorVote\",\"params\":[\"$2\",true],\"id\":1}"
  response=$(curl -s -X POST --data "$payload" "http://$ip:$port")
  echo "$response"
}