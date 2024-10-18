// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashManager {

    struct HashInfo {
        uint256 index; // Index position in the `hashList` array
        address owner; // Owner of the hash
    }

    mapping(bytes32 => HashInfo) private hashMapping; // Mapping hash value -> HashInfo
    bytes32[] private hashList; // store all hash values

    // Events for CRUD operations
    event HashCreated(bytes32 indexed hashValue, address indexed owner);
    event HashUpdated(bytes32 indexed oldHashValue, bytes32 indexed newHashValue, address indexed owner);
    event HashDeleted(bytes32 indexed hashValue, address indexed owner);

    function createHash(bytes32 _hash) external { // create
        require(_hash != bytes32(0), "Invalid hash");
        require(hashMapping[_hash].owner == address(0), "Hash already exists");
        hashMapping[_hash] = HashInfo({ index: hashList.length, owner: msg.sender });
        hashList.push(_hash);
        emit HashCreated(_hash, msg.sender); // emit event
    }

    function readHash(bytes32 _hash) external view returns (uint256 index, address owner) { // read
        require(hashMapping[_hash].owner != address(0), "Hash does not exist");
        HashInfo memory hashInfo = hashMapping[_hash];
        return (hashInfo.index, hashInfo.owner);
    }

    function updateHash(bytes32 _oldHash, bytes32 _newHash) external { // update
        require(hashMapping[_oldHash].owner != address(0), "Old hash does not exist");
        require(hashMapping[_newHash].owner == address(0), "New hash already exists");
        require(hashMapping[_oldHash].owner == msg.sender, "Caller is not the owner");
        uint256 index = hashMapping[_oldHash].index; // Get the index of the old hash
        hashList[index] = _newHash; // Replace old hash in array with the new hash
        hashMapping[_newHash] = HashInfo({ index: index, owner: msg.sender }); // Add new hash in mapping
        delete hashMapping[_oldHash]; // Delete old hash from mapping
        emit HashUpdated(_oldHash, _newHash, msg.sender); // emit event
    }

    function deleteHash(bytes32 _hash) external { // delete
        require(hashMapping[_hash].owner != address(0), "Hash does not exist");
        require(hashMapping[_hash].owner == msg.sender, "Caller is not the owner");
        uint256 index = hashMapping[_hash].index; // index of hash to delete
        uint256 lastIndex = hashList.length - 1; // last index of array
        if (index != lastIndex) {
            bytes32 lastHash = hashList[lastIndex];
            hashList[index] = lastHash; // Replace the hash to be deleted with the last hash
            hashMapping[lastHash].index = index; // Update the index of the last hash
        }
        hashList.pop(); // Remove the last element from the array
        delete hashMapping[_hash]; // delete from mapping
        emit HashDeleted(_hash, msg.sender); // emit event
    }

}
