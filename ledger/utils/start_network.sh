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
if [ -z "$(sudo docker network ls --filter name="$BESU_NETWORK_NAME" --format "{{.Name}}")" ]; then
    echo "Creating Docker network $BESU_NETWORK_NAME > $BESU_NETWORK_CIDR.."
    sudo docker network create --subnet="$BESU_NETWORK_CIDR" "$BESU_NETWORK_NAME"
fi

# check existence of qbft initial config
if [ ! -f "$LEDGER_CONFIGS/qbftConfigFile.json" ]; then
    echo "qbftConfigFile.json not found in $LEDGER_CONFIGS"
    exit 1
fi

# generating nodes folders (if not exists)
if ! find "$LEDGER_NODES" -mindepth 1 -type d 1>/dev/null 2>&1; then

    if [ -z "$1" ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
        echo "Expeted number of nodes to generate in input"
        exit 1
    fi

    # generate keys
    for ((i = 0; i < $1; i++)); do
        node_name="node$i"
        node_path="$LEDGER_NODES/$node_name"
        mkdir -p "$node_path"

        # generate private key
        echo "Generating private key for $node_name.."
        openssl ecparam -name $BESU_ECCURVE -genkey -noout -out "$node_path/key.pem"
        echo -n '0x' > "$node_path/key" && \
            openssl ec -in "$node_path/key.pem" -text -noout | \
            grep priv: -A 3 | \
            tail -n +2 | \
            tr -d '\n[:space:]:' >> "$node_path/key"

        # generate public key
        sudo docker run --rm \
            -v $ROOTPATH/$node_path:/besu \
            hyperledger/besu:$BESU_VERSION public-key export \
            --node-private-key-file=/besu/key \
            --to=/besu/key.pub \
            --ec-curve="$BESU_ECCURVE"
        
        # generate address
        sudo docker run --rm \
            -v $ROOTPATH/$node_path:/besu \
            hyperledger/besu:$BESU_VERSION public-key export-address \
            --node-private-key-file=/besu/key \
            --to=/besu/besu.address \
            --ec-curve=$BESU_ECCURVE
    done

    # generate validators file
    echo "Generating validators.json.."
    address_list=()
    for node_path in $(ls -d $LEDGER_NODES/node* 2>/dev/null); do
        node_name="$(cat "$node_path/besu.address")"
        address_list+=("$node_name")
    done
    printf '%s\n' "${address_list[@]}" | jq -R . | jq -s . > "$LEDGER_CONFIGS/validators.json"

    # generate validators file
    echo "Generating genesis.json.."
    sudo docker run --rm \
        -v $ROOTPATH/$LEDGER_CONFIGS:/besu \
        hyperledger/besu:$BESU_VERSION rlp encode \
        --from=/besu/validators.json \
        --to=/besu/extradata \
        --type=QBFT_EXTRA_DATA
    jq --arg extraData "$(cat "$LEDGER_CONFIGS/extradata")" \
        '.genesis.extraData = $extraData | .genesis' \
        "$LEDGER_CONFIGS/qbftConfigFile.json" > "$LEDGER_CONFIGS/genesis.json"
    rm -f "$LEDGER_CONFIGS/extradata"

    # CIDR to integer conversion
    IFS='/.' read -r a b c d mask <<< "$IPFS_NETWORK_CIDR"
    range=$((2**(32 - mask) - 1))
    curip=$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))
    endip=$((curip + range))

    # create node
    bootnode=""
    for ((i = 0; i < $1; i++)); do
        node_name="node$i"
        node_path="$LEDGER_NODES/$node_name"

        # generate IP (skip reserved IPs ending with .0, .1, or .255)
        ip_address=""
        for ((curip; curip <= endip; curip++)); do
            ip_octet=$((curip & 255))
            if [[ "$ip_octet" -eq 0 || "$ip_octet" -eq 1 || "$ip_octet" -eq 255 ]]; then
                continue
            fi
            (( curip > endip )) && { echo "IP address range exceeded. Exiting."; exit 1; }
            tmp_address="$((($curip>>24)&255)).$((($curip>>16)&255)).$((($curip>>8)&255)).$(($curip&255))"
            if sudo docker network inspect "$BESU_NETWORK_NAME" | grep -q "$tmp_address"; then
                continue
            fi
            ip_address="$tmp_address"
            break
        done

        # calculate bootnode
        if [[ "$node_name" == "node0" ]]; then
            pubkey="$(cat "$node_path/key.pub" | tr -d '\n' | sed 's/^0x//')"
            bootnode="enode://$pubkey@$ip_address:$BESU_P2P_PORT"
        fi

        # first start up
        echo "$node_name@$ip_address"
        sudo docker run \
            -v $ROOTPATH/$node_path:/node \
            -v $ROOTPATH/$LEDGER_CONFIGS:/configs \
            --name "besu_$node_name" \
            --network $BESU_NETWORK_NAME \
            --ip $ip_address \
            hyperledger/besu:$BESU_VERSION \
            --min-gas-price=0 \
            --data-path=/node \
            --genesis-file=/configs/genesis.json \
            --p2p-host=$ip_address \
            --p2p-port=$BESU_P2P_PORT \
            --rpc-http-enabled \
            --rpc-http-host=$ip_address \
            --rpc-http-port=$BESU_RPC_PORT \
            --rpc-http-api=ETH,NET,QBFT \
            --host-allowlist=* \
            --rpc-http-cors-origins=\"all\" \
            --bootnodes=$bootnode \
            > "$node_path/.log" 2>&1 &
        
        # increment ip
        curip=$((curip + 1))
    done

    while true; do
        statuses=$(sudo docker ps --filter "name=besu_" --format "{{.Status}}")
        [[ $(echo "$statuses" | grep -v "^Up") ]] && sleep 1 && continue
        break
    done

    echo "Removing .jfr log files"
    find $(pwd) -type f -name "*.jfr" -delete

else

    node_list=()
    for node_path in $(ls -d $LEDGER_NODES/node* 2>/dev/null); do
        node_name="$(basename "$node_path")"
        node_list+=("besu_$node_name")
    done
    sudo docker start "${node_list[@]}"

fi

echo "Besu network listening"
