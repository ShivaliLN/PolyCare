// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Treasury Contract that will have all the donation funds locked and governed
 * @author Shivali Sharma @ Polygon BUIDL IT Hackathon 2022 
**/

contract Treasury is Ownable {
uint public proposalId;
uint public totalDonationAmt;
uint public releasedAmt;
mapping (address => uint) public institutionAmount;
mapping (uint => bool) public idPayment;
mapping (uint => string) public idName;   // This will be used in SVG minting

event FundsReleased(uint ProposalID, address To, uint Amount);
event Received(address, uint);

/**
  @notice Below function is goverened by the timelock
**/
  function releaseFunds(address payable _to, string calldata _name,uint _amount) public onlyOwner {
    require(address(this).balance >= _amount, "Not enough funds");
    //require(idPayment[_proposalId]==false, "Payment already processed");
    //idPayment[_proposalId]=true;
    //proposalId.push(_proposalId);
    ++proposalId;
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Failed to send donation");
    institutionAmount[_to] += _amount;
    idName[proposalId] = _name;
    releasedAmt += _amount;
    emit FundsReleased(proposalId, _to, _amount);
  }

  function getIdInfo(uint _proposalId) public view returns(string memory _name){
      return idName[_proposalId];
  }

  function contractBalance() public view returns(uint) {
          return address(this).balance;
    }

receive() external payable {
        totalDonationAmt +=msg.value;
		emit Received(msg.sender, msg.value);
	}  

}