#!/bin/bash

# Function to capture the IP address of a given Docker container
get_container_ip() {
    local container_name=$1
    local container_ip

    # Capture the IP address of the specified container
    container_ip=$(docker inspect --format='{{.NetworkSettings.IPAddress}}' "$container_name")

    # Return the captured IP address
    echo "$container_ip"
}