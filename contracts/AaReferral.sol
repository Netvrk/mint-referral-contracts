// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// Importing necessary OpenZeppelin contracts for security, access control, and token interfaces
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// Importing interface for the AaNft contract
import "./interfaces/IAaNft.sol";

/**
 * @title AaReferral Contract
 * @dev This contract allows for referral-based NFT minting, where users can refer others to mint NFTs.
 * It handles tier pricing, referral revenue distribution, and manages the use of Merkle proofs for validation.
 * The contract also allows administrators to withdraw funds, update tier prices, manage snapshots, and more.
 */
contract AaReferral is AccessControl, ReentrancyGuard {
    // Define roles for access control
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    // Treasury and payment token addresses
    address private _treasury;
    address private _paymentToken;

    // Mapping to store tier prices
    mapping(uint256 => uint256) private _tierPrices;

    // Interface for interacting with the AaNft contract
    IAaNft private _nftContract;

    // Struct to represent a snapshot of Merkle roots and their time range
    struct snapshot {
        uint256 start; // Start timestamp of the snapshot period
        uint256 end; // End timestamp of the snapshot period
        bytes32 merkleRoot; // Merkle root for validation of referrals during this snapshot period
    }

    // Array to store all snapshots
    snapshot[] private _snapshots;
    // The duration of each snapshot in seconds (default 1 day)
    uint256 private _snapshotRange;

    /**
     * @dev Contract constructor to initialize the AaReferral contract.
     * @param nftContract_ Address of the AaNft contract
     * @param treasury_ Address of the treasury wallet
     * @param paymentToken_ Address of the payment token (ERC20)
     */
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

    /**
     * @dev Update the price of a specific tier.
     * @param tierId The ID of the tier
     * @param price The new price for the tier
     */
    function updateTierPrice(
        uint256 tierId,
        uint256 price
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _tierPrices[tierId] = price;
    }

    /**
     * @dev Update the address of the treasury.
     * @param treasury_ The new treasury address
     */
    function updateTreasury(
        address treasury_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _treasury = treasury_;
    }

    /**
     * @dev Withdraw funds from the contract to the treasury.
     * Only callable by an account with the DEFAULT_ADMIN_ROLE.
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
     * @dev Mint an NFT for a recipient through a referral program.
     * @param recipient The address that will receive the minted NFT
     * @param tierId The ID of the tier for the NFT
     * @param tierSize The number of NFTs to mint
     * @param cost The cost for minting the NFTs
     * @param referer The address of the referrer
     * @param referralFactor The percentage of the cost that goes to the referrer
     * @param proof The Merkle proof to validate the referral
     */
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

        // Check if the referer has a valid balance of NFTs
        require(_nftContract.balanceOf(referer) > 0, "INVALID_REFERER");

        // Check if the current snapshot is valid
        require(
            _snapshots[_snapshots.length - 1].start <= block.timestamp &&
                _snapshots[_snapshots.length - 1].end >= block.timestamp,
            "INVALID_SNAPSHOT"
        );

        // Verify the Merkle proof for the referral
        require(
            _verifyMerkleProof(proof, referer, referralFactor),
            "INVALID_MERKLE_PROOF"
        );

        // Calculate revenue distribution: how much goes to the treasury and how much to the referrer
        uint256 treasurytake = (cost * (1000 - referralFactor)) / 1000;
        uint256 referralTake = cost - treasurytake;

        // Transfer funds from the sender to the treasury and the referrer
        IERC20(_paymentToken).transferFrom(
            msg.sender,
            address(this),
            treasurytake
        );
        IERC20(_paymentToken).transferFrom(msg.sender, referer, referralTake);

        // Mint the NFT for the recipient
        address[] memory recipients = new address[](1);
        recipients[0] = recipient;

        uint256[] memory tierIds = new uint256[](1);
        tierIds[0] = tierId;

        uint256[] memory tierSizes = new uint256[](1);
        tierSizes[0] = tierSize;

        _nftContract.bulkMint(recipients, tierIds, tierSizes);
    }

    /**
     * @dev Update the Merkle root for a snapshot.
     * @param startTimestamp The timestamp when the snapshot starts
     * @param merkleRoot_ The Merkle root to be associated with the snapshot
     */
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

    /**
     * @dev Update the duration (in days) for each snapshot range.
     * @param snapshotRange_ The new snapshot range in days
     */
    function updateSnapshotRangeInDays(
        uint16 snapshotRange_
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _snapshotRange = snapshotRange_ * 1 days;
    }

    /**
     * @dev Internal function to verify the Merkle proof for a given referral.
     * @param proof The Merkle proof to verify
     * @param referer The address of the referrer
     * @param referralFactor The referral factor to verify
     * @return True if the proof is valid, false otherwise
     */
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

    // Getter functions

    /**
     * @dev Get the latest Merkle root.
     * @return The latest Merkle root used for verification
     */
    function getLatestMerkleRoot() external view virtual returns (bytes32) {
        return _snapshots[_snapshots.length - 1].merkleRoot;
    }

    /**
     * @dev Get the details of a specific snapshot.
     * @param snapshotId The ID of the snapshot to fetch
     * @return The snapshot struct containing start timestamp, end timestamp, and Merkle root
     */
    function getSnapshot(
        uint256 snapshotId
    ) external view virtual returns (snapshot memory) {
        return _snapshots[snapshotId];
    }

    /**
     * @dev Get the index of the most recent snapshot.
     * @return The index of the latest snapshot
     */
    function getSnapshotIndex() external view virtual returns (uint256) {
        return _snapshots.length - 1;
    }

    /**
     * @dev Get the price of a specific tier.
     * @param tierId The ID of the tier
     * @return The price of the tier
     */
    function getTierPrice(
        uint256 tierId
    ) external view virtual returns (uint256) {
        return _tierPrices[tierId];
    }

    /**
     * @dev Get the address of the treasury.
     * @return The address of the treasury
     */
    function getTreasury() external view virtual returns (address) {
        return _treasury;
    }

    /**
     * @dev Get the address of the payment token.
     * @return The address of the payment token
     */
    function getPaymentToken() external view virtual returns (address) {
        return _paymentToken;
    }

    /**
     * @dev Get the address of the NFT contract.
     * @return The address of the NFT contract
     */
    function getNftContract() external view virtual returns (address) {
        return address(_nftContract);
    }
}
