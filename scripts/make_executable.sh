#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Locate script
SCRIPTPATH="$(realpath "$(dirname "$0")")"
ROOTPATH="$(dirname "${SCRIPTPATH}")"

# Find all scripts inside rescale folder and make them executable
find "$ROOTPATH" -type f -name "*.sh" -exec chmod +x {} \;

echo "All scripts in $ROOTPATH are now executable"
