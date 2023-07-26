// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

import "./interfaces/INFT.sol";

contract Referral is AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address private _treasury;
    address private _paymentToken;

    mapping(uint256 => uint256) private _tierPrices;
    uint256 private _referralFactor;

    INFT private _nftContract;

    constructor(INFT nftContract_, address treasury_, address paymentToken_) {
        require(
            nftContract_.supportsInterface(type(IERC721).interfaceId),
            "INVALID_NFT_CONTRACT"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _nftContract = nftContract_;
        _treasury = treasury_;
        _paymentToken = paymentToken_;
        _referralFactor = 250;
    }

    // Update Functions for Admin
    function updateReferralFactor(
        uint256 referralFactor_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _referralFactor = referralFactor_;
    }

    function updateTierPrice(
        uint256 tierId,
        uint256 price
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _tierPrices[tierId] = price;
    }

    function updateTreasury(
        address treasury_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _treasury = treasury_;
    }

    // Withdraw function for Admin
    function withdraw()
        external
        virtual
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 balance = IERC20(_paymentToken).balanceOf(address(this));
        require(balance > 0, "ZERO_BALANCE");
        IERC20(_paymentToken).transfer(_treasury, balance);
    }

    // Referral mint function
    function referralMint(
        address recipient,
        uint256 tierId,
        uint256 tierSize,
        uint256 cost,
        address referer
    ) external virtual nonReentrant {
        require(_tierPrices[tierId] > 0, "INVALID_TIER_PRICE");
        require(cost == _tierPrices[tierId] * tierSize, "INVALID_PRICE");
        require(referer != address(0), "INVALID_REFERER");
        require(
            _nftContract.hasRole(MINTER_ROLE, address(this)),
            "INVALID_MINTER_ROLE"
        );

        // Check if the referer is valid
        require(_nftContract.balanceOf(referer) > 0, "INVALID_REFERER");

        // Provide revenue to referer
        uint256 treasurytake = (cost * (1000 - _referralFactor)) / 1000;
        uint256 referralTake = cost - treasurytake;
        IERC20(_paymentToken).transferFrom(
            msg.sender,
            address(this),
            treasurytake
        );
        IERC20(_paymentToken).transferFrom(msg.sender, referer, referralTake);

        // Mint NFT
        address[] memory recipients = new address[](1);
        recipients[0] = recipient;

        uint256[] memory tierIds = new uint256[](1);
        tierIds[0] = tierId;

        uint256[] memory tierSizes = new uint256[](1);
        tierSizes[0] = tierSize;

        _nftContract.bulkMint(recipients, tierIds, tierSizes);
    }

    // Get Functions

    function getTierPrice(
        uint256 tierId
    ) external view virtual returns (uint256) {
        return _tierPrices[tierId];
    }

    function getReferralFactor() external view virtual returns (uint256) {
        return _referralFactor;
    }

    function getTreasury() external view virtual returns (address) {
        return _treasury;
    }

    function getPaymentToken() external view virtual returns (address) {
        return _paymentToken;
    }

    function getNFTContract() external view virtual returns (address) {
        return address(_nftContract);
    }
}
