// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "hardhat/console.sol";

import "./interfaces/IAaNft.sol";

contract AaReferral is AccessControl, ReentrancyGuard {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address private _treasury;
    address private _paymentToken;

    mapping(uint256 => uint256) private _tierPrices;

    IAaNft private _nftContract;

    struct snapshot {
        uint256 start;
        uint256 end;
        bytes32 merkleRoot;
    }
    snapshot[] private _snapshots;
    uint256 private _snapshotRange;

    constructor(IAaNft nftContract_, address treasury_, address paymentToken_) {
        require(
            nftContract_.supportsInterface(type(IERC721).interfaceId),
            "INVALID_NFT_CONTRACT"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, msg.sender);
        _nftContract = nftContract_;
        _treasury = treasury_;
        _paymentToken = paymentToken_;
        _snapshotRange = 1 days;
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

    // AaReferral mint function
    function referralMint(
        address recipient,
        uint256 tierId,
        uint256 tierSize,
        uint256 cost,
        address referer,
        uint256 referralFactor,
        bytes32[] memory proof
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

        // Check if the snapshot is valid
        require(
            _snapshots[_snapshots.length - 1].start <= block.timestamp &&
                _snapshots[_snapshots.length - 1].end >= block.timestamp,
            "INVALID_SNAPSHOT"
        );

        // Check if the merkle proof is valid
        require(
            _verifyMerkleProof(proof, referer, referralFactor),
            "INVALID_MERKLE_PROOF"
        );

        // Provide revenue to referer
        uint256 treasurytake = (cost * (1000 - referralFactor)) / 1000;
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

    function updateMerkleRoot(
        uint256 startTimestamp,
        bytes32 merkleRoot_
    ) external virtual onlyRole(MANAGER_ROLE) {
        _snapshots.push(
            snapshot(
                startTimestamp,
                startTimestamp + _snapshotRange,
                merkleRoot_
            )
        );
    }

    function updateSnapshotRangeInDays(
        uint16 snapshotRange_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _snapshotRange = snapshotRange_ * 1 days;
    }

    function _verifyMerkleProof(
        bytes32[] memory proof,
        address referer,
        uint256 referralFactor
    ) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(referer, referralFactor));
        return
            MerkleProof.verify(
                proof,
                _snapshots[_snapshots.length - 1].merkleRoot,
                leaf
            );
    }

    // Get Functions

    function getLatestMerkleRoot() external view virtual returns (bytes32) {
        return _snapshots[_snapshots.length - 1].merkleRoot;
    }

    function getSnapshot(
        uint256 snapshotId
    ) external view virtual returns (snapshot memory) {
        return _snapshots[snapshotId];
    }

    function getSnapshotIndex() external view virtual returns (uint256) {
        return _snapshots.length - 1;
    }

    function getTierPrice(
        uint256 tierId
    ) external view virtual returns (uint256) {
        return _tierPrices[tierId];
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
