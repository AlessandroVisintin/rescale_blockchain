get_node_address() {
    # Check if correct number of arguments is provided
    if [ "$#" -ne 1 ]; then
        echo "Usage: $0 <node_name>"
        return
    fi
    node_path="network/$1/besu.address"

    # Check if file exists
    if [ ! -f "$node_path" ]; then
        echo "Error: '$node_path' not found."
        return
    fi
    # Read the value stored in the besu.address file
    address=$(cat "$node_path")
    # Check if address was successfully extracted
    if [ -z "$address" ]; then
        echo "Error: Could not extract address from '$node_path'."
        return
    fi
    # Output the extracted address
    echo "$address"
}
