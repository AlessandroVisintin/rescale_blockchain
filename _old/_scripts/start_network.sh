#!/bin/bash

source _lib/get_enode_address.sh
source _lib/get_local_ip.sh
source _lib/get_rpc_port.sh

# Network directory
NETWORK_DIR="network"

# Initialize ports
P2P_PORT=30303
RPC_HTTP_PORT=8545

# Check if bootnode folder exists
if [ ! -d "$NETWORK_DIR/bootnode" ]; then
	echo "Bootnode folder not found. Exiting..."
	exit 1
fi

# Start bootnode
echo "Starting bootnode..."
docker run --rm \
		-v $(pwd)/$NETWORK_DIR/bootnode:/besu \
		-w /besu \
		-p $P2P_PORT:$P2P_PORT \
		-p $RPC_HTTP_PORT:$RPC_HTTP_PORT \
		--name bootnode \
		hyperledger/besu:latest \
		--min-gas-price=0 \
		--logging=ALL \
		--data-path=./ \
		--genesis-file=./genesis.json \
		--p2p-port=$P2P_PORT \
		--rpc-http-enabled \
		--rpc-http-api=ADMIN,ETH,NET,QBFT \
		--host-allowlist="*" \
		--rpc-http-cors-origins="all" \
		--rpc-http-port=$RPC_HTTP_PORT \
		> "$NETWORK_DIR/bootnode/log" 2>&1 &

# Wait for bootnode to be online
echo "Waiting for bootnode to be online..."
while [ ! -f "$NETWORK_DIR/bootnode/besu.networks" ]; do
	sleep 1
done
# Get bootnode enode
BOOTNODE_ENODE=$(get_enode_address bootnode)

echo "Starting nodes..."
# Scan current directory for folders named "node{n}" pattern
for node_dir in $(find $NETWORK_DIR -maxdepth 1 -type d -name "node[0-9]*" | sort); do
	node=$(basename "$node_dir")
	# Augment port numbers
	P2P_PORT=$(expr $P2P_PORT + 1)
	RPC_HTTP_PORT=$(expr $RPC_HTTP_PORT + 1)

	# start node
	docker run --rm \
		-v $(pwd)/$NETWORK_DIR/$node:/besu \
		-v $(pwd)/$NETWORK_DIR/bootnode:/bootnode \
		-w /besu \
		-p $P2P_PORT:$P2P_PORT \
		-p $RPC_HTTP_PORT:$RPC_HTTP_PORT \
		--name "$node" \
		hyperledger/besu:latest \
		--min-gas-price=0 \
		--data-path=./ \
		--genesis-file=/bootnode/genesis.json \
		--bootnodes=$BOOTNODE_ENODE \
		--p2p-port=$P2P_PORT \
		--rpc-http-enabled \
		--rpc-http-host=0.0.0.0 \
		--rpc-http-api=ETH,NET,QBFT \
		--host-allowlist="*" \
		--rpc-http-cors-origins="all" \
		--rpc-http-port=$RPC_HTTP_PORT \
		> $node_dir/log 2>&1 &

	# Wait a bit before starting the next node
	sleep 0.5
done

echo "bootnode -> $(get_local_ip bootnode):$(get_rpc_port bootnode)"
for node_dir in $(find $NETWORK_DIR -maxdepth 1 -type d -name "node[0-9]*" | sort); do
	node=$(basename "$node_dir")
	while [ ! -f "$NETWORK_DIR/$node/besu.networks" ]; do
		sleep 0.5
	done
	echo "$node -> $(get_local_ip $node):$(get_rpc_port $node)"
done
