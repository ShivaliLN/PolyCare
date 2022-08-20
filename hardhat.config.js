require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require('dotenv').config()
 /**@type import('hardhat/config').HardhatUserConfig **/
 require('hardhat/config') // need to fix deployment error for large size contracts
 
const POLYGON_RPC_URL = process.env.POLYGON_URL;
const POLYGON_API_KEY = process.env.POLYGONSCAN_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true
    }, 
    mumbai: {
      chainId: 80001,
      url: POLYGON_RPC_URL,
      accounts: [PRIVATE_KEY],
      saveDeployments: true,
      allowUnlimitedContractSize: true
  },     
},
etherscan: {
 apiKey: POLYGON_API_KEY
},
paths: {
  artifacts: './artifacts',
},
  solidity: {
    version:"0.8.9",
    settings: {
      optimizer: {
        enabled: false,
        runs: 1000
      }
    }
  }  
};
