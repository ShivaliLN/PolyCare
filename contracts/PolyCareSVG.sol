// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "contracts/Treasury.sol";
import "contracts/PolyCareMain.sol";

/**
 * @title PolyCareSVG NFT contract
 * @notice Users who did the donation can mint NFT of any charity organization where the funds where given. SVG NFTs are dynamically created based on the charity organization name.
 * @author Shivali Sharma @ Polygon BUIDL IT Hackathon 2022 
 **/

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

contract PolyCareSVG is ERC721, ERC721Enumerable, Ownable {
    mapping(uint256 => Attr) public attributes;
    mapping(address => mapping (uint=> bool)) public userMinted;

    struct Attr {
        string name; 
    }
    
    Treasury treasury;
    PolyCareMain polyCareMain;

    constructor(address payable _treasury, address payable _polyCareMain) ERC721("Polycare", "POLYC") {
        treasury = Treasury(_treasury);  
        polyCareMain = PolyCareMain(_polyCareMain);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice checkUpKeep will monitor if any new agreement has been created by 'CricNFTTeamAgreement.sol'
     * @dev Register/Setup keepers on both Kovan and Polygon
     * @param to address to which NFT will be minted
     * @param tokenId token id associated with Goverance Proposal for which funds where donated 
    */
    function mint(
        address to, 
        uint256 tokenId
        ) 
    public {
        require(userMinted[to][tokenId]==false, "User already minted this NFT");
        require(polyCareMain.isDonor(to)==true, "User is not listed as a donor"); 
        require(treasury.isValidProposalId(tokenId) == true, "Invalid Token Id"); 
        _safeMint(to, tokenId);
        attributes[tokenId] = Attr(treasury.getIdInfo(tokenId));
        userMinted[to][tokenId]=true;
    }

    function getSvg(uint tokenId, string memory  _name) private pure returns (string memory) {
        string memory svg;
        svg = "<svg width='350px' height='350px' viewBox='0 0 24 24' fill='none' xmlns='http://www.w3.org/2000/svg'> <path d='M11.55 18.46C11.3516 18.4577 11.1617 18.3789 11.02 18.24L5.32001 12.53C5.19492 12.3935 5.12553 12.2151 5.12553 12.03C5.12553 11.8449 5.19492 11.6665 5.32001 11.53L13.71 3C13.8505 2.85931 14.0412 2.78017 14.24 2.78H19.99C20.1863 2.78 20.3745 2.85796 20.5133 2.99674C20.652 3.13552 20.73 3.32374 20.73 3.52L20.8 9.2C20.8003 9.40188 20.7213 9.5958 20.58 9.74L12.07 18.25C11.9282 18.3812 11.7432 18.4559 11.55 18.46ZM6.90001 12L11.55 16.64L19.3 8.89L19.25 4.27H14.56L6.90001 12Z' fill='red'/> <path d='M14.35 21.25C14.2512 21.2522 14.153 21.2338 14.0618 21.1959C13.9705 21.158 13.8882 21.1015 13.82 21.03L2.52 9.73999C2.38752 9.59782 2.3154 9.40977 2.31883 9.21547C2.32226 9.02117 2.40097 8.83578 2.53838 8.69837C2.67579 8.56096 2.86118 8.48224 3.05548 8.47882C3.24978 8.47539 3.43783 8.54751 3.58 8.67999L14.88 20C15.0205 20.1406 15.0993 20.3312 15.0993 20.53C15.0993 20.7287 15.0205 20.9194 14.88 21.06C14.7353 21.1907 14.5448 21.259 14.35 21.25Z' fill='red'/> <path d='M6.5 21.19C6.31632 21.1867 6.13951 21.1195 6 21L2.55 17.55C2.47884 17.4774 2.42276 17.3914 2.385 17.297C2.34724 17.2026 2.32855 17.1017 2.33 17C2.33 16.59 2.33 16.58 6.45 12.58C6.59063 12.4395 6.78125 12.3607 6.98 12.3607C7.17876 12.3607 7.36938 12.4395 7.51 12.58C7.65046 12.7206 7.72934 12.9112 7.72934 13.11C7.72934 13.3087 7.65046 13.4994 7.51 13.64C6.22001 14.91 4.82 16.29 4.12 17L6.5 19.38L9.86 16C9.92895 15.9292 10.0114 15.873 10.1024 15.8346C10.1934 15.7962 10.2912 15.7764 10.39 15.7764C10.4888 15.7764 10.5866 15.7962 10.6776 15.8346C10.7686 15.873 10.8511 15.9292 10.92 16C11.0605 16.1406 11.1393 16.3312 11.1393 16.53C11.1393 16.7287 11.0605 16.9194 10.92 17.06L7 21C6.8614 21.121 6.68402 21.1884 6.5 21.19Z' fill='red'/> </svg>";
        //svg = "<svg id='visual' viewBox='0 0 150 250' width='150' height='250' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' version='1.1'><path d='M0 76L14 76L14 104L27 104L27 54L41 54L41 89L55 89L55 59L68 59L68 51L82 51L82 69L95 69L95 54L109 54L109 49L123 49L123 59L136 59L136 39L150 39L150 71L150 0L150 0L136 0L136 0L123 0L123 0L109 0L109 0L95 0L95 0L82 0L82 0L68 0L68 0L55 0L55 0L41 0L41 0L27 0L27 0L14 0L14 0L0 0Z' fill='#fa7268'/><path d='M0 101L14 101L14 121L27 121L27 64L41 64L41 111L55 111L55 71L68 71L68 81L82 81L82 94L95 94L95 86L109 86L109 79L123 79L123 89L136 89L136 69L150 69L150 99L150 69L150 37L136 37L136 57L123 57L123 47L109 47L109 52L95 52L95 67L82 67L82 49L68 49L68 57L55 57L55 87L41 87L41 52L27 52L27 102L14 102L14 74L0 74Z' fill='#f16669'/><path d='M0 141L14 141L14 141L27 141L27 79L41 79L41 134L55 134L55 106L68 106L68 109L82 109L82 111L95 111L95 116L109 116L109 106L123 106L123 111L136 111L136 99L150 99L150 114L150 97L150 67L136 67L136 87L123 87L123 77L109 77L109 84L95 84L95 92L82 92L82 79L68 79L68 69L55 69L55 109L41 109L41 62L27 62L27 119L14 119L14 99L0 99Z' fill='#e75b69'/><path d='M0 174L14 174L14 171L27 171L27 124L41 124L41 164L55 164L55 154L68 154L68 139L82 139L82 144L95 144L95 149L109 149L109 149L123 149L123 149L136 149L136 151L150 151L150 161L150 112L150 97L136 97L136 109L123 109L123 104L109 104L109 114L95 114L95 109L82 109L82 107L68 107L68 104L55 104L55 132L41 132L41 77L27 77L27 139L14 139L14 139L0 139Z' fill='#dc506a'/><path d='M0 224L14 224L14 211L27 211L27 194L41 194L41 221L55 221L55 211L68 211L68 224L82 224L82 204L95 204L95 199L109 199L109 206L123 206L123 219L136 219L136 214L150 214L150 199L150 159L150 149L136 149L136 147L123 147L123 147L109 147L109 147L95 147L95 142L82 142L82 137L68 137L68 152L55 152L55 162L41 162L41 122L27 122L27 169L14 169L14 172L0 172Z' fill='#d0456b'/><path d='M0 234L14 234L14 234L27 234L27 221L41 221L41 231L55 231L55 231L68 231L68 234L82 234L82 229L95 229L95 226L109 226L109 224L123 224L123 231L136 231L136 226L150 226L150 226L150 197L150 212L136 212L136 217L123 217L123 204L109 204L109 197L95 197L95 202L82 202L82 222L68 222L68 209L55 209L55 219L41 219L41 192L27 192L27 209L14 209L14 222L0 222Z' fill='#c43b6c'/><path d='M0 251L14 251L14 251L27 251L27 251L41 251L41 251L55 251L55 251L68 251L68 251L82 251L82 251L95 251L95 251L109 251L109 251L123 251L123 251L136 251L136 251L150 251L150 251L150 224L150 224L136 224L136 229L123 229L123 222L109 222L109 224L95 224L95 227L82 227L82 232L68 232L68 229L55 229L55 229L41 229L41 219L27 219L27 232L14 232L14 232L0 232Z' fill='#b7326c'/></svg>";
        return svg;
    }    

    function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {
        string memory json = Base64.encode(
            bytes(string(
                abi.encodePacked(
                    '{"name": "', attributes[tokenId].name, '",',
                    '"image_data": "', getSvg(tokenId, attributes[tokenId].name), '",',
                     '"attributes": [{',',]}'
                   // '"attributes": [{"trait_type": "Speed", "value": ', uint2str(attributes[tokenId].speed), '},',
                   // '{"trait_type": "Attack", "value": ', uint2str(attributes[tokenId].attack), '},',
                   // '{"trait_type": "Defence", "value": ', uint2str(attributes[tokenId].defence), '},',
                   // '{"trait_type": "Material", "value": "', attributes[tokenId].material, '"}',
                   // ']}'
                )
            ))
        );
        return string(abi.encodePacked('data:application/json;base64,', json));
    }    
}