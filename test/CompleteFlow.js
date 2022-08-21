const hre = require("hardhat");
const { assert, expect } = require("chai");
const { ethers } = require("hardhat");
const { network } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const FUNC = "releaseFunds"
const PROPOSAL_DESCRIPTION = "test"
const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
const VOTING_PERIOD  = 5 // blocks
const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
const  MIN_DELAY = 1 //  How long do we have to wait until we can execute after a passed proposal

let polyCareMain, governor, svgnft, nftContract ,timelock, treasury, owner, Alice, Bob, Tom

describe("PolyCare Governor Flow", async () => {
  
  before(async () => {  
    [owner, Alice, Bob, Tom, Charity, Executor] = await ethers.getSigners();
    console.log("Owner" + owner.address)
    console.log("Alice" + Alice.address)
    console.log("Bob" + Bob.address)
    console.log("Tom" + Tom.address)
    console.log("Charity" + Charity.address)
    console.log("Executor" + Executor.address)
    console.log("----------------------------------------------------")
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

    const NftContract = await ethers.getContractFactory("PolyCareNFT");
    nftContract = await NftContract.deploy(polyCareMain.address);
    await nftContract.deployed();
    console.log("NftContract deployed at: "+ nftContract.address); 

    console.log("----------------------------------------------------")
    console.log("Setting up contracts for roles...")
    // would be great to use multicall here...
    const proposerRole = await timelock.PROPOSER_ROLE()
    const executorRole = await timelock.EXECUTOR_ROLE()
    const adminRole = await timelock.TIMELOCK_ADMIN_ROLE()
  
    const proposerTx = await timelock.grantRole(proposerRole, governor.address)
    await proposerTx.wait(1)
    const executorTx = await timelock.grantRole(executorRole, governor.address)
    await executorTx.wait(1)
    const transferOwnership = await treasury.connect(owner).transferOwnership(timelock.address)
    await transferOwnership.wait(1)
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
    console.log("Demand" + ethers.utils.parseEther("3"))
    console.log("Treasury Owner" + await treasury.owner())
    
  })

  it("Get token balance of PolyCareMain", async () => {
     console.log("ERC20Vote balance: " + await polyCareMain.getTokenBalance())
  })

  it("can only be changed through governance", async () => {
    await expect(treasury.connect(Tom).releaseFunds(Bob.address, "test", ethers.utils.parseEther("3") )).to.be.revertedWith("Ownable: caller is not the owner")
  })

  it("proposes, votes, waits, queues, and then executes", async () => {
    // propose
    const encodedFunctionCall = treasury.interface.encodeFunctionData(FUNC, [Charity.address, "test", ethers.utils.parseEther("3")])
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
    
    // Bob delegate Alice
    const voteTx1 = await polyCareMain.connect(Bob).delegate(Alice.address);
    await voteTx1.wait(1) 
    
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
    const voteTx = await governor.connect(Alice).castVoteWithReason(proposalId, voteWay, reason)
    await voteTx.wait(1)   
    
    proposalState = await governor.state(proposalId)
    assert.equal(proposalState.toString(), "1")
    console.log(`Current Proposal State: ${proposalState}`)

    console.log(await governor.proposalVotes(proposalId))
    console.log(await governor.quorum(await hre.ethers.provider.getBlockNumber()-1))   

    //await moveBlocks(VOTING_PERIOD + 1)
    let amount2 = VOTING_PERIOD + 1;
    for (let index = 0; index < amount2; index++) {
      await network.provider.request({
        method: "evm_mine",
        params: [],
      })
    }
    console.log(`Moved ${amount2} blocks: ` + await hre.ethers.provider.getBlockNumber())   
    
    // queue & execute
    // const descriptionHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(PROPOSAL_DESCRIPTION))
    const descriptionHash = ethers.utils.id(PROPOSAL_DESCRIPTION)
    const saltHash = ethers.utils.id("")
    const queueTx = await governor.queue([treasury.address], [0], [encodedFunctionCall], descriptionHash)
    await queueTx.wait(1)
    //await moveTime(MIN_DELAY + 1)
    let amount3 = MIN_DELAY + 1 + 1660573252
    await network.provider.send("evm_increaseTime", [amount3]);
    console.log(`Moved forward in time ${amount3} seconds`)
    
    proposalState = await governor.state(proposalId)
    console.log(`Current Proposal State: ${proposalState}`)

    //await moveBlocks(1)
    for (let index = 0; index < 1; index++) {
      await network.provider.request({
       method: "evm_mine",
       params: [],
     })
    }
    console.log(`Moved 1 block: ` + await hre.ethers.provider.getBlockNumber())
    //await time.increase(86400); 

    proposalState = await governor.state(proposalId)
    console.log(`Current Proposal State: ${proposalState}`)
    
    console.log("Executing...")
    const exTx = await governor.execute([treasury.address], [0], [encodedFunctionCall], descriptionHash)
    await exTx.wait(1)
    console.log("Charity new balance: " + ethers.utils.formatEther(await Charity.getBalance()));    
  }) 

  it("Add NFT token and mint", async () => {
    await nftContract.connect(Bob).addToken(5000 ,"QmV46tyKPs6qRnpDWYV9Dxd99CWPCcqw2oYsTGmYJ1nMc4");
    await nftContract.connect(Bob).mint(1)
   })

})