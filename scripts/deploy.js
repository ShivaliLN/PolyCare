const hre = require("hardhat");

async function main() {
  const [owner] = await ethers.getSigners();
   /*
  // Contracts are deployed using the first signer/account by default
  const [owner] = await ethers.getSigners();
  //const price = hre.ethers.utils.parseEther("0.0001");
  //const minAmount = hre.ethers.utils.parseEther("0.0001");
  //const maxAmount = hre.ethers.utils.parseEther("100");
  const  MIN_DELAY = 1 // How long do we have to wait until we can execute after a passed proposal
  const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
  const VOTING_PERIOD  = 40 // blocks
  const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active

 
  const Contract1 = await hre.ethers.getContractFactory("Treasury");
  const contract1 = await Contract1.deploy();
  await contract1.deployed();
  console.log("Treasury deployed at: "+ contract1.address);  


  const Contract2 = await hre.ethers.getContractFactory("PolyCareMain");
  const contract2 = await Contract2.deploy(ethers.utils.parseEther("0.0002"), contract1.address);
  await contract2.deployed();
  console.log("PolyCareMain deployed at: "+ contract2.address); 



  const Contract3 = await hre.ethers.getContractFactory("TimeLock");
  const contract3 = await Contract3.deploy(MIN_DELAY, [], []);
  await contract3.deployed();
  console.log("TimeLock deployed at: "+ contract3.address); 



  const Contract4 = await hre.ethers.getContractFactory("GovernorContract");
  //const contract4 = await Contract4.deploy(contract2.address, contract3.address, QUORUM_PERCENTAGE, VOTING_PERIOD, VOTING_DELAY);
  const contract4 = await Contract4.deploy("0x0cd73F6cbe32FF4815E6FefF9852907b0Ad1D809", "0xB6d1Bf81a33c8F2A2Ed7Fcda8Cd96059E472528f", QUORUM_PERCENTAGE, VOTING_PERIOD, VOTING_DELAY);
  await contract4.deployed();
  console.log("GovernorContract deployed at: "+ contract4.address); 


 
  const Contract5 = await ethers.getContractFactory("PolyCareNFT");
  //contract5 = await Contract5.deploy(contract2.address);
  contract5 = await Contract5.deploy("0x0cd73F6cbe32FF4815E6FefF9852907b0Ad1D809");
  await contract5.deployed();
  console.log("NftContract deployed at: "+ contract5.address); 
*/
  console.log("----------------------------------------------------")
  console.log("Setting up contracts for roles...")
    // would be great to use multicall here...
    const contract = await hre.ethers.getContractAt("TimeLock", "0xB6d1Bf81a33c8F2A2Ed7Fcda8Cd96059E472528f");
    const treasury = await hre.ethers.getContractAt("Treasury", "0x541607EF0081c5A932aE020ABE5da119B9427272");
    const proposerRole = await contract.PROPOSER_ROLE()
    const executorRole = await contract.EXECUTOR_ROLE()
    const adminRole = await contract.TIMELOCK_ADMIN_ROLE()
  
    const proposerTx = await contract.grantRole(proposerRole, "0x58e332dDA542Fc2CFeB2464e84280d0751779a0e")
    await proposerTx.wait(1)
    const executorTx = await contract.grantRole(executorRole, "0x58e332dDA542Fc2CFeB2464e84280d0751779a0e")
    await executorTx.wait(1)
    const transferOwnership = await treasury.connect(owner).transferOwnership("0xB6d1Bf81a33c8F2A2Ed7Fcda8Cd96059E472528f")
    await transferOwnership.wait(1)
    //const revokeTx = await contract.revokeRole(adminRole, owner.address)
    //await revokeTx.wait(1)  
    
/* 
  const Contract5 = await ethers.getContractFactory("PolyCareSVG");
  //contract5 = await Contract5.deploy(contract2.address);
  contract5 = await Contract5.deploy("0xe50AAC0A78e2Ab8eB779089350c62538ADF047bD", "0x8264010c963636cBF0d6EE7C9Cc1977787FE07AB");
  await contract5.deployed();
  console.log("PolyCareSVG deployed at: "+ contract5.address); 
*/

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
