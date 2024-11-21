// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IRootNft.sol";

contract RootReferral is AccessControl, ReentrancyGuard {
    // Role identifier for PREDICATE role
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    // Address of the treasury where funds are collected
    address private _treasury;
    // Address of the ERC20 token used for payments
    address private _paymentToken;

    // Price of the NFT
    uint256 private _price;

    // Referral factor for calculating referral rewards
    uint256 private _referralFactor;

    // Reference to the IRootNft contract
    IRootNft private _nftContract;

    /**
     * @dev Constructor to initialize the contract with the NFT contract, treasury address, and payment token address.
     * @param nftContract_ Address of the IRootNft contract.
     * @param treasury_ Address of the treasury.
     * @param paymentToken_ Address of the ERC20 payment token.
     */
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

        _price = 100 ether;
    }

    /**
     * @dev Function to update the referral factor.
     * @param AaReferralFactor_ New referral factor to be set.
     */
    function updateAaReferralFactor(
        uint256 AaReferralFactor_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _referralFactor = AaReferralFactor_;
    }

    /**
     * @dev Function to update the price of the NFT.
     * @param price New price to be set.
     */
    function updatePrice(
        uint256 price
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = price;
    }

    /**
     * @dev Function to update the treasury address.
     * @param treasury_ New treasury address to be set.
     */
    function updateTreasury(
        address treasury_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _treasury = treasury_;
    }

    /**
     * @dev Function to withdraw the contract balance to the treasury.
     */
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

    /**
     * @dev Function to mint an NFT with referral.
     * @param recipient Address of the recipient of the NFT.
     * @param tokenId ID of the NFT to be minted.
     * @param cost Cost of the NFT in the payment token.
     * @param referer Address of the referrer.
     */
    function referralMint(
        address recipient,
        uint256 tokenId,
        uint256 cost,
        address referer
    ) external virtual nonReentrant {
        require(cost == _price, "INVALID_PRICE");
        require(referer != address(0), "INVALID_REFERER");
        require(
            _nftContract.hasRole(PREDICATE_ROLE, address(this)),
            "INVALID_PREDICATE_ROLE"
        );

        // Check if the referer is valid
        require(_nftContract.balanceOf(referer) > 0, "INVALID_REFERER");

        require(!_nftContract.exists(tokenId), "INVALID_TOKEN_ID");

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
    /**
     * @dev Function to get the price of the NFT.
     * @return Price of the NFT.
     */
    function getPrice() external view virtual returns (uint256) {
        return _price;
    }

    /**
     * @dev Function to get the referral factor.
     * @return Referral factor.
     */
    function getReferralFactor() external view virtual returns (uint256) {
        return _referralFactor;
    }

    /**
     * @dev Function to get the treasury address.
     * @return Address of the treasury.
     */
    function getTreasury() external view virtual returns (address) {
        return _treasury;
    }

    /**
     * @dev Function to get the payment token address.
     * @return Address of the payment token.
     */
    function getPaymentToken() external view virtual returns (address) {
        return _paymentToken;
    }

    /**
     * @dev Function to get the address of the NFT contract.
     * @return Address of the NFT contract.
     */
    function getNftContract() external view virtual returns (address) {
        return address(_nftContract);
    }
}
