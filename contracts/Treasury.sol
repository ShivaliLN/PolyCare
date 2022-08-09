// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TBD
 * @notice TBD
 * @author Shivali Sharma @ Polygon Buidl Hackathon 2022 
 **/

contract Treasury is Ownable {
mapping (address => uint) institutionAmount;
mapping (uint => bool) idPayment;

event FundsReleased(uint ID, address To, uint Amount);

//This contract with have function to release funds to oldage homes
  function releaseFunds(uint _id, address _to, uint _amount) public onlyOwner {
    require(address(this).balance >= _amount, "Not enough funds");
    require(idPayment[_id]==false, "Payment already processed");
    idPayment[_id]=true;
    payable(address(_to)).transfer(_amount);
    emit FundsReleased(_id, _to, _amount);
  }

receive() external payable {
		
	}  

}