const { Web3 } = require("web3");
const fs = require('fs').promises;
const path = require("path");

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

    // Get command line arguments
    const nodeName = process.argv[2];       // eg "node1"
    const contractName = process.argv[3];   // eg "MyContract"
    const functionName = process.argv[4];   // eg "createHash"
    if (!nodeName || !contractName || !functionName) {
        console.error("Usage: node deploy.js <nodeName> <contractName> <functionName> [functionArgs]");
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

    // Load ABI from the contract's JSON artifact
    const contractArtifactPath = path.join(CONTRACTS_DIR, `${contractName}.json`);
    const contractArtifact = JSON.parse(await fs.readFile(contractArtifactPath, "utf8"));
    const abi = contractArtifact.abi;
    if (!abi) {
        console.error(`Abi not found in contract artifact: ${contractName}`);
        process.exit(1);
    }

    // Load contract address
    const contractAddressPath = path.join(CONTRACTS_DIR, `${contractName}.address`);
    const addressesContent = await fs.readFile(contractAddressPath, "utf8");
    const contractAddress = addressesContent.split('\n')[0].trim()
    if (!contractAddress) {
        console.error(`${contractName} address not found`);
        process.exit(1);
    }

    // Initialize Web3
    const web3 = new Web3(httpAddress);
    const account = web3.eth.accounts.privateKeyToAccount(privateKey);
    const contract = new web3.eth.Contract(abi, contractAddress);

    switch (functionName) {
        case 'createHash' :
            await createHash(web3, account, contract);
            break;
        case 'readHash' :
            await readHash(web3, account, contract);
            break;
    
        default :
            console.error("Unsupported command");
            process.exit(1);
        }

}

// contract function calls
async function createHash(web3, account, contract) {

    // Get hash from parameters
    let hash = process.argv[5];
    if (!hash) {
        console.error("Please provide a hash value.");
        process.exit(1);
    }

    console.log('Signing transaction..');
    var signedTx = await signTransaction(web3, account, {
        from: account.address,
        to: contract.options.address,
        data: contract.methods.createHash(hash).encodeABI(),
        gasPrice: "0x0", // free gas network
        gasLimit: "0x1ffffffff", // free gas network
    })

    console.log('Sending signed transaction..');
    var receipt = await sendSignedTransaction(web3, signedTx);

    safeLogJson(receipt);
}

async function readHash(web3, account, contract) {

    // Get hash from parameters
    let hash = process.argv[5];
    if (!hash) {
        console.error("Please provide a hash value.");
        process.exit(1);
    }

    console.log('Signing transaction..');
    var signedTx = await signTransaction(web3, account, {
        from: account.address,
        to: contract.options.address,
        data: contract.methods.readHash(hash).encodeABI(),
        gasPrice: "0x0", // free gas network
        gasLimit: "0x1ffffffff", // free gas network
    })

    console.log('Sending signed transaction..');
    var receipt = await sendSignedTransaction(web3, signedTx);

    safeLogJson(receipt);
}


main().then(() => process.exit(0));
