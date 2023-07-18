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

    uint256 private _price;
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
        _price = 100 * 10 ** 18;
        _referralFactor = 250;
    }

    // Referral mint
    function referralMint(
        address referer,
        uint256 cost,
        address[] memory recipients,
        uint256[] memory tierIds,
        uint256[] memory tierSizes
    ) external virtual nonReentrant {
        require(recipients.length == tierIds.length, "INVALID_INPUT");
        require(recipients.length == tierSizes.length, "INVALID_INPUT");
        require(cost == _price, "INVALID_PRICE");
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
        _nftContract.bulkMint(recipients, tierIds, tierSizes);
    }

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
}
