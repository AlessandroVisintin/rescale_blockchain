#!/bin/bash

# Network directory
NETWORK_DIR="network"

# Stop dockers
docker stop $(docker ps --filter "ancestor=hyperledger/besu:latest" -q)

# Discover and delete .jfr files in node{n} folders
for dir in $(find "$NETWORK_DIR" -maxdepth 1 -type d | sort); do
    find "$dir" -type f -name "*.jfr" -exec rm -v {} \;
done