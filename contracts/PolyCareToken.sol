// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @title PolyCareToken ERC20 for Governance
 * @notice Users who did the donation will be minted with these token so they can participate in the governance and vote. 
 * @author Shivali Sharma @ Polygon BUIDL IT Hackathon 2022 
 **/

contract PolyCareToken is ERC20Votes {
  uint256 public s_maxSupply = 10e25; // 100M
  address public donations;
  
  constructor(address _donation) ERC20("PolycareToken", "PCT") ERC20Permit("PolycareToken") {
    donations = _donation;
    _mint(_donation, s_maxSupply);
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