// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Treasury Contract that will have all the donation funds locked and governed
 * @author Shivali Sharma @ Polygon BUIDL IT Hackathon 2022 
**/

contract Treasury is Ownable {
mapping (address => uint) public institutionAmount;
mapping (uint => bool) public idPayment;
mapping (uint => string) public idName;
uint[] public proposalId;

event FundsReleased(uint ProposalID, address To, uint Amount);
event Received(address, uint);

//This contract with have function to release funds to oldage homes
  function releaseFunds(uint _proposalId, address payable _to, string calldata _name,uint _amount) public onlyOwner {
    require(address(this).balance >= _amount, "Not enough funds");
    require(idPayment[_proposalId]==false, "Payment already processed");
    idPayment[_proposalId]=true;
    proposalId.push(_proposalId);
    //payable(address(_to)).transfer(_amount);
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Failed to send donation");
    institutionAmount[_to] += _amount;
    idName[_proposalId] = _name;
    emit FundsReleased(_proposalId, _to, _amount);
  }

  function getIdInfo(uint _proposalId) public view returns(string memory _name){
      return idName[_proposalId];
  }

  function isValidProposalId(uint _proposalId) public view returns(bool){
      for(uint i=0; i < proposalId.length; i++){
          if(_proposalId == proposalId[i]) return true;
      }
      return false;
  }

  function contractBalance() public view returns(uint) {
          return address(this).balance;
    }

receive() external payable {
		emit Received(msg.sender, msg.value);
	}  

}