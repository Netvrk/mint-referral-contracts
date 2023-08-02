// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract AaNft is ERC2981, AccessControl, ReentrancyGuard, ERC721Enumerable {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address private _treasury;
    string private _tokenBaseURI;
    string private _contractURI;
    address private _paymentToken;

    // TIER
    struct Tier {
        uint256 id;
        uint256 price;
        uint256 maxSupply;
        uint256 supply;
    }
    mapping(uint256 => Tier) private _tier;

    // TIER BALANCES & REVENUE
    mapping(address => mapping(uint256 => uint256)) private _ownerTierBalance;
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _ownerTierToken;

    uint256 private _totalRevenue;
    uint256 private constant _maxTiers = 100;
    uint256 private _totalTiers;

    constructor(
        string memory baseURI_,
        address treasury_,
        address manager_,
        address paymentToken_
    ) ERC721("AaNft", "AaNft") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MANAGER_ROLE, manager_);
        _setupRole(MINTER_ROLE, manager_);

        _tokenBaseURI = baseURI_;
        _treasury = treasury_;
        _totalTiers = 0;
        _paymentToken = paymentToken_;
    }

    // Set AaNft base URI
    function setBaseURI(
        string memory newBaseURI_
    ) external virtual onlyRole(MANAGER_ROLE) {
        _tokenBaseURI = newBaseURI_;
    }

    // Set Contract URI
    function setContractURI(
        string memory newContractURI
    ) external virtual onlyRole(MANAGER_ROLE) {
        _contractURI = newContractURI;
    }

    // Set default royalty
    function setDefaultRoyalty(
        address receiver,
        uint96 royalty
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(receiver, royalty);
    }

    // Set treasury address
    function updateTreasury(
        address newTreasury
    ) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _treasury = newTreasury;
    }

    function initTier(
        uint256 id,
        uint256 price,
        uint256 maxSupply
    ) external virtual onlyRole(MANAGER_ROLE) {
        require(id < _maxTiers, "TIER_UNAVAILABLE");
        require(_tier[id].id == 0, "TIER_ALREADY_INITIALIZED");
        require(maxSupply > 0, "INVALID_MAX_SUPPLY");

        _tier[id] = Tier(id, price, maxSupply, 0);
        _totalTiers++;
    }

    /**
    ////////////////////////////////////////////////////
    // Initial Functions 
    ///////////////////////////////////////////////////
    */

    // Withdraw all amounts (revenue, influencer rewards, etc.)
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

    /*##################################################
    ############### MINT FUNCTIONS #####################
    ####################################################
    */

    // PHASE 0: AIRDROP FROM EXTERNAL CONTRACT

    function bulkMint(
        address[] memory recipients,
        uint256[] memory tierIds,
        uint256[] memory tierSizes
    ) external virtual onlyRole(MINTER_ROLE) {
        require(recipients.length == tierIds.length, "INVALID_INPUT");
        require(recipients.length == tierSizes.length, "INVALID_INPUT");

        for (uint256 idx = 0; idx < recipients.length; idx++) {
            require(tierIds[idx] <= _totalTiers, "TIER_UNAVAILABLE");
            require(tierSizes[idx] > 0, "INVALID_SUPPLY");
            require(
                _tier[tierIds[idx]].supply + tierSizes[idx] <=
                    _tier[tierIds[idx]].maxSupply,
                "MAX_SUPPLY_EXCEEDED"
            );
            _mintTier(recipients[idx], tierIds[idx], tierSizes[idx]);
        }
    }

    /**
    ////////////////////////////////////////////////////
    // Internal Functions 
    ///////////////////////////////////////////////////
    */

    function _mintTier(address to, uint256 tierId, uint256 tokenSize) internal {
        Tier storage tier = _tier[tierId];

        // Check if tier is sold out
        require(
            tier.supply + tokenSize <= tier.maxSupply,
            "MAX_SUPPLY_EXCEEDED"
        );

        // Mint tokens
        for (uint256 x = 0; x < tokenSize; x++) {
            uint256 tokenId = _maxTiers + (tier.supply * _maxTiers) + tierId;
            _safeMint(to, tokenId);
            tier.supply++;
            _ownerTierToken[to][tierId][
                _ownerTierBalance[to][tierId]
            ] = tokenId;
            _ownerTierBalance[to][tierId]++;
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    /**
    ////////////////////////////////////////////////////
    // View only functions
    ///////////////////////////////////////////////////
    */

    function contractURI() external view virtual returns (string memory) {
        return _contractURI;
    }

    function treasury() external view virtual returns (address) {
        return _treasury;
    }

    function paymentToken() external view virtual returns (address) {
        return _paymentToken;
    }

    function totalRevenue() external view virtual returns (uint256) {
        return _totalRevenue;
    }

    function maxTiers() external view virtual returns (uint256) {
        return _maxTiers;
    }

    function totalTiers() external view virtual returns (uint256) {
        return _totalTiers;
    }

    function tierInfo(
        uint256 tierId
    ) external view returns (uint256 price, uint256 supply, uint256 maxSupply) {
        require(tierId <= _totalTiers, "TIER_UNAVAILABLE");
        Tier storage tier = _tier[tierId];
        return (tier.price, tier.supply, tier.maxSupply);
    }

    function tierTokenByIndex(
        uint256 tierId,
        uint256 index
    ) external view returns (uint256) {
        require(tierId <= _totalTiers, "TIER_UNAVAILABLE");
        return (index * _maxTiers) + tierId;
    }

    function tierTokenOfOwnerByIndex(
        address owner,
        uint256 tierId,
        uint256 index
    ) external view returns (uint256) {
        require(tierId <= _totalTiers, "TIER_UNAVAILABLE");
        require(index < _ownerTierBalance[owner][tierId], "INVALID_INDEX");
        return _ownerTierToken[owner][tierId][index];
    }

    function balanceOfTier(
        address owner,
        uint256 tierId
    ) external view returns (uint256) {
        require(tierId <= _totalTiers, "TIER_UNAVAILABLE");
        return _ownerTierBalance[owner][tierId];
    }

    /**
    ////////////////////////////////////////////////////
    // Override Functions 
    ///////////////////////////////////////////////////
    */

    // The following functions are overrides required by Solidity.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC2981, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
