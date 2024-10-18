#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

sudo docker stop $(sudo docker ps -q --filter "name=^besu")