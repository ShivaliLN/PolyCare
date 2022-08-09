const hre = require("hardhat");

async function main() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();
  const price = hre.ethers.utils.parseEther("0.0001");
  const minAmount = hre.ethers.utils.parseEther("0.0001");
  const maxAmount = hre.ethers.utils.parseEther("100");

  const Contract = await hre.ethers.getContractFactory("Donations");
  const contract = await Contract.deploy(owner, price, );
  await contract.deployed();
  
  

  console.log("Donations Contract deployed to:", contract.address);

  /*
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

  const lockedAmount = hre.ethers.utils.parseEther("1");

  const Lock = await hre.ethers.getContractFactory("Lock");
  const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

  await lock.deployed();

  console.log("Lock with 1 ETH deployed to:", lock.address);
  */
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
