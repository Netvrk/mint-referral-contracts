// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// Importing necessary contracts from OpenZeppelin for security, access control, and token interfaces
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IMRNft.sol";

/**
 * @title MrReferral Contract
 * @dev This contract allows for a referral-based NFT minting system, where users can mint NFTs by referring others.
 * It supports referral revenue distribution, dynamic pricing, and access control.
 * The contract includes functions for managing referral factors, pricing, and treasury address updates,
 * as well as the minting process and withdrawal capabilities for the administrator.
 */
contract MrReferral is AccessControl, ReentrancyGuard {
    // Define the role for the manager, which controls certain privileged functions
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    // Address of the treasury that will receive the funds
    address private _treasury;

    // Address of the ERC20 token used for payments
    address private _paymentToken;

    // Price per NFT minting and the referral factor (percentage of the cost that goes to the referrer)
    uint256 private _price;
    uint256 private _referralFactor;

    // Interface for interacting with the MRNft contract
    IMrNft private _nftContract;

    /**
     * @dev Constructor to initialize the MrReferral contract with required addresses and pricing.
     * @param nftContract_ Address of the IMrNft contract
     * @param treasury_ Address of the treasury that will receive the funds
     * @param paymentToken_ Address of the payment token (ERC20)
     */
    constructor(IMrNft nftContract_, address treasury_, address paymentToken_) {
        // Ensure the provided NFT contract supports the IERC721 interface
        require(
            nftContract_.supportsInterface(type(IERC721).interfaceId),
            "INVALID_NFT_CONTRACT"
        );

        // Setting up access control: the deployer is the admin by default
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initialize the NFT contract, treasury, and payment token addresses
        _nftContract = nftContract_;
        _treasury = treasury_;
        _paymentToken = paymentToken_;

        // Default referral factor is 250 basis points (25%)
        _referralFactor = 250;

        // Default price for minting an NFT
        _price = 100 ether;
    }

    // =====================
    // ADMINISTRATION FUNCTIONS
    // =====================

    /**
     * @dev Update the referral factor (percentage of cost for the referrer).
     * @param AaReferralFactor_ The new referral factor, given in basis points (e.g., 250 is 25%).
     */
    function updateAaReferralFactor(
        uint256 AaReferralFactor_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _referralFactor = AaReferralFactor_;
    }

    /**
     * @dev Update the price of the NFTs.
     * @param price The new price of an NFT in the chosen ERC20 token (e.g., Ether).
     */
    function updatePrice(
        uint256 price
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = price;
    }

    /**
     * @dev Update the address of the treasury where the contract funds will be sent.
     * @param treasury_ The new treasury address.
     */
    function updateTreasury(
        address treasury_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _treasury = treasury_;
    }

    /**
     * @dev Allows the admin to withdraw the ERC20 token balance of the contract to the treasury.
     * This function ensures the contract's balance is transferred securely and only by an admin.
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

    // =======================
    // REFERRAL MINTING FUNCTION
    // =======================

    /**
     * @dev Allows a user to mint an NFT for another user, using a referral mechanism.
     * The minting process will charge the sender the price, split the revenue between the treasury and the referrer,
     * and mint an NFT to the recipient.
     * @param recipient The address of the user who will receive the minted NFT
     * @param axeId The unique ID of the NFT being minted
     * @param axeType The type or category of the NFT being minted
     * @param cost The cost associated with minting the NFT
     * @param referer The address of the user who referred the recipient
     */
    function referralMint(
        address recipient,
        string memory axeId,
        string memory axeType,
        uint256 cost,
        address referer
    ) external virtual nonReentrant {
        // Ensure the price is valid and the cost matches the set price
        require(_price > 0, "INVALID_TIER_PRICE");
        require(cost == _price, "INVALID_PRICE");
        require(referer != address(0), "INVALID_REFERER");
        require(
            _nftContract.hasRole(MANAGER_ROLE, address(this)),
            "INVALID_MANAGER"
        );

        // Check if the referer is valid
        require(_nftContract.balanceOf(referer) > 0, "INVALID_REFERER");

        require(_nftContract.axeIdToTokenId(axeId) == 0, "AXE_ALREADY_MINTED");

        // Provide revenue to referer
        uint256 treasurytake = (cost * (1000 - _referralFactor)) / 1000;
        uint256 referralTake = cost - treasurytake;
        IERC20(_paymentToken).transferFrom(
            msg.sender,
            address(this),
            treasurytake
        );
        IERC20(_paymentToken).transferFrom(msg.sender, referer, referralTake);

        _nftContract.mintItem(recipient, axeId, axeType);
    }

    // ==========================
    // GETTER FUNCTIONS
    // ==========================

    /**
     * @dev Get the current price for minting an NFT.
     * @return The price in the chosen ERC20 token.
     */
    function getPrice() external view virtual returns (uint256) {
        return _price;
    }

    /**
     * @dev Get the current referral factor (percentage for the referrer).
     * @return The referral factor in basis points (e.g., 250 for 25%).
     */
    function getReferralFactor() external view virtual returns (uint256) {
        return _referralFactor;
    }

    /**
     * @dev Get the address of the treasury.
     * @return The address of the treasury.
     */
    function getTreasury() external view virtual returns (address) {
        return _treasury;
    }

    /**
     * @dev Get the address of the payment token used for minting.
     * @return The address of the ERC20 payment token.
     */
    function getPaymentToken() external view virtual returns (address) {
        return _paymentToken;
    }

    /**
     * @dev Get the address of the NFT contract being used by the MrReferral contract.
     * @return The address of the IMrNft contract.
     */
    function getNftContract() external view virtual returns (address) {
        return address(_nftContract);
    }
}
