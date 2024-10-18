#!/bin/sh
set -e

# set custom boostrap
ipfs bootstrap rm all

# Set bootstrap id variables are set
if [[ -n "$IP_ADDR" && -n "$PEER_ID" ]]; then
  ipfs bootstrap add "/ip4/$IP_ADDR/tcp/4001/ipfs/$PEER_ID"
fi