#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Move to root folder
ROOTPATH="$(realpath "$(dirname "$0")")"
while [ "$ROOTPATH" != "/" ] && [ ! -f "$ROOTPATH/.env" ]; do ROOTPATH="$(dirname "$ROOTPATH")"; done
[ "$ROOTPATH" = "/" ] && { echo "ROOTPATH is root directory. Exiting."; exit 1; }
cd "$ROOTPATH"
# Import env variables
[ -f "$ROOTPATH/.env" ] && { echo "Loading environment variables from .env"; . "$ROOTPATH/.env"; }

# generate docker network (if not exists)
if [ -z "$(sudo docker network ls --filter name="$IPFS_NETWORK_NAME" --format "{{.Name}}")" ]; then
    echo "Creating Docker network $IPFS_NETWORK_NAME > $IPFS_NETWORK_CIDR.."
    sudo docker network create --subnet="$IPFS_NETWORK_CIDR" "$IPFS_NETWORK_NAME"
fi

# generate swarm key (if not available)
mkdir -p "$STORAGE_CONFIGS"
[ ! -f "$STORAGE_CONFIGS/swarm.key" ] && {
    echo "/key/swarm/psk/1.0.0/"
    echo "/base16/"
    echo "$(tr -dc 'a-f0-9' < /dev/urandom | head -c64)"
} > "$STORAGE_CONFIGS/swarm.key"

# generating nodes folders (if not exists)
if ! find "$STORAGE_NODES" -mindepth 1 -type d 1>/dev/null 2>&1; then

    if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Expeted number of nodes to generate in input"
        exit 1
    fi

    # CIDR to integer conversion
    IFS='/.' read -r a b c d mask <<< "$IPFS_NETWORK_CIDR"
    range=$((2**(32 - mask) - 1))
    curip=$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))
    endip=$((curip + range))

    boot_ip=""
    boot_id=""
    swarm_key=$(cat "$STORAGE_CONFIGS/swarm.key")

    # generate sequential nodes
    for ((i = 0; i < $1; i++)); do
        node_name="node$i"
        node_path="$STORAGE_NODES/$node_name"
        
        echo "Creating $node_path.."
        mkdir -p "$node_path/export"
        mkdir -p "$node_path/data/ipfs"

        # generate IP (skip reserved IPs ending with .0, .1, or .255)
        for ((curip; curip <= endip; curip++)); do
            ip_octet=$((curip & 255))
            if [[ "$ip_octet" -ne 0 && "$ip_octet" -ne 1 && "$ip_octet" -ne 255 ]]; then
                break  # Valid IP found, exit loop
            fi
        done
        (( curip > endip )) && { echo "IP address range exceeded. Exiting."; exit 1; }
        ip_address="$((($curip>>24)&255)).$((($curip>>16)&255)).$((($curip>>8)&255)).$(($curip&255))"
        
        # set bootstrap ip to node0
        [[ "$node_name" == "node0" ]] && boot_ip="$ip_address"

        # first node startup
        sudo docker run -d \
            -e IP_ADDR=$boot_ip \
            -e PEER_ID=$boot_id \
            -e IPFS_SWARM_KEY="$swarm_key" \
            -v "$ROOTPATH/$STORAGE_CONFIGS/config.sh:/container-init.d/config.sh"\
            -v "$ROOTPATH/$node_path/export:/export" \
            -v "$ROOTPATH/$node_path/data/ipfs:/data/ipfs" \
            --network $IPFS_NETWORK_NAME \
            --ip $ip_address \
            --name "ipfs_$node_name" \
            ipfs/kubo:$IPFS_VERSION \
            > "$node_path/.log" 2>&1

        # wait start-up and stop
        echo "Waiting ipfs_$node_name startup.." 
        while ! sudo docker logs "ipfs_$node_name" 2>&1 | grep -q "Daemon is ready";
        do sleep 1;
        done && sudo docker stop "ipfs_$node_name"

        # set bootstrap peer id
        [[ "$node_name" == "node0" ]] && boot_id=$(jq -r '.Identity.PeerID' "$node_path/data/ipfs/config")

        # increment ip
        curip=$((curip + 1))
    done
fi

# start all nodes
node_list=()
for node_path in $(ls -d $STORAGE_NODES/node* 2>/dev/null); do
    node_name="$(basename "$node_path")"
    node_list+=("ipfs_$node_name")
done
sudo docker start "${node_list[@]}"
