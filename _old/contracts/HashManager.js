const { Web3 } = require("web3");
const fs = require('fs');
const path = require("path");

// Get command line arguments
const nodeName = process.argv[2];       // eg "node1"
const contractName = process.argv[3];   // eg "MyContract"
const functionName = process.argv[4];   // eg "createHash"
if (!nodeName || !contractName || !functionName) {
    console.error("Usage: node deploy.js <nodeName> <contractName> <functionName> [functionArgs]");
    process.exit(1);
}
const networkDir = path.join('network', nodeName);
// Get local ip
const networkContent = fs.readFileSync(path.join(networkDir, 'besu.networks'), 'utf8');
const localIpMatch = networkContent.match(/local-ip=(.+)/);
if (!localIpMatch) {
    console.error("Could not find IP.");
    process.exit(1);
}
const localIp = localIpMatch[1].trim();
// Get rpc port
const portsContent = fs.readFileSync(path.join(networkDir, 'besu.ports'), 'utf8');
const jsonRpcPortMatch = portsContent.match(/json-rpc=(.+)/);
if (!jsonRpcPortMatch) {
    console.error("Could not find Port.");
    process.exit(1);
}
const jsonRpcPort = jsonRpcPortMatch[1].trim();
// Get private key
const privateKey = fs.readFileSync(path.join(networkDir, 'key'), 'utf8').trim();
if (!privateKey) {
    console.error("Could not private key.");
    process.exit(1);
}
// Get ABI
try {
    abiFilePath = path.join('contracts', `${contractName}.abi`)
    abi = JSON.parse(fs.readFileSync(abiFilePath), 'utf8');
} catch (error) {
    console.error(`Error parsing ABI file ${abiFilePath}:`, error.message);
    process.exit(1);
}
// Get contract address
const addressesContent = fs.readFileSync(path.join('contracts', 'addresses.txt'), 'utf8');
const contractAddressLine = addressesContent.split('\n').find(line => line.startsWith(`${contractName}:`));
if (!contractAddressLine) {
    console.error(`${contractName} address not found.`);
    process.exit(1);
}
const contractAddress = contractAddressLine.split(':')[1].trim();
// open connection
const web3 = new Web3(`http://${localIp}:${jsonRpcPort}/`);
// create contract object
const contract = new web3.eth.Contract(abi, contractAddress);
// contract function calls
async function createHash() {
//     const functionArgs = process.argv.slice(5); // Additional arguments for the function

//     try {
//         const account = web3.eth.accounts.privateKeyToAccount(privateKey);
//         const receipt = await contract.methods.createHash(hashInput).send(
//             {
//                 from: account.address
//             }
//         )
//         console.log(JSON.stringify(receipt, (key, value) =>
//             typeof value === 'bigint' ? value.toString() : value, 2));
//     } catch(error) {
//         console.error("Error:", error.message);
//         process.exit(1);
//     };
}

// switch (functionName) {
//     case 'createHash' :
//         createHash()
//         break
//     default :
//         console.error("Unsupported command");
//         process.exit(1);
// }
