// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/PolyCareMain.sol";

/**
 * @title PolyCareSVG NFT contract
 * @notice Users who did the donation can mint NFT of any charity organization where the funds where given. SVG NFTs are dynamically created based on the charity organization name.
 * @author Shivali Sharma @ Polygon BUIDL IT Hackathon 2022 
 **/

contract PolyCareNFT is ERC1155 {
    
    using SafeMath for uint;

    uint256[] public tokens;
    uint256[] public supplies;
    uint256[] public minted;
    
    mapping(uint => string) tokenURIs;
        
    PolyCareMain polyCareMain;
    
    event TokenAdded(uint indexed id, uint supply, string indexed imageCID, string cid);  
    event Minted(address indexed user,uint indexed tokenId, uint indexed quantity);
   
    constructor(address _polyCareMain) ERC1155("https://gateway.pinata.cloud/ipfs/{CID}") {
        polyCareMain = PolyCareMain(_polyCareMain);    
    }
    
  /**
  @notice Once the metadata of the NFT has been uploaded on IPFS/Filecoin, this function is called to add the token by IPL Team Owner
  @dev Set supply, minted and rate arrays. Date coming from CricNFTTeamAgreement contract
  @param _id uint
  @param _imageCID bytes32
  @param _cid string
  **/
    function addToken(uint _id, uint _totalNumOfTokenstoMint, string calldata _imageCID, string calldata _cid) public{
        require(polyCareMain.isDonor(msg.sender)==true, "You have not donated to PolyCare");
        //check for duplicate token id
        tokens.push(_id);
        supplies.push(_totalNumOfTokenstoMint);
        minted.push(0);
        //example: tokenURIs[1]="QmU7fyhpadQEouGUohCAiZ4e7NxfujFKbieHAPKESe6jt9";
        tokenURIs[_id]=_cid;
        //tokenForSeason[msg.sender][seasonId]=true;
        emit TokenAdded(_id, _totalNumOfTokenstoMint, _imageCID ,_cid);
    }

/**
  @notice ERC1155 Mint Function to mint the NFT
  @param id uint
  @param amount uint
**/

    function mint(uint256 id, uint256 amount)
        public
    {
        require(polyCareMain.isDonor(msg.sender)==true, "You have not donated to PolyCare");
        require(id <= supplies.length, "Invalid Token Id" );
        require(id > 0, "Invalid Token Id");
        uint index = id-1;
        require(minted[index]+ amount <= supplies[index], "Not enough supply");
        require(SafeMath.add(balanceOf(msg.sender, id),amount) < 6, "You can only mint upto 5 NFTs for a given id");
                        
        _mint(msg.sender, id, amount, "");
        minted[index] += amount;
        emit Minted(msg.sender,id, amount);
    }

 /**
  @notice set correct URI based on the token id
  @param _tokenId uint
**/

    function uri(uint256 _tokenId) override public view returns (string memory){
        string memory _cid=tokenURIs[_tokenId];
        return string(abi.encodePacked("https://gateway.pinata.cloud/ipfs/",_cid));
    }

 /**
  @notice Function to allow users to query the remaining supply
  @param _tokenId uint
**/
    function querySupplyLeftRate(uint256 _tokenId) external view returns (uint _supply){
            uint index = _tokenId-1;
            _supply = supplies[index]-minted[index];
    } 

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }      
}
