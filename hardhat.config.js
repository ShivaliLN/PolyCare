require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require('dotenv').config()
/** @type import('hardhat/config').HardhatUserConfig */

const POLYGON_RPC_URL = process.env.POLYGON_URL;
const POLYGON_API_KEY = process.env.POLYGONSCAN_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

module.exports = {
  //defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    }, mumbai: {
      url: POLYGON_RPC_URL,
      accounts: [PRIVATE_KEY],
      saveDeployments: true,
  },     
},
etherscan: {
 apiKey: POLYGON_API_KEY
},
paths: {
  artifacts: './artifacts',
},
  solidity: "0.8.9",
};
