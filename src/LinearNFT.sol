// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC721} from "@solmate/tokens/ERC721.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

import {toDaysWadUnsafe} from "@solmate/utils/SignedWadMath.sol";

import {LinearVRGDA} from "@vrgdas/LinearVRGDA.sol";

/// @title Linear VRGDA NFT
/// @author transmissions11 <t11s@paradigm.xyz>
/// @author FrankieIsLost <frankie@paradigm.xyz>
/// @notice Example NFT sold using LinearVRGDA.
/// @dev This is an example. Do not use in production.
abstract contract LinearNFT is ERC721, LinearVRGDA {
    /*//////////////////////////////////////////////////////////////
                              SALES STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSold; // The total number of tokens sold so far.

    uint256 public immutable startTime = block.timestamp; // When VRGDA sales begun.

    string internal __tokenURI;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 targetPrice,
        uint256 priceDecayPercent,
        uint256 perTimeUnit
    )
        ERC721(_name, _symbol)
        LinearVRGDA(
            targetPrice, // '69.42e18'
            priceDecayPercent, // '0.31e18'
            perTimeUnit // '2e18'
        )
    {
        __tokenURI = _tokenURI;
    }

    /*//////////////////////////////////////////////////////////////
                              MINTING LOGIC
    //////////////////////////////////////////////////////////////*/

    error Underpaid();

    function mint() public payable returns (uint256 mintedId) {
        unchecked {
            // Note: By using toDaysWadUnsafe(block.timestamp - startTime) we are establishing that 1 "unit of time" is 1 day.
            uint256 price =
                getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), mintedId = totalSold++);

            require(msg.value >= price, Underpaid()); // Don't allow underpaying.

            _mint(msg.sender, mintedId); // Mint the NFT using mintedId.

            // Note: We do this at the end to avoid creating a reentrancy vector.
            // Refund the user any ETH they spent over the current price of the NFT.
            // Unchecked is safe here because we validate msg.value >= price above.
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        }
    }

    /*//////////////////////////////////////////////////////////////
                                URI LOGIC
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256) public pure override(ERC721) returns (string memory) {
        return __tokenURI;
    }
}
