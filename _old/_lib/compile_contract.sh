#!/bin/bash

compile_contract() {
    # Check if file path is provided
    if [[ -z "$1" ]]; then
        echo "Usage: compile_solidity <contract_name> [--overwrite]"
        return 1
    fi
    dir="contracts"
    filename="$1.sol"
    filepath="$dir/$filename"
    # Compile the Solidity file
    if [[ "$2" == "--overwrite" ]]; then
        solc --abi --bin "$filepath" -o "$dir/" --overwrite
    else
        solc --abi --bin "$filepath" -o "$dir/"
    fi
    # Check if the compilation was successful
    if [[ $? -eq 0 ]]; then
        echo "ABI: $dir/$filename.abi"
        echo "Bytecode: $dir/$filename.bin"
    else
        echo "Compilation failed"
        return 1
    fi
}
