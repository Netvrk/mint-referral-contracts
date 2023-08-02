// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

import "./interfaces/IRootNft.sol";

contract NetvrkReferral is AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address private _treasury;
    address private _paymentToken;

    uint256 private _price;
    uint256 private _referralFactor;

    IRootNft private _nftContract;

    constructor(
        IRootNft nftContract_,
        address treasury_,
        address paymentToken_
    ) {
        require(
            nftContract_.supportsInterface(type(IERC721).interfaceId),
            "INVALID_NFT_CONTRACT"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _nftContract = nftContract_;
        _treasury = treasury_;
        _paymentToken = paymentToken_;
        _referralFactor = 250;

        _price = 0.1 ether;
    }

    // Update Functions for Admin
    function updateAaReferralFactor(
        uint256 AaReferralFactor_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _referralFactor = AaReferralFactor_;
    }

    function updatePrice(
        uint256 price
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = price;
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

    // AaReferral mint function
    function referralMint(
        address recipient,
        uint256 tokenId,
        uint256 cost,
        address referer
    ) external virtual nonReentrant {
        require(_price > 0, "INVALID_TIER_PRICE");
        require(cost == _price, "INVALID_PRICE");
        require(referer != address(0), "INVALID_REFERER");
        require(
            _nftContract.hasRole(MINTER_ROLE, address(this)),
            "INVALID_MINTER_ROLE"
        );

        // Check if the referer is valid
        require(_nftContract.balanceOf(referer) > 0, "INVALID_REFERER");

        require(
            _nftContract.ownerOf(tokenId) == address(0),
            "INVALID_TOKEN_ID"
        );

        // Provide revenue to referer
        uint256 treasurytake = (cost * (1000 - _referralFactor)) / 1000;
        uint256 referralTake = cost - treasurytake;
        IERC20(_paymentToken).transferFrom(
            msg.sender,
            address(this),
            treasurytake
        );
        IERC20(_paymentToken).transferFrom(msg.sender, referer, referralTake);

        _nftContract.mint(recipient, tokenId);
    }

    // Get Functions

    function getPrice() external view virtual returns (uint256) {
        return _price;
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

    function getNftContract() external view virtual returns (address) {
        return address(_nftContract);
    }
}
