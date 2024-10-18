const { Web3 } = require("web3");
const path = require("path");
const fs = require("fs").promises;

// resolve root path
function findRootFolder(startPath) {
    let currentPath = startPath;
    while (true) {
        envFilePath = path.join(currentPath, ".env");
        if (require("fs").existsSync(envFilePath)) {
            return currentPath;
        }
        const parentPath = path.dirname(currentPath);
        if (parentPath === currentPath) {
            throw new Error("Could not find the root folder (no .env found)");
        }
        currentPath = parentPath;
    }
}
const rootPath = findRootFolder(__dirname);
// move to root folder
process.chdir(rootPath);

// Import dotenv and load environment variables
const dotenv = require('dotenv').config({ path: ".env" });
const CONTRACTS_DIR = process.env.CONTRACTS_DIR;

// util functions
async function signTransaction(web3, account, txData) {
    try {
        var signed = await web3.eth.accounts.signTransaction(
            txData,
            account.privateKey.slice(2)
        )
        return signed
    } catch (error) {
        if (error && error.data) {
            console.error('Error details:', JSON.stringify(error.data, null, 2));
        } else {
            console.error('Transaction failed:', error);
        }
        process.exit(1);
    }
}

async function sendSignedTransaction(web3, signedTx) {
    try {
        var receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
        return receipt
    } catch (error) {
        if (error && error.data) {
            console.error('Error details:', JSON.stringify(error.data, null, 2));
        } else {
            console.error('Transaction failed:', error);
        }
        process.exit(1);    }
    
}

function safeLogJson(json) {
    try {
        console.log(JSON.stringify(json, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value, 2));
    } catch (error) {
        console.error('JSON stringify failed:', error.message);
        process.exit(1);
    }  
}


async function main() {

    // Get command-line arguments
    const nodeName = process.argv[2];  // eg "node1"
    const contractName = process.argv[3]; // eg "HashManager"
    if (!nodeName || !contractName) {
        console.error("Usage: node deploy.js <nodeName> <contractName>");
        process.exit(1);
    }

    // Construct httpAddress from node configuration
    const networkConfig = JSON.parse(await fs.readFile(
        path.join("blockchain", "configs", "network.json"),
        "utf8"
    ));    
    const nodeConfig = networkConfig[nodeName];
    if (!nodeConfig) {
        console.error(`Node configuration not found for: ${nodeName}`);
        process.exit(1);
    }
    const httpAddress = `http://${nodeConfig.local_ip}:${nodeConfig.rpc_port}`;

    // Load the private key
    const privateKeyPath = path.join("blockchain", "nodes", nodeName, "key");
    const privateKey = (await fs.readFile(privateKeyPath, "utf8")).trim();
    if (!privateKey) {
        console.error(`Private key not found for node: ${nodeName}`);
        process.exit(1);
    }

    // Load binary data from the contract's JSON artifact
    const contractArtifactPath = path.join(CONTRACTS_DIR, `${contractName}.json`);
    const contractArtifact = JSON.parse(await fs.readFile(contractArtifactPath, "utf8"));
    const bytecode = "0x" + contractArtifact.bytecode;
    if (!bytecode) {
        console.error(`Bytecode not found in contract artifact: ${contractName}`);
        process.exit(1);
    }

    // Deploy the contract and get the transaction result
    const contractAddress = await deploy(httpAddress, privateKey, bytecode);

    // Save the transaction result to a file
    await fs.appendFile(
        path.join(CONTRACTS_DIR, `${contractName}.address`),`${contractAddress}\n`, "utf8");

}

async function deploy(httpAddress, privateKey, bytecode) {

    const web3 = new Web3(httpAddress);
    const account = await web3.eth.accounts.privateKeyToAccount(privateKey);

    console.log('Signing transaction..');
    var signedTx = await signTransaction(web3, account, {
        from: account.address,
        to: null, //public tx
        value: "0x00",
        data: bytecode,
        gasPrice: "0x0", // free gas network
        gasLimit: "0x1ffffffff", // free gas network
    })

    console.log('Sending signed transaction..');
    var receipt = await sendSignedTransaction(web3, signedTx);

    safeLogJson(receipt);

    // Extract the contract address from the transaction receipt
    const contractAddress = receipt.contractAddress;
    if (!contractAddress) {
        throw new Error("Contract deployment failed. No contract address returned.");
    }
    return contractAddress;
    
}

main().then(() => process.exit(0));
