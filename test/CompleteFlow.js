const hre = require("hardhat");
const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
const { network } = require("hardhat");

const FUNC = "releaseFunds"
const PROPOSAL_DESCRIPTION = "The charity Red Cross is willing to provide daycare services for the nearby orphange Little Feet located at 6th Street"
const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
const VOTING_PERIOD  = 5 // blocks
const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
const  MIN_DELAY = 3600 // 1 hour - after a vote passes, you have 1 hour before you can enact
const ADDRESS_ZERO = "0x0000000000000000000000000000000000000078"
let polyCareMain, governor, svgnft, erc20vote, timelock, treasury, owner, Alice, Bob, Tom

describe("PolyCare Governor Flow", async () => {
  
  before(async () => {  
    [owner, Alice, Bob, Tom, Charity] = await ethers.getSigners();

    const Treasury = await ethers.getContractFactory("Treasury");
    treasury = await Treasury.deploy();
    await treasury.deployed();
    console.log("Treasury deployed at: "+ treasury.address);

    const PolyCareMain = await ethers.getContractFactory("PolyCareMain");
    polyCareMain = await PolyCareMain.deploy(ethers.utils.parseEther("0.0002"), treasury.address);
    await polyCareMain.deployed();
    console.log("PolyCareMain deployed at: "+ polyCareMain.address); 

    const Timelock = await ethers.getContractFactory("TimeLock");
    timelock = await Timelock.deploy(MIN_DELAY, [], []);
    await timelock.deployed();
    console.log("Timelock deployed at: "+ timelock.address); 

    const Governor = await ethers.getContractFactory("GovernorContract");
    governor = await Governor.deploy(polyCareMain.address, timelock.address, QUORUM_PERCENTAGE, VOTING_PERIOD, VOTING_DELAY);
    await governor.deployed();
    console.log("Governor deployed at: "+ governor.address); 
  
    const Svgnft = await ethers.getContractFactory("PolyCareSVG");
    svgnft = await Svgnft.deploy(treasury.address, polyCareMain.address);
    await svgnft.deployed();
    console.log("Svgnft deployed at: "+ svgnft.address);  
    
    console.log("----------------------------------------------------")
    console.log("Setting up contracts for roles...")
    // would be great to use multicall here...
    const proposerRole = await timelock.PROPOSER_ROLE()
    const executorRole = await timelock.EXECUTOR_ROLE()
    const adminRole = await timelock.TIMELOCK_ADMIN_ROLE()
  
    const proposerTx = await timelock.grantRole(proposerRole, governor.address)
    await proposerTx.wait(1)
    const executorTx = await timelock.grantRole(executorRole, ADDRESS_ZERO)
    await executorTx.wait(1)
    const revokeTx = await timelock.revokeRole(adminRole, owner.address)
    await revokeTx.wait(1)

  })

  it("receives donation and mints token to donor", async () => {
    await polyCareMain.connect(Bob).donate({value: ethers.utils.parseEther("2")})
    console.log("Bob token balance: " + await polyCareMain.balanceOf(Bob.address))
    
  })

  it("Treasury receives donation", async () => {
    console.log("Treasury balance: " + await treasury.contractBalance())
  })

  it("receives donation without token mint", async () => {
    await polyCareMain.connect(Bob).donateWithoutToken({value: ethers.utils.parseEther("3")})
    console.log("Bob token balance: " + await polyCareMain.balanceOf(Bob.address))
    console.log("Treasury balance: " + await treasury.contractBalance())
    
  })

  it("Get token balance of PolyCareMain", async () => {
     console.log("ERC20Vote balance: " + await polyCareMain.getTokenBalance())
  })

  it("can only be changed through governance", async () => {
    await expect(treasury.connect(Tom).releaseFunds(7, Bob.address, "test", ethers.utils.parseEther("3") )).to.be.revertedWith("Ownable: caller is not the owner")
  })

  it("proposes, votes, waits, queues, and then executes", async () => {
    // propose
    const encodedFunctionCall = treasury.interface.encodeFunctionData(FUNC, [7, Charity.address, "test", ethers.utils.parseEther("3")])
    const proposeTx = await governor.propose(
      [treasury.address],
      [0],
      [encodedFunctionCall],
      PROPOSAL_DESCRIPTION
    )

    const proposeReceipt = await proposeTx.wait(1)
    const proposalId = proposeReceipt.events[0].args.proposalId
    let proposalState = await governor.state(proposalId)
    console.log("Proposal ID: " + proposalId)
    console.log(`Current Proposal State: ${proposalState}`)    

    //await moveBlocks(VOTING_DELAY + 1)
    let amount = VOTING_DELAY + 1;
    for (let index = 0; index < amount; index++) {
      await network.provider.request({
        method: "evm_mine",
        params: [],
      })
    }
    console.log(`Moved ${amount} blocks`)
    // vote
    const voteWay = 1 // for
    const reason = "I support this cause"
    const voteTx = await governor.castVoteWithReason(proposalId, voteWay, reason)
    await voteTx.wait(1)   
    
    proposalState = await governor.state(proposalId)
    assert.equal(proposalState.toString(), "1")
    console.log(`Current Proposal State: ${proposalState}`)

    console.log(await governor.proposalVotes(proposalId))
    console.log()
    console.log(await governor.quorum(await hre.ethers.provider.getBlockNumber()-1))   
 
    /*

    //await moveBlocks(VOTING_PERIOD + 1)
    let amount2 = VOTING_PERIOD + 1;
    for (let index = 0; index < amount2; index++) {
      await network.provider.request({
        method: "evm_mine",
        params: [],
      })
    }
    console.log(`Moved ${amount2} blocks`)   

    // queue & execute
    // const descriptionHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(PROPOSAL_DESCRIPTION))
    const descriptionHash = ethers.utils.id(PROPOSAL_DESCRIPTION)
    const queueTx = await governor.queue([treasury.address], [0], [encodedFunctionCall], descriptionHash)
    await queueTx.wait(1)
    //await moveTime(MIN_DELAY + 1)
    let amount3 = MIN_DELAY + 1
    await network.provider.send("evm_increaseTime", [amount3])
    console.log(`Moved forward in time ${amount3} seconds`)

    //await moveBlocks(1)
    for (let index = 0; index < 1; index++) {
      await network.provider.request({
        method: "evm_mine",
        params: [],
      })
    }
    console.log(`Moved 1 block`)


    proposalState = await governor.state(proposalId)
    console.log(`Current Proposal State: ${proposalState}`)

    console.log("Executing...")
    console.log
    const exTx = await governor.execute([treasury.address], [0], [encodedFunctionCall], descriptionHash)
    await exTx.wait(1)
    console.log(ethers.utils.formatEther(await Charity.getBalance()));
    */
  }) 
})