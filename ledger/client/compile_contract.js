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

// import from local modules
const dotenv = require('dotenv').config({ path: ".env"});
const solc = require("solc");

const CONTRACTS_DIR = process.env.CONTRACTS_DIR;

async function main() {

    // Take contract name from command-line argument
    const contractName = process.argv[2];  
    if (!contractName) {
        console.error("Please provide a contract name as an argument.");
        process.exit(1);
    }

    // read from .sol file
    const sourceCode = await fs.readFile(
        path.join(CONTRACTS_DIR, `${contractName}.sol`), "utf8");
    // compile the source code
    const { abi, bytecode } = compile(sourceCode, contractName);
    // store the ABI and bytecode into a JSON file
    const artifact = JSON.stringify({ abi, bytecode }, null, 2);
    await fs.writeFile(
        path.join(CONTRACTS_DIR, `${contractName}.json`), artifact);
}

function compile(sourceCode, contractName) {
    // create the Solidity Compiler Standard Input and Output JSON
    const input = {
        language: "Solidity",
        sources: { main: { content: sourceCode } },
        settings: { outputSelection: { "*": { "*": ["abi", "evm.bytecode"] } } },
    };
    // parse the compiler output to retrieve the ABI and bytecode
    const output = solc.compile(JSON.stringify(input));
    const artifact = JSON.parse(output).contracts.main[contractName];
    return {
        abi: artifact.abi,
        bytecode: artifact.evm.bytecode.object,
    };
}

main().then(() => process.exit(0));