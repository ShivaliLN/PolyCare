// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./PolyCareToken.sol";
import "./Treasury.sol";

/**
 * @title TBD
 * @notice TBD
 * @author Shivali Sharma @ Polygon Buidl Hackathon 2022 
 **/

contract Donations {	
  	struct Donation {
        address donor;
        uint quantity;
    }
        
	PolyCareToken polycareToken;
    Treasury treasury;
  	address public admin;    
    uint public price;
    uint public minPurchase;
    uint public maxPurchase;
    
	Donation[] public donations;
	mapping(address => bool) public donors;
	mapping(address => Donation) donorQuantity;

	event Donate(address indexed user, uint256 amount);
    event DonateWithoutToken(address indexed user, uint256 amount);
	
	constructor(address _owner, uint _price) {
		admin = _owner;
        price = _price;
	}

    function donate()
        payable
        external
        {
        require(msg.value % price == 0, 'have to send a multiple of price');
        uint quantity = msg.value / price ;
        require(quantity <= polycareToken.balanceOf(address(this)), 'Not enough tokens left');
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
        payable(address(treasury)).transfer(address(this).balance);
        polycareToken.transfer(msg.sender, quantity);
        emit Donate(msg.sender, msg.value);
    }

    function donateWithoutToken()
        payable
        external
        {            
        payable(address(treasury)).transfer(address(this).balance);
        emit DonateWithoutToken(msg.sender, msg.value);
    }

    function getTokenBalance() public view returns(uint balance){
            return polycareToken.balanceOf(address(this));
    }
}
