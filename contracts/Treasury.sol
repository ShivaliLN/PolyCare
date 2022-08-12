// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TBD
 * @notice TBD
 * @author Shivali Sharma @ Polygon Buidl Hackathon 2022 
 **/

contract Treasury is Ownable {
mapping (address => uint) public institutionAmount;
mapping (uint => bool) public idPayment;
mapping (uint => string) public idName;

event FundsReleased(uint ID, address To, uint Amount);

//This contract with have function to release funds to oldage homes
  function releaseFunds(uint _id, address payable _to, string calldata _name,uint _amount) public onlyOwner {
    require(address(this).balance >= _amount, "Not enough funds");
    require(idPayment[_id]==false, "Payment already processed");
    idPayment[_id]=true;
    //payable(address(_to)).transfer(_amount);
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Failed to send donation");
    institutionAmount[_to] += _amount;
    idName[_id] = _name;
    emit FundsReleased(_id, _to, _amount);
  }

  function getIdInfo(uint _id) public view returns(string memory _name){
      return idName[_id];
  }

receive() external payable {
		
	}  

}