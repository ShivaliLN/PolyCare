// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./Treasury.sol";
import "hardhat/console.sol";

/**
 * @title PolyCareToken ERC20 for Governance and receiving donations
 * @notice Users who did the donation will be minted with these token so they can participate in the governance and vote. 
 * @author Shivali Sharma @ Polygon BUIDL IT Hackathon 2022 
 **/

contract PolyCareMain is ERC20Votes {
    struct Donation {
        address donor;
        uint quantity;
    }
  uint256 public s_maxSupply = 10e25; // 100M
  uint public currentSupply;
  uint public value;
  uint public minPurchase;
  uint public maxPurchase;
    
  Donation[] public donations;
  mapping(address => bool) public donors;
  mapping(address => Donation) donorQuantity;
  Treasury treasury;

  event Donate(address indexed user, uint256 amount);
  event DonateWithoutToken(address indexed user, uint256 amount);

  constructor(uint _value, address payable _treasury) ERC20("PolycareToken", "PCT") ERC20Permit("PolycareToken") {    
    value = _value;
    treasury = Treasury(_treasury);
  }

  //User will get ERC20 tokens based on the donation amount
    function donate()
        payable
        external
        {
        require(msg.value % value == 0, 'have to send a multiple of price');
        uint quantity = msg.value / value ;
        require(getTokenBalance() >= quantity, 'Not enough tokens left');
		if(donors[msg.sender]== true) {
			Donation storage donor = donorQuantity[msg.sender];
			donor.quantity += quantity;
		}else{
			donations.push(Donation(
            msg.sender,
            quantity
        ));
		donors[msg.sender]=true;
		donorQuantity[msg.sender]= Donation(msg.sender,quantity);
		}
        console.log(address(this).balance);
        (bool success, ) = address(treasury).call{value: address(this).balance}("");
        require(success, "Failed to transfer to treasury");
         _mint(msg.sender, quantity);
         currentSupply += quantity;
        emit Donate(msg.sender, msg.value);
    }

    //Function to just receive donation
    function donateWithoutToken()
        payable
        external
        {            
        (bool success, ) = address(treasury).call{value: address(this).balance}("");
        require(success, "Failed to transfer to treasury");
        emit DonateWithoutToken(msg.sender, msg.value);
    }

    function getTokenBalance() public view returns(uint balance){
            return (s_maxSupply - currentSupply);
    }

    function isDonor(address _donor) view external returns (bool) {
        return donors[_donor];
    }

  // The functions below are overrides required by Solidity.

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal override(ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal override(ERC20Votes) {
    super._burn(account, amount);
  }
}