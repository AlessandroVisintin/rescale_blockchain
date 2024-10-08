get_local_ip() {
    # Check if correct number of arguments is provided
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <node_name>"
        exit 1
    fi
    node_path="network/$1/besu.networks"
    # Check if the network file exists
    if [ ! -f "$node_path" ]; then
        echo "Error: '$node_path' not found."
        exit 1
    fi
    # Extract the local-ip from the network file
    host=$(grep 'local-ip=' "$node_path" | cut -d'=' -f2)
    # Check if the local-ip was successfully extracted
    if [ -z "$host" ]; then
        echo "Error: Could not extract local-ip from '$node_path'."
        return 1
    fi
    # Output the extracted local-ip
    echo "$host"
}
