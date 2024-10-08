const { Web3 } = require("web3");
const path = require("path");
const fs = require("fs");

// Get command-line arguments
const httpAddress = process.argv[2];  // eg "http://172.17.0.2:8545/"
const privateKey = process.argv[3];   // eg "0x49f084edaae83aec3..."
const binaryData = process.argv[4];   // eg "0x60806040523480156..."

if (!httpAddress || !privateKey || !binaryData) {
    console.error("Usage: node deploy.js <httpAddress> <privateKey> <binaryData>");
    process.exit(1);
}

async function deploy() {
    const web3 = new Web3(httpAddress);
    const account = await web3.eth.accounts.privateKeyToAccount(privateKey);
    try {
        var signed = await web3.eth.accounts.signTransaction(
            {
            from: account.address,
            to: null, //public tx
            value: "0x00",
            data: binaryData,
            gasPrice: "0x0", // free gas network
            gasLimit: "0x1ffffffff", // free gas network
            },
            privateKey.slice(2)
        )
    } catch (error) {
        console.error('Signing failed:', error.message);
        process.exit(1);
    }
    try {
        var tx = await web3.eth.sendSignedTransaction(signed.rawTransaction);
    } catch (error) {
        console.error('Transaction failed:', error.message);
        process.exit(1);
    }
    try {
        console.log(JSON.stringify(tx, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value, 2));
    } catch (error) {
        console.error('JSON stringify failed:', error.message);
        process.exit(1);
    }
    
}

deploy();
