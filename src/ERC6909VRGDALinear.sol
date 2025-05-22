// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {LinearNFT} from "./LinearNFT.sol";

/// @title ERC6909VRGDALinear
/// @notice NFT contract using VRGDA pricing where each NFT represents a claim to ERC6909 tokens.
contract ERC6909VRGDALinear is LinearNFT {
    /*//////////////////////////////////////////////////////////////
                              CLAIM STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public immutable coinId;
    uint256 public immutable coinsPerNFT;
    IERC6909 public immutable coinContract;
    address public immutable zammContract;
    uint256 public immutable supplyForSale;

    // Track remaining claimable balance per NFT
    mapping(uint256 => uint256) public claimableBalance;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 targetPrice,
        uint256 priceDecayPercent,
        uint256 perTimeUnit,
        address _coinContract,
        address _zammContract,
        uint256 _nftsForSale,
        uint256 _supplyForSale,
        uint256 creatorSupply,
        address creator
    ) payable LinearNFT(_name, _symbol, _tokenURI, targetPrice, priceDecayPercent, perTimeUnit) {
        coinContract = IERC6909(_coinContract);
        zammContract = _zammContract;
        coinId = _predictId(_name, _symbol);
        coinsPerNFT = _supplyForSale / _nftsForSale;

        ICOINS(_coinContract).setOperator(address(ZAMM), true);
        ICOINS(_coinContract).create(
            _name, _symbol, _tokenURI, address(this), _supplyForSale + creatorSupply
        );

        if (creatorSupply != 0) ICOINS(COINS).transfer(creator, coinId, creatorSupply); // Optional.
        ICOINS(COINS).transferOwnership(coinId, address(0)); // Lock further minting or URI updates.
    }

    /*//////////////////////////////////////////////////////////////
                            OVERRIDDEN MINTING
    //////////////////////////////////////////////////////////////*/

    function mint() public payable override(LinearNFT) returns (uint256 mintedId) {
        // Call parent mint function to handle VRGDA pricing and NFT minting.
        mintedId = super.mint();

        // Set the claimable balance for this NFT.
        claimableBalance[mintedId] = coinsPerNFT;
    }

    /*//////////////////////////////////////////////////////////////
                             CLAIM FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /// @notice Claim coins from NFT to another address
    /// @param nftId ID of the NFT to transfer coins from
    /// @param to The address to transfer tokens towards
    /// @param amount The amount of tokens to transfer
    function claim(uint256 nftId, address to, uint256 amount) public {
        require(ownerOf(nftId) == msg.sender, Unauthorized());

        claimableBalance[nftId] -= amount; // Reverts if insufficient claim.

        coinContract.transfer(to, coinId, amount);
    }

    // helpers

    function _predictId(string calldata name, string calldata symbol)
        internal
        pure
        returns (uint256 predicted)
    {
        bytes32 salt = keccak256(abi.encodePacked(name, COINS, symbol));
        predicted = uint256(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            COINS,
                            salt,
                            bytes32(
                                0x6594461b4ce3b23f6cbdcdcf50388d5f444bf59a82f6e868dfd5ef2bfa13f6d4
                            )
                        )
                    )
                )
            )
        );
    }

    function _computePoolId(PoolKey memory poolKey) internal pure returns (uint256 poolId) {
        assembly ("memory-safe") {
            poolId := keccak256(poolKey, 0xa0)
        }
    }
}

interface IERC6909 {
    function transfer(address to, uint256 id, uint256 amount) external returns (bool);
}

interface ICOINS {
    function transferOwnership(uint256, address) external;
    function setOperator(address, bool) external returns (bool);
    function transfer(address, uint256, uint256) external returns (bool);
    function transferFrom(address, address, uint256, uint256) external returns (bool);
    function create(string calldata, string calldata, string calldata, address, uint256) external;
}
